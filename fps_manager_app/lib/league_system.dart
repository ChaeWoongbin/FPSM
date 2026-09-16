import 'models.dart';
import 'dart:math';

class Matchup {
  Matchup({required this.home, required this.away});
  final Club home;
  final Club away;

  @override
  String toString() => '${home.name} vs ${away.name}';
}

class TeamStats {
  TeamStats({required this.club});
  final Club club;
  int wins = 0;
  int losses = 0;
  int roundWins = 0;
  int roundLosses = 0;

  int get pointDifference => roundWins - roundLosses;

  void addResult(int myScore, int opponentScore) {
    if (myScore > opponentScore) {
      wins++;
    } else if (opponentScore > myScore) {
      losses++;
    }
    roundWins += myScore;
    roundLosses += opponentScore;
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
