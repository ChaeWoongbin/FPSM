import 'package:flutter/material.dart';
import 'dart:math';
import 'game_data.dart';
import 'models.dart';
import 'league_system.dart';
import 'match_screen.dart';

class LeagueDashboardScreen extends StatefulWidget {
  const LeagueDashboardScreen({
    super.key,
    required this.data,
    required this.myClub,
    required this.div1,
    required this.div2,
    required this.div1Schedule,
    required this.div2Schedule,
  });

  final GameData data;
  final Club myClub;
  final List<Club> div1;
  final List<Club> div2;
  final LeagueSchedule div1Schedule;
  final LeagueSchedule div2Schedule;

  @override
  State<LeagueDashboardScreen> createState() => _LeagueDashboardScreenState();
}

class _LeagueDashboardScreenState extends State<LeagueDashboardScreen> {
  int currentRound = 0;
  String mapId = 'industrial';
  
  late final Map<String, TeamStats> div1Stats;
  late final Map<String, TeamStats> div2Stats;

  @override
  void initState() {
    super.initState();
    div1Stats = { for (var c in widget.div1) c.id : TeamStats(club: c) };
    div2Stats = { for (var c in widget.div2) c.id : TeamStats(club: c) };
  }

  bool get _isDiv1 => widget.div1.contains(widget.myClub);
  List<Club> get _myDiv => _isDiv1 ? widget.div1 : widget.div2;
  LeagueSchedule get _mySchedule => _isDiv1 ? widget.div1Schedule : widget.div2Schedule;
  Map<String, TeamStats> get _myStats => _isDiv1 ? div1Stats : div2Stats;

  Matchup? _findMyNextMatch() {
    if (currentRound >= _mySchedule.rounds.length) return null;
    final matches = _mySchedule.rounds[currentRound];
    for (var m in matches) {
      if (m.home == widget.myClub || m.away == widget.myClub) return m;
    }
    return null;
  }

  List<TeamStats> _getSortedStandings(Map<String, TeamStats> statsMap) {
    final list = statsMap.values.toList();
    list.sort((a, b) {
      if (a.wins != b.wins) return b.wins.compareTo(a.wins);
      if (a.pointDifference != b.pointDifference) return b.pointDifference.compareTo(a.pointDifference);
      return 0; // tie
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final myNextMatch = _findMyNextMatch();
    final sortedStandings = _getSortedStandings(_myStats);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.myClub.name} 감독 사무실 (상반기 ${currentRound + 1}R)'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('다음 경기 일정', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    if (myNextMatch == null)
                      const Text('정규 시즌 일정이 종료되었습니다.', style: TextStyle(fontSize: 18))
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _teamBadge(myNextMatch.home),
                          const Text('VS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          _teamBadge(myNextMatch.away),
                        ],
                      ),
                    const SizedBox(height: 48),
                    if (myNextMatch != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.sports_esports),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Text('매치업 진행 (${currentRound + 1}주 차)', style: const TextStyle(fontSize: 20)),
                        ),
                        onPressed: () => _playMatch(myNextMatch),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('${_isDiv1 ? '1부' : '2부'} 리그 순위표', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  for (int i = 0; i < sortedStandings.length; i++)
                    ListTile(
                      leading: Text('${i + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      title: Text(sortedStandings[i].club.name),
                      trailing: Text(
                        '${sortedStandings[i].wins}승 ${sortedStandings[i].losses}패 (득실 ${sortedStandings[i].pointDifference > 0 ? '+' : ''}${sortedStandings[i].pointDifference})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamBadge(Club club) {
    return Column(
      children: [
        Image.asset(club.logo, height: 80, errorBuilder: (_,__,___) => const Icon(Icons.shield, size: 80)),
        const SizedBox(height: 12),
        Text(club.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _playMatch(Matchup match) async {
    final rosterA = widget.data.rosterFor(match.home);
    final rosterB = widget.data.rosterFor(match.away);
    
    final config = MatchConfig(
      matchId: 'league_r${currentRound}_${match.home.id}_${match.away.id}',
      seed: DateTime.now().millisecondsSinceEpoch,
      mapId: mapId,
      teamA: match.home,
      teamB: match.away,
      teamAPlayers: rosterA,
      teamBPlayers: rosterB,
    );

    final result = await Navigator.of(context).push<MatchResult>(
      MaterialPageRoute(builder: (_) => MatchScreen(config: config)),
    );

    if (result != null && mounted) {
      _processRoundResults(result, match);
    }
  }

  void _processRoundResults(MatchResult myMatchResult, Matchup myMatch) {
    setState(() {
      // 1. 유저 팀의 경기 결과 반영
      final isHomeA = myMatchResult.teamAName == myMatch.home.name;
      final homeScore = isHomeA ? myMatchResult.teamAScore : myMatchResult.teamBScore;
      final awayScore = isHomeA ? myMatchResult.teamBScore : myMatchResult.teamAScore;
      
      _myStats[myMatch.home.id]!.addResult(homeScore, awayScore);
      _myStats[myMatch.away.id]!.addResult(awayScore, homeScore);

      // 2. 다른 팀들의 경기 자동 시뮬레이션 (간단한 난수 승패 판정)
      final rng = Random();
      final allMatches = _mySchedule.rounds[currentRound];
      for (var m in allMatches) {
        if (m == myMatch) continue; // 이미 처리됨
        
        // 6선승제이므로 승자는 6점, 패자는 0~5점 획득 (대략적인 시뮬레이션)
        final winnerIsHome = rng.nextBool();
        final loserScore = rng.nextInt(6);
        
        if (winnerIsHome) {
          _myStats[m.home.id]!.addResult(6, loserScore);
          _myStats[m.away.id]!.addResult(loserScore, 6);
        } else {
          _myStats[m.away.id]!.addResult(6, loserScore);
          _myStats[m.home.id]!.addResult(loserScore, 6);
        }
      }

      // 3. 반대편 분배 리그 (1부/2부 중 내가 속하지 않은 곳) 시뮬레이션
      final otherSchedule = _isDiv1 ? widget.div2Schedule : widget.div1Schedule;
      final otherStats = _isDiv1 ? div2Stats : div1Stats;
      
      if (currentRound < otherSchedule.rounds.length) {
        for (var m in otherSchedule.rounds[currentRound]) {
          final winnerIsHome = rng.nextBool();
          final loserScore = rng.nextInt(6);
          if (winnerIsHome) {
            otherStats[m.home.id]!.addResult(6, loserScore);
            otherStats[m.away.id]!.addResult(loserScore, 6);
          } else {
            otherStats[m.away.id]!.addResult(6, loserScore);
            otherStats[m.home.id]!.addResult(loserScore, 6);
          }
        }
      }

      // 라운드 넘기기
      currentRound++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${myMatchResult.winnerName} 승리! 다음 라운드로 진행합니다.')),
    );
  }
}
