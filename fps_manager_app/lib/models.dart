import 'dart:convert';

int _rating(Object? value, [int fallback = 60]) {
  final number = value is num ? value.round() : fallback;
  return number.clamp(1, 99);
}

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.clubId,
    required this.slot,
    required this.portrait,
    required this.skills,
    required this.battle,
    required this.operation,
  });
  final String id;
  final String name;
  final String clubId;
  final int slot;
  final String portrait;
  final Map<String, dynamic> skills;
  final int battle;
  final int operation;

  Map<String, dynamic> get matchAttributes {
    final aim = _rating(skills['micro'], battle);
    final judgment = _rating(skills['judgment']);
    final aggression = _rating(skills['aggression']);
    final reaction = _rating(operation);
    return {
      'aim': aim,
      'reaction': reaction,
      'judgment': judgment,
      'aggression': aggression,
      'recoil': {
        'pistol': _rating(aim - 2),
        'smg': _rating(aim + 1),
        'rifle': _rating(aim),
        'sniper': _rating((aim + judgment) ~/ 2),
        'shotgun': _rating((aim + aggression) ~/ 2),
      },
    };
  }

  int get overall {
    final attributes = matchAttributes;
    final recoil = attributes['recoil'] as Map<String, dynamic>;
    final ratings = <int>[
      attributes['aim'] as int,
      attributes['reaction'] as int,
      attributes['judgment'] as int,
      attributes['aggression'] as int,
      recoil['pistol'] as int,
      recoil['smg'] as int,
      recoil['rifle'] as int,
      recoil['sniper'] as int,
      recoil['shotgun'] as int,
    ];
    return (ratings.reduce((sum, rating) => sum + rating) / ratings.length)
        .round()
        .clamp(1, 99);
  }

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    name: json['name'] as String,
    clubId: json['club_id'] as String,
    slot: (json['roster_slot'] as num?)?.toInt() ?? 0,
    portrait: ((json['portrait'] as Map?)?['path'] as String?) ?? '',
    skills: Map<String, dynamic>.from(json['skills'] as Map? ?? const {}),
    battle: _rating(json['battle']),
    operation: _rating(json['operation']),
  );

  Map<String, dynamic> toMatchJson(int index) {
    const roles = ['entry', 'support', 'sniper', 'lurk', 'anchor'];
    const weapons = ['smg', 'rifle', 'sniper', 'rifle', 'shotgun'];
    return {
      'id': id,
      'name': name,
      'nickname': name,
      'slot': index,
      'role': roles[index],
      'igl': index == 1,
      'preferredWeapon': weapons[index],
      'attributes': matchAttributes,
    };
  }
}

class Club {
  const Club({
    required this.id,
    required this.name,
    required this.logo,
    required this.rosterIds,
    required this.kind,
    this.division,
  });
  final String id;
  final String name;
  final String logo;
  final List<String> rosterIds;
  final String kind;
  final int? division;

  factory Club.fromJson(Map<String, dynamic> json) => Club(
    id: json['id'] as String,
    name: json['name'] as String,
    logo: ((json['emblem'] as Map?)?['path'] as String?) ?? '',
    rosterIds: List<String>.from(
      json['initial_roster_ids'] as List? ?? const [],
    ),
    kind: json['kind'] as String? ?? 'unknown',
    division: json['division'] as int?,
  );
}

class MatchConfig {
  const MatchConfig({
    required this.matchId,
    required this.seed,
    required this.mapId,
    required this.teamA,
    required this.teamB,
    required this.teamAPlayers,
    required this.teamBPlayers,
  });
  final String matchId;
  final int seed;
  final String mapId;
  final Club teamA;
  final Club teamB;
  final List<Player> teamAPlayers;
  final List<Player> teamBPlayers;
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'matchId': matchId,
    'seed': seed,
    'map': {'id': mapId, 'sites': 2},
    'rules': {
      'targetWins': 4,
      'swapEvery': 3,
      'tieAt': 3,
      'overtimeMode': 'win_by_two',
      'overtimeLead': 2,
      'buyDuration': 10,
      'roundTime': 110,
      'plantTime': 3.2,
      'defuseTime': 5,
      'postPlantTime': 38,
    },
    'economy': {'enabled': true, 'startCash': 1000, 'maxCash': 9000},
    'teamA': _teamJson(teamA, teamAPlayers, '#E5A36B'),
    'teamB': _teamJson(teamB, teamBPlayers, '#70C4BD'),
    'tactics': {
      'teamA': mapId == 'service_ring' ? 'rearFlank' : 'splitB',
      'teamB': 'balanced',
    },
  };
  static Map<String, dynamic> _teamJson(
    Club club,
    List<Player> players,
    String color,
  ) => {
    'id': club.id,
    'name': club.name,
    'shortName': club.name,
    'color': color,
    'logoAssetKey': club.logo,
    'players': [
      for (var i = 0; i < players.length; i++) players[i].toMatchJson(i),
    ],
  };
  String encode() => jsonEncode(toJson());
}

class MatchResult {
  const MatchResult({
    required this.matchId,
    required this.mapId,
    required this.winnerName,
    required this.teamAName,
    required this.teamBName,
    required this.teamAScore,
    required this.teamBScore,
    required this.players,
  });
  final String matchId;
  final String mapId;
  final String winnerName;
  final String teamAName;
  final String teamBName;
  final int teamAScore;
  final int teamBScore;
  final List<Map<String, dynamic>> players;
  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final teams = Map<String, dynamic>.from(json['teams'] as Map? ?? const {});
    final scores = Map<String, dynamic>.from(
      json['scores'] as Map? ?? const {},
    );
    final winnerKey = json['winner'] as String?;
    final winner = Map<String, dynamic>.from(
      teams[winnerKey] as Map? ?? const {},
    );
    return MatchResult(
      matchId: (json['matchId'] ?? json['id'] ?? '') as String,
      mapId: ((json['map'] as Map?)?['id'] ?? '') as String,
      winnerName: (winner['name'] ?? winnerKey ?? '-') as String,
      teamAName: ((teams['EMBER'] as Map?)?['name'] ?? 'EMBER') as String,
      teamBName: ((teams['TIDE'] as Map?)?['name'] ?? 'TIDE') as String,
      teamAScore: (scores['EMBER'] as num?)?.toInt() ?? 0,
      teamBScore: (scores['TIDE'] as num?)?.toInt() ?? 0,
      players: (json['totals'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}
