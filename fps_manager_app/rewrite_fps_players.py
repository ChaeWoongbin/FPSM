import json, random

with open("assets/data/players.json", "r", encoding="utf-8") as f:
    players = json.load(f)

# True FPS Player Names (CS:GO / Valorant)
fps_names = [
    # CS:GO Legends & Stars
    "s1mple", "ZywOo", "NiKo", "dev1ce", "kennyS", "coldzera", "FalleN", 
    "olofmeister", "GeT_RiGhT", "f0rest", "ropz", "m0NESY", "donk", "Twistzz", 
    "EliGE", "sh1ro", "Ax1Le", "b1t", "electroNic", "KSCERATO", "blameF", 
    "stavn", "cadiaN", "apEX", "dupreeh", "Magisk", "gla1ve", "Xyp9x", 
    "flusha", "JW", "KRIMZ", "snax", "pashaBiceps", "TaZ", "NEO",
    # Valorant Stars
    "TenZ", "f0rsakeN", "aspas", "Less", "Derke", "Boaster", "Alfajer", 
    "Leo", "Chronicle", "nAts", "Redgar", "cNed", "yay", "Marved", "FNS", 
    "crashies", "Victor", "zombs", "dapr", "ShahZaM", "stax", "BuZz", 
    "MaKo", "Rb", "Zest", "Lakia", "t3xture", "Meteor", "Munchkin", "Karon", 
    "ZmjjKK", "AAAAY", "CHICHOO", "Haodong", "nobody", "Sayaplayer", "Dep", 
    "Laz", "crow", "TENNN", "SugarZ3ro", "something", "mindfreak", "Jinggg", "d4v41",
    "Keznit", "Klaus", "Mazino", "Saadhak", "pANcada", "Sacy", "Tuyz", "Cauanzin",
    "Tarik", "Shroud", "Hiko", "Skadoodle", "Stewie2K", "autimatic", "RUSH", "Tarik"
]
random.shuffle(fps_names)

fps_tags = [
    "엔트리 프래거", "메인 스나이퍼", "인게임 리더(IGL)", "러커", "서포터", 
    "플렉스", "클러치 마스터", "에임봇", "전략가", "타격대", "척후대", "감시자", "연막"
]

for i, p in enumerate(players):
    # Unique name assignment, append numbers if we run out of unique names
    base_name = fps_names[i % len(fps_names)]
    suffix = str(random.randint(1, 99)) if i >= len(fps_names) else ""
    p["name"] = f"{base_name}{suffix}"
    
    # Replace RTS tags with FPS roles
    p["tag"] = random.choice(fps_tags)
    
    # Remove 'preference' or any other weird RTS leftover keys
    for k in ["preference", "source_profile_index"]:
        p.pop(k, None)

with open("assets/data/players.json", "w", encoding="utf-8") as f:
    json.dump(players, f, ensure_ascii=False, indent="\t")

print("Done resetting to true FPS standards.")
