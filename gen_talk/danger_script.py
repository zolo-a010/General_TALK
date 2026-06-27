# A simple Flask backend example
from flask import Flask, request, jsonify
import pickle

app = Flask(__name__)
# Load your pre-trained model
model = pickle.load(open("best_danger_model.pkl", "rb"))

@app.route('/get_danger', methods=['POST'])
def get_danger():
    data = request.json
    # Extract features sent from Godot
    features = [[data['damage'], data['enemies'], data['structures_destroyed']]]
    
    # Predict the danger percentage
    predicted_danger = model.predict(features)[0]
    
    return jsonify({"city": data['city'], "danger_percent": predicted_danger})

if __name__ == '__main__':
    app.run(port=5000)