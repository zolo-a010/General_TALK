import csv
import random

# Configuration
output_filename = "trainingdata.csv"
total_rows = 8000

# Distribution ratios: ~40% Friendly, ~35% Suspicious, ~25% Aggressive
friendly_count = int(total_rows * 0.34)
suspicious_count = int(total_rows * 0.33)
aggressive_count = total_rows - (friendly_count + suspicious_count)

dataset = []

# 1. Generate Friendly Patterns (Behavior = 0)
# High interactions, zero or rare accidental thefts, weapon always sheathed
for _ in range(friendly_count):
    times_talked = random.randint(5, 60)
    items_stolen = random.choices([0, 1], weights=[95, 5])[0]  # 95% chance of 0 thefts
    weapon_equipped = 0
    dataset.append([times_talked, items_stolen, weapon_equipped, 0])

# 2. Generate Suspicious Patterns (Behavior = 1)
# Moderate interactions, low-to-medium thefts, weapon sheathed
for _ in range(suspicious_count):
    times_talked = random.randint(1, 20)
    items_stolen = random.randint(1, 4)
    weapon_equipped = 0
    dataset.append([times_talked, items_stolen, weapon_equipped, 1])

# 3. Generate Aggressive Patterns (Behavior = 2)
# Low interactions with thefts OR weapon actively drawn (immediate hostility)
for _ in range(aggressive_count):
    weapon_equipped = random.choices([0, 1], weights=[30, 70])[0]
    
    if weapon_equipped == 1:
        # If weapon is out, behavior is aggressive regardless of other stats
        times_talked = random.randint(0, 50)
        items_stolen = random.randint(0, 15)
    else:
        # If weapon is down, they must have stolen a massive amount to be aggressive
        times_talked = random.randint(0, 10)
        items_stolen = random.randint(5, 15)
        
    dataset.append([times_talked, items_stolen, weapon_equipped, 2])

# Shuffle the rows so the model doesn't learn based on order
random.shuffle(dataset)

# Write to CSV
with open(output_filename, mode="w", newline="", encoding="utf-8") as file:
    writer = csv.writer(file)
    # Write header
    writer.writerow(["times_talked", "items_stolen", "weapon_equipped", "behavior"])
    # Write data rows
    writer.writerows(dataset)

print(f"[+] Successfully generated {total_rows} rows inside '{output_filename}'!")