import json, random

with open("assets/data/players.json", "r", encoding="utf-8") as f:
    players = json.load(f)

# FPS-style nicknames
tags = [
    "Ace", "Viper", "Zeus", "Kira", "Ghost", "Neo", "Strike", "AimBot",
    "Faker", "Deft", "ShowMaker", "Chovy", "Canyon", "BeryL", "Peanut",
    "Ruler", "Keria", "Oner", "Gumayusi", "Viper", "Zeka", "Kingen",
    "Doran", "Tarzan", "Scout", "Rookie", "TheShy", "Doinb", "Gala",
    "Ming", "Crisp", "Tian", "Knight", "JackeyLove", "Baolan", "Ning",
    "Uzi", "Clearlove", "Meiko", "Flandre", "Jiejie", "Pawn", "Mata",
    "Imp", "Dandy", "Looper", "Marin", "Bang", "Wolf", "Bengi", "Blank",
    "Duke", "Piglet", "PoohManDu", "Impact", "Caps", "Perkz", "Jankos",
    "Wunder", "Mikyx", "Rekkles", "Broxah", "Bwipo", "Hylissang", "Nemesis",
    "Crown", "CoreJJ", "Ambition", "CuVee", "Ruler", "Haru", "Wraith",
    "Smeb", "Kuro", "Pray", "GorillA", "Hojin", "Peanut", "Khan", "Bdd",
    "Teddy", "Cuzz", "Clid", "Life", "Rascal", "Kiin", "Aim", "Headshot",
    "Sniper", "Lurk", "Flick", "Clutch", "Ninja", "Shadow", "Hunter", "Eagle",
    "Hawk", "Wolf", "Bear", "Lion", "Tiger", "Dragon", "Phoenix", "Titan",
    "Gamer", "Pro", "Star", "King", "Lord", "God", "Demon", "Devil",
    "Angel", "Hero", "Legend", "Master", "Boss", "Captain", "Commander"
]
random.shuffle(tags)

descriptions = [
    "뛰어난 에임과 빠른 반응속도를 자랑하는 팀의 핵심 엔트리 프래거.",
    "클러치 상황에서 침착한 판단이 돋보이는 선수.",
    "후방에서 팀원들을 든든하게 지원하는 서포터형 플레이어.",
    "정밀한 스나이퍼 라이플 조준력으로 적을 압도하는 메인 스나이퍼.",
    "변칙적인 움직임과 예측 불허의 위치 선정으로 적을 교란합니다.",
    "오랜 경험을 바탕으로 오더를 내리는 팀의 정신적 지주 (IGL).",
    "공격적인 플레이 스타일로 항상 교전을 주도하는 불도저.",
    "안정적인 리코일 컨트롤과 단단한 수비력을 갖춘 앵커.",
    "상황 판단력이 뛰어나 언제 어디서 진입해야 할지 아는 두뇌파.",
    "엄청난 동체 시력으로 순간적인 교전에서 우위를 점합니다.",
    "적의 빈틈을 파고드는 러커(Lurker) 포지션의 스페셜리스트.",
    "불리한 상황도 혼자서 뒤집을 수 있는 압도적인 캐리력을 보유했습니다.",
    "항상 냉정함을 유지하며 기복 없이 꾸준한 활약을 보여줍니다.",
    "새롭게 떠오르는 신예로, 피지컬만큼은 리그 최상위권으로 평가받습니다."
]

for i, p in enumerate(players):
    p["name"] = tags[i % len(tags)] + str(random.randint(1, 99) if i >= len(tags) else "")
    desc = random.choice(descriptions)
    
    # Customize description slightly based on their highest stat
    skills = p.get("skills", {})
    battle = p.get("battle", 50)
    op = p.get("operation", 50)
    
    if battle > 85:
        desc = "리그 최고 수준의 에임 트래킹과 헤드샷 적중률을 가진 괴물."
    elif op > 85:
        desc = "경기의 흐름을 읽는 놀라운 게임 센스와 반응속도로 팀을 지휘합니다."
    elif skills.get("judgment", 0) > 85:
        desc = "순간적인 오더와 맵 리딩 능력이 탁월한 지능형 플레이어."
    elif skills.get("aggression", 0) > 85:
        desc = "적진을 초토화시키는 극도의 공격성과 전진 배치가 특기입니다."
        
    p["description"] = desc
    
    # Remove old RPG cruft
    for k in ["faction_id", "faction_name", "hero", "hero_index", "strategy", "strategy_index"]:
        p.pop(k, None)

with open("assets/data/players.json", "w", encoding="utf-8") as f:
    json.dump(players, f, ensure_ascii=False, indent="\t")

print("Done")
