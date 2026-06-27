from flask import Flask, request, jsonify
from groq import Groq
from dotenv import load_dotenv
import os
import numpy as np
import joblib  # Lightweight utility to load our pre-trained model file

load_dotenv()

app = Flask(__name__)
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

# =====================================================================
# MACHINE LEARNING: LOAD PRE-TRAINED MODEL
# =====================================================================

model_path = os.path.join(os.path.dirname(__file__), "npc_behavior_model.pkl")

try:
    # Load the pre-trained Naive Bayes model directly from the Jupyter export
    classifier = joblib.load(model_path)
    print(f"[+] Successfully loaded pre-trained model: '{model_path}'")
except Exception as e:
    print(f"[!] Critical Error loading model file: {e}")
    print("[!] Ensure you copied 'npc_behavior_model.pkl' into this directory!")
    classifier = None

# Map numbers back to string states for Godot
STATE_MAPPING = {0: "Friendly", 1: "Suspicious", 2: "Aggressive"}

# =====================================================================
# ROUTE HANDLING WITH ML PREDICTION
# =====================================================================

@app.route("/chat", methods=["POST"])
def process_npc_dialogue():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Invalid JSON"}), 400

    # 1. Pull out chat metadata
    message = data.get("message", "")
    npc_name = data.get("npc_name", "Unknown NPC")
    npc_persona = data.get("npc_persona", "A mysterious character.")

    # 2. Extract Game Features sent by Godot for ML calculation
    times_talked = int(data.get("times_talked", 0))
    items_stolen = int(data.get("items_stolen", 0))
    weapon_equipped = int(data.get("weapon_equipped", 0)) # 0 or 1

    # 3. Predict NPC Mood State using the loaded model
    npc_state = "Friendly"  # Fallback safety default
    if classifier:
        try:
            player_features = np.array([[times_talked, items_stolen, weapon_equipped]])
            predicted_class = classifier.predict(player_features)[0]
            # Convert numeric prediction (0, 1, 2) to string representation
            npc_state = STATE_MAPPING.get(int(predicted_class), "Friendly")
            print(f"\n[+] ML Live Inference for {npc_name}: Features {player_features.tolist()} -> Predicted Mood: {npc_state}")
        except Exception as eval_err:
            print(f"[!] Live inference processing failed: {eval_err}")

    # 4. Dynamically update the AI System Prompt with the ML mood
    system_prompt = (
        f"You are an NPC named {npc_name} in a 2D RPG video game. "
        f"Your character description: {npc_persona}. "
        f"CRITICAL CURRENT MOOD: You currently feel {npc_state} towards the player. "
        f"If Friendly: Be helpful, welcoming, and warm. "
        f"If Suspicious: Be cautious, short, and question why they are lurking around. "
        f"If Aggressive: Be completely hostile, sound threatened, or command them to clear out. "
        "Rules: Keep answers short (1-2 sentences maximum). Stay firmly in character."
    )
    
    try:
        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": message}
            ],
            temperature=0.7, 
            max_tokens=100
        )
        
        reply_text = response.choices[0].message.content
        print(f"[-] Response Sent: {npc_name} ({npc_state}): {reply_text}")
        
        # Return BOTH the dialogue text and the calculated ML mood status back to Godot!
        return jsonify({
            "response": reply_text,
            "npc_state": npc_state
        })
        
    except Exception as e:
        print(f"[!] Groq API Inference Error: {e}")
        return jsonify({
            "response": "... (Stares at you blankly.)",
            "npc_state": npc_state
        })

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000, debug=True)