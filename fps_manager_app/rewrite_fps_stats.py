import json, random

with open("assets/data/players.json", "r", encoding="utf-8") as f:
    players = json.load(f)

for p in players:
    # Extract old stats to generate sensible new ones
    old_skills = p.get("skills", {})
    old_battle = p.get("battle", 50)
    old_op = p.get("operation", 50)
    old_micro = old_skills.get("micro", 50)
    old_judg = old_skills.get("judgment", 50)
    old_agg = old_skills.get("aggression", 50)
    
    # Calculate new stats similar to the old formula to keep balance
    aim = int((old_micro + old_battle) / 2) if old_micro and old_battle else old_battle
    reaction = old_op
    judgment = old_judg
    aggression = old_agg
    
    # Add a bit of randomness to make them unique
    aim = max(1, min(99, aim + random.randint(-5, 5)))
    reaction = max(1, min(99, reaction + random.randint(-5, 5)))
    judgment = max(1, min(99, judgment + random.randint(-5, 5)))
    aggression = max(1, min(99, aggression + random.randint(-5, 5)))
    
    p["stats"] = {
        "aim": aim,
        "reaction": reaction,
        "judgment": judgment,
        "aggression": aggression
    }
    
    # Delete old RTS keys
    for k in ["skills", "battle", "operation"]:
        p.pop(k, None)

with open("assets/data/players.json", "w", encoding="utf-8") as f:
    json.dump(players, f, ensure_ascii=False, indent="\t")

print("Done resetting stats.")
