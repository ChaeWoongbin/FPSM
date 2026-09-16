import 'models.dart';

class Matchup {
  Matchup({required this.home, required this.away});
  final Club home;
  final Club away;

  @override
  String toString() => '${home.name} vs ${away.name}';
}

class PlayerSeasonStats {
  PlayerSeasonStats();
  int kills = 0;
  int deaths = 0;
  int assists = 0;
  int wins = 0;
  int losses = 0;

  double get kda => deaths == 0 ? (kills + assists).toDouble() : (kills + assists) / deaths;
  double get winRate => (wins + losses) == 0 ? 0 : wins / (wins + losses);

  Map<String, dynamic> toJson() => {
    'kills': kills,
    'deaths': deaths,
    'assists': assists,
    'wins': wins,
    'losses': losses,
  };

  factory PlayerSeasonStats.fromJson(Map<String, dynamic> json) {
    return PlayerSeasonStats()
      ..kills = json['kills'] ?? 0
      ..deaths = json['deaths'] ?? 0
      ..assists = json['assists'] ?? 0
      ..wins = json['wins'] ?? 0
      ..losses = json['losses'] ?? 0;
  }
}

class TeamStats {
  TeamStats({required this.club});
  final Club club;
  int wins = 0;
  int losses = 0;
  int roundWins = 0;
  int roundLosses = 0;
  List<String> form = []; // 'W' or 'L'
  List<String> matchScores = []; // "MyScore:OpponentScore"
  Map<String, PlayerSeasonStats> playerStats = {}; // PlayerID -> Stats

  int get pointDifference => roundWins - roundLosses;

  void addResult(int myScore, int opponentScore) {
    if (myScore > opponentScore) {
      wins++;
      form.add('W');
    } else if (opponentScore > myScore) {
      losses++;
      form.add('L');
    }
    roundWins += myScore;
    roundLosses += opponentScore;
    matchScores.add('$myScore:$opponentScore');
  }

  void resetSeason() {
    wins = 0;
    losses = 0;
    roundWins = 0;
    roundLosses = 0;
    form.clear();
    matchScores.clear();
    playerStats.clear();
  }

  Map<String, dynamic> toJson() => {
    'wins': wins,
    'losses': losses,
    'roundWins': roundWins,
    'roundLosses': roundLosses,
    'form': form,
    'matchScores': matchScores,
    'playerStats': playerStats.map((k, v) => MapEntry(k, v.toJson())),
  };

  void loadJson(Map<String, dynamic> json) {
    wins = json['wins'] as int? ?? 0;
    losses = json['losses'] as int? ?? 0;
    roundWins = json['roundWins'] as int? ?? 0;
    roundLosses = json['roundLosses'] as int? ?? 0;
    form = List<String>.from(json['form'] ?? []);
    matchScores = List<String>.from(json['matchScores'] ?? []);
    if (json['playerStats'] != null) {
      final map = json['playerStats'] as Map<String, dynamic>;
      playerStats = map.map((k, v) => MapEntry(k, PlayerSeasonStats.fromJson(v as Map<String, dynamic>)));
    }
  }
}

class LeagueSchedule {
  LeagueSchedule({required this.rounds});
  // rounds[roundIndex][matchIndex]
  final List<List<Matchup>> rounds;
}

class LeagueSystem {
  static LeagueSchedule generateDoubleRoundRobin(List<Club> teams) {
    if (teams.length % 2 != 0) {
      throw Exception('Teams count must be even for standard round-robin');
    }
    final int numTeams = teams.length;
    final int numRounds = numTeams - 1;
    final int matchesPerRound = numTeams ~/ 2;

    List<Club> circle = List.from(teams);
    List<List<Matchup>> firstHalf = [];

    for (int r = 0; r < numRounds; r++) {
      List<Matchup> roundMatches = [];
      for (int m = 0; m < matchesPerRound; m++) {
        // Alternate home/away based on round to balance
        if (r % 2 == 0) {
          roundMatches.add(Matchup(home: circle[m], away: circle[numTeams - 1 - m]));
        } else {
          roundMatches.add(Matchup(home: circle[numTeams - 1 - m], away: circle[m]));
        }
      }
      firstHalf.add(roundMatches);
      
      // Rotate the circle (keep index 0 fixed, rotate others clockwise)
      final last = circle.removeLast();
      circle.insert(1, last);
    }

    // Second half is the same but home/away swapped
    List<List<Matchup>> secondHalf = [];
    for (var round in firstHalf) {
      List<Matchup> swappedRound = round.map((m) => Matchup(home: m.away, away: m.home)).toList();
      secondHalf.add(swappedRound);
    }

    return LeagueSchedule(rounds: [...firstHalf, ...secondHalf]);
  }
}
