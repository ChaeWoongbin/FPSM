import 'package:flutter/material.dart';
import 'dart:math';
import 'game_data.dart';
import 'models.dart';
import 'league_system.dart';
import 'match_screen.dart'; // We'll update MatchScreen to do random map.
import 'save_manager.dart';
import 'offseason_dialog.dart';

class LeagueDashboardScreen extends StatefulWidget {
  const LeagueDashboardScreen({
    super.key,
    required this.data,
    required this.myClub,
    required this.div1,
    required this.div2,
    required this.div1Schedule,
    required this.div2Schedule,
    this.loadedSave,
  });

  final GameData data;
  final Club myClub;
  final List<Club> div1;
  final List<Club> div2;
  final LeagueSchedule div1Schedule;
  final LeagueSchedule div2Schedule;
  final SaveData? loadedSave;

  @override
  State<LeagueDashboardScreen> createState() => _LeagueDashboardScreenState();
}

class _LeagueDashboardScreenState extends State<LeagueDashboardScreen> {
  int currentRound = 0;
  late Map<String, TeamStats> div1Stats;
  late Map<String, TeamStats> div2Stats;

  late bool _isDiv1;
  late LeagueSchedule _mySchedule;
  late Map<String, TeamStats> _myStats;
  
  int? _viewedLeagueRound;
  Club? _selectedInfoClub;

  @override
  void initState() {
    super.initState();
    _isDiv1 = widget.div1.contains(widget.myClub);
    _mySchedule = _isDiv1 ? widget.div1Schedule : widget.div2Schedule;
    
    div1Stats = { for (var c in widget.div1) c.id: TeamStats(club: c) };
    div2Stats = { for (var c in widget.div2) c.id: TeamStats(club: c) };
    
    if (widget.loadedSave != null) {
      currentRound = widget.loadedSave!.currentRound;
      final statsMap = widget.loadedSave!.stats;
      for (var entry in div1Stats.entries) {
        if (statsMap.containsKey(entry.key)) {
          entry.value.loadJson(statsMap[entry.key]);
        }
      }
      for (var entry in div2Stats.entries) {
        if (statsMap.containsKey(entry.key)) {
          entry.value.loadJson(statsMap[entry.key]);
        }
      }
    }
    
    _myStats = _isDiv1 ? div1Stats : div2Stats;
    _selectedInfoClub = widget.div1.first;
  }

  Matchup? get _myNextMatch {
    if (currentRound >= _mySchedule.rounds.length) return null;
    return _mySchedule.rounds[currentRound].firstWhere(
      (m) => m.home == widget.myClub || m.away == widget.myClub
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.myClub.name} - 감독 대시보드'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '홈'),
              Tab(text: '일정'),
              Tab(text: '선수단'),
              Tab(text: '리그'),
              Tab(text: '순위'),
              Tab(text: '정보'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveGameData(0),
            ),
          ],
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildHomeTab(),
              _buildScheduleTab(),
              _buildRosterTab(widget.myClub),
              _buildLeagueTab(),
              _buildStandingsTab(),
              _buildInfoTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final myNextMatch = _myNextMatch;
    final stat = _myStats[widget.myClub.id]!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('내 팀 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Image.asset(widget.myClub.logo, width: 80, height: 80),
                    const SizedBox(height: 8),
                    Text(widget.myClub.name, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 16),
                    Text('현재 성적: ${stat.wins}승 ${stat.losses}패'),
                    Text('득실차: ${stat.pointDifference}'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: stat.form.map((res) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: res == 'W' ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(res, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('다음 경기 일정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (myNextMatch == null)
                      Column(
                        children: [
                          const Text('정규 시즌 일정이 종료되었습니다.', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _startOffseason,
                            icon: const Icon(Icons.autorenew),
                            label: const Text('오프시즌 및 드래프트 진입', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.amber, 
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Image.asset(myNextMatch.home.logo, width: 60, height: 60),
                              const Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              Image.asset(myNextMatch.away.logo, width: 60, height: 60),
                            ],
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => _playMatch(myNextMatch),
                            child: const Text('경기 시작'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mySchedule.rounds.length,
      itemBuilder: (context, index) {
        final matches = _mySchedule.rounds[index];
        final myMatch = matches.firstWhere((m) => m.home == widget.myClub || m.away == widget.myClub);
        
        bool isPast = index < currentRound;
        bool isCurrent = index == currentRound;
        
        String resultText = '';
        if (isPast) {
          final stat = _myStats[widget.myClub.id]!;
          if (index < stat.matchScores.length) {
            final form = stat.form[index];
            final score = stat.matchScores[index];
            resultText = form == 'W' ? '승리 ($score)' : '패배 ($score)';
          }
        }

        return Card(
          color: isCurrent ? Colors.blue.withOpacity(0.2) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCurrent ? Colors.blue : Colors.grey,
              child: Text('${index + 1}R'),
            ),
            title: Text('${myMatch.home.name} vs ${myMatch.away.name}'),
            subtitle: isPast ? Text(resultText, style: TextStyle(color: resultText.contains('승리') ? Colors.green : Colors.red, fontWeight: FontWeight.bold)) : (isCurrent ? const Text('이번 라운드') : const Text('예정')),
            trailing: isCurrent ? FilledButton(
              onPressed: () => _playMatch(myMatch),
              child: const Text('진행'),
            ) : null,
          ),
        );
      },
    );
  }

  Widget _buildRosterTab(Club club) {
    final roster = widget.data.rosterFor(club);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: roster.length,
        itemBuilder: (context, index) {
          final p = roster[index];
          return _buildPlayerCard(p);
        },
      ),
    );
  }

  Widget _buildPlayerCard(Player p) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showPlayerProfile(p),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    p.sourcePortrait.isNotEmpty ? p.sourcePortrait : p.portrait,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
              Text(p.tag, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('OVR ${p.overall}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlayerProfile(Player p) {
    // Get player stats (KDA)
    final stats = _myStats[p.clubId]?.playerStats[p.id] ?? PlayerSeasonStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(p.sourcePortrait.isNotEmpty ? p.sourcePortrait : p.portrait, width: 250, height: 250, fit: BoxFit.cover),
                      const SizedBox(height: 16),
                      Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('OVR ${p.overall}', style: const TextStyle(fontSize: 20, color: Colors.amber)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('선수 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      Text(p.description),
                      const SizedBox(height: 16),
                      const Text('시즌 기록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statBox('K', stats.kills.toString()),
                          _statBox('D', stats.deaths.toString()),
                          _statBox('A', stats.assists.toString()),
                          _statBox('KDA', stats.kda.toStringAsFixed(2)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statBox('승리', stats.wins.toString(), color: Colors.green),
                          _statBox('패배', stats.losses.toString(), color: Colors.red),
                          _statBox('승률', '${(stats.winRate * 100).toStringAsFixed(1)}%'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('세부 능력치', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      _buildStatBar('에임', p.aim),
                      _buildStatBar('반응속도', p.reaction),
                      _buildStatBar('상황판단', p.judgment),
                      _buildStatBar('공격성', p.aggression),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildStatBar(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 99.0,
              backgroundColor: Colors.grey[800],
              color: value >= 80 ? Colors.amber : (value >= 60 ? Colors.green : Colors.blue),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: 30, child: Text(value.toString(), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildLeagueTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _viewedLeagueRound = (_viewedLeagueRound ?? currentRound) - 1;
                    if (_viewedLeagueRound! < 0) _viewedLeagueRound = 0;
                  });
                },
              ),
              Text('${(_viewedLeagueRound ?? currentRound) + 1} 라운드 일정', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _viewedLeagueRound = (_viewedLeagueRound ?? currentRound) + 1;
                    final max = widget.div1Schedule.rounds.length - 1;
                    if (_viewedLeagueRound! > max) _viewedLeagueRound = max;
                  });
                },
              ),
              if (_viewedLeagueRound != currentRound)
                TextButton(
                  onPressed: () => setState(() => _viewedLeagueRound = currentRound),
                  child: const Text('현재 라운드로'),
                ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('1부 리그', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const Divider(),
                      Expanded(child: _buildRoundSchedule(widget.div1Schedule, div1Stats)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('2부 리그', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const Divider(),
                      Expanded(child: _buildRoundSchedule(widget.div2Schedule, div2Stats)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoundSchedule(LeagueSchedule schedule, Map<String, TeamStats> stats) {
    int roundIndex = _viewedLeagueRound ?? currentRound;
    if (roundIndex >= schedule.rounds.length) return const Center(child: Text('일정 없음'));
    
    final matches = schedule.rounds[roundIndex];
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final m = matches[index];
        final homeStat = stats[m.home.id]!;
        bool isPast = roundIndex < currentRound;
        String scoreTxt = 'VS';
        if (isPast) {
          if (roundIndex < homeStat.matchScores.length) {
            scoreTxt = homeStat.matchScores[roundIndex]; // e.g. "6:4"
          }
        }
        return ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m.home.name),
              const SizedBox(width: 8),
              Image.asset(m.home.logo, width: 24, height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(scoreTxt, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Image.asset(m.away.logo, width: 24, height: 24),
              const SizedBox(width: 8),
              Text(m.away.name),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStandingsTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildStandingsTable('1부 리그', widget.div1, div1Stats)),
        Expanded(child: _buildStandingsTable('2부 리그', widget.div2, div2Stats)),
      ],
    );
  }

  Widget _buildStandingsTable(String title, List<Club> div, Map<String, TeamStats> stats) {
    List<Club> sorted = List.from(div);
    sorted.sort((a, b) {
      final sA = stats[a.id]!;
      final sB = stats[b.id]!;
      if (sA.wins != sB.wins) return sB.wins.compareTo(sA.wins);
      return sB.pointDifference.compareTo(sA.pointDifference);
    });

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('순위')),
                  DataColumn(label: Text('팀')),
                  DataColumn(label: Text('승')),
                  DataColumn(label: Text('패')),
                  DataColumn(label: Text('득실차')),
                ],
                rows: List.generate(sorted.length, (index) {
                  final club = sorted[index];
                  final stat = stats[club.id]!;
                  return DataRow(
                    color: club == widget.myClub ? MaterialStateProperty.all(Colors.amber.withOpacity(0.2)) : null,
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Row(
                        children: [
                          Image.asset(club.logo, width: 24, height: 24),
                          const SizedBox(width: 8),
                          Text(club.name),
                        ],
                      )),
                      DataCell(Text('${stat.wins}')),
                      DataCell(Text('${stat.losses}')),
                      DataCell(Text('${stat.pointDifference}')),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    if (_selectedInfoClub == null) return const SizedBox();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('팀 선택: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              DropdownButton<Club>(
                value: _selectedInfoClub,
                items: [
                  ...widget.div1.map((c) => DropdownMenuItem(value: c, child: Text('1부 - ${c.name}'))),
                  ...widget.div2.map((c) => DropdownMenuItem(value: c, child: Text('2부 - ${c.name}'))),
                ],
                onChanged: (c) {
                  if (c != null) setState(() => _selectedInfoClub = c);
                },
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(child: _buildRosterTab(_selectedInfoClub!)),
      ],
    );
  }

  void _playMatch(Matchup match) async {
    // 맵 랜덤 선택 로직! (HTML 엔진에 정의된 맵 ID 사용)
    final maps = ['industrial', 'ring', 'cross', 'switchback', 'pinhole'];
    final randomMap = maps[Random().nextInt(maps.length)];

    final config = MatchConfig(
      matchId: '${match.home.id}_${match.away.id}_$currentRound',
      seed: Random().nextInt(9999999),
      mapId: randomMap,
      teamA: match.home,
      teamB: match.away,
      teamAPlayers: widget.data.rosterFor(match.home),
      teamBPlayers: widget.data.rosterFor(match.away),
    );

    final result = await Navigator.push<MatchResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MatchScreen(config: config),
      ),
    );

    if (result != null && mounted) {
      _processRoundResults(result, match);
    }
  }

  void _processRoundResults(MatchResult myMatchResult, Matchup myMatch) {
    setState(() {
      final isHomeA = myMatchResult.teamAName == myMatch.home.name;
      final homeScore = isHomeA ? myMatchResult.teamAScore : myMatchResult.teamBScore;
      final awayScore = isHomeA ? myMatchResult.teamBScore : myMatchResult.teamAScore;
      
      _myStats[myMatch.home.id]!.addResult(homeScore, awayScore);
      _myStats[myMatch.away.id]!.addResult(awayScore, homeScore);
      
      // KDA 반영 (내 경기 기록)
      _updatePlayerStats(_myStats[myMatch.home.id]!, myMatchResult, myMatch.home, isHomeA);
      _updatePlayerStats(_myStats[myMatch.away.id]!, myMatchResult, myMatch.away, !isHomeA);

      // 자동 시뮬레이션 (다른 매치들)
      final rng = Random();
      final allMatches = _mySchedule.rounds[currentRound];
      for (var m in allMatches) {
        if (m == myMatch) continue;
        
        final winnerIsHome = rng.nextBool();
        final loserScore = rng.nextInt(6);
        
        if (winnerIsHome) {
          _myStats[m.home.id]!.addResult(6, loserScore);
          _myStats[m.away.id]!.addResult(loserScore, 6);
          _simulatePlayerStats(_myStats[m.home.id]!, _myStats[m.away.id]!, m.home, m.away, true);
        } else {
          _myStats[m.away.id]!.addResult(6, loserScore);
          _myStats[m.home.id]!.addResult(loserScore, 6);
          _simulatePlayerStats(_myStats[m.home.id]!, _myStats[m.away.id]!, m.home, m.away, false);
        }
      }

      // 다른 디비전 시뮬레이션
      final otherSchedule = _isDiv1 ? widget.div2Schedule : widget.div1Schedule;
      final otherStats = _isDiv1 ? div2Stats : div1Stats;
      
      if (currentRound < otherSchedule.rounds.length) {
        for (var m in otherSchedule.rounds[currentRound]) {
          final winnerIsHome = rng.nextBool();
          final loserScore = rng.nextInt(6);
          if (winnerIsHome) {
            otherStats[m.home.id]!.addResult(6, loserScore);
            otherStats[m.away.id]!.addResult(loserScore, 6);
            _simulatePlayerStats(otherStats[m.home.id]!, otherStats[m.away.id]!, m.home, m.away, true);
          } else {
            otherStats[m.away.id]!.addResult(6, loserScore);
            otherStats[m.home.id]!.addResult(loserScore, 6);
            _simulatePlayerStats(otherStats[m.home.id]!, otherStats[m.away.id]!, m.home, m.away, false);
          }
        }
      }

      currentRound++;
      _viewedLeagueRound = null;
    });
    
    _saveGameData(null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${myMatchResult.winnerName} 승리! 다음 라운드로 진행합니다. (자동 저장됨)')),
    );
  }

  void _updatePlayerStats(TeamStats teamStat, MatchResult result, Club club, bool isTeamA) {
    for (var p in result.players) {
      if ((isTeamA && p['team'] == 'A') || (!isTeamA && p['team'] == 'B')) {
        final ps = teamStat.playerStats.putIfAbsent(p['id'], () => PlayerSeasonStats());
        ps.kills += (p['kills'] as num).toInt();
        ps.deaths += (p['deaths'] as num).toInt();
        ps.assists += (p['assists'] as num).toInt();
        if (result.winnerName == club.name) {
          ps.wins++;
        } else {
          ps.losses++;
        }
      }
    }
  }

  void _simulatePlayerStats(TeamStats homeStat, TeamStats awayStat, Club home, Club away, bool homeWins) {
    final rng = Random();
    for (var id in home.rosterIds) {
      final ps = homeStat.playerStats.putIfAbsent(id, () => PlayerSeasonStats());
      ps.kills += rng.nextInt(15) + 5;
      ps.deaths += rng.nextInt(10) + 5;
      ps.assists += rng.nextInt(8) + 2;
      homeWins ? ps.wins++ : ps.losses++;
    }
    for (var id in away.rosterIds) {
      final ps = awayStat.playerStats.putIfAbsent(id, () => PlayerSeasonStats());
      ps.kills += rng.nextInt(15) + 5;
      ps.deaths += rng.nextInt(10) + 5;
      ps.assists += rng.nextInt(8) + 2;
      !homeWins ? ps.wins++ : ps.losses++;
    }
  }

  Future<void> _startOffseason() async {
    final updatedRosters = await OffseasonManager.runOffseason(
      context: context,
      data: widget.data,
      myClub: widget.myClub,
      div1: widget.div1,
      div2: widget.div2,
      div1Stats: div1Stats,
      div2Stats: div2Stats,
    );

    if (updatedRosters != null && mounted) {
      setState(() {
        for (final club in widget.data.clubs) {
          if (updatedRosters.containsKey(club.id)) {
            club.rosterIds = updatedRosters[club.id]!;
          }
        }
        for (final stat in div1Stats.values) stat.resetSeason();
        for (final stat in div2Stats.values) stat.resetSeason();
        currentRound = 0;
        _viewedLeagueRound = null;
        widget.div1Schedule.rounds.clear();
        widget.div1Schedule.rounds.addAll(LeagueSystem.generateDoubleRoundRobin(widget.div1).rounds);
        widget.div2Schedule.rounds.clear();
        widget.div2Schedule.rounds.addAll(LeagueSystem.generateDoubleRoundRobin(widget.div2).rounds);
      });
      _saveGameData(null, customRosters: updatedRosters);
    }
  }

  Future<void> _saveGameData(int? manualSlot, {Map<String, List<String>>? customRosters}) async {
    final stats = <String, dynamic>{};
    for (var entry in div1Stats.entries) stats[entry.key] = entry.value.toJson();
    for (var entry in div2Stats.entries) stats[entry.key] = entry.value.toJson();
    
    Map<String, List<String>> rostersToSave = customRosters ?? {};
    if (rostersToSave.isEmpty) {
      for (final club in widget.data.clubs) rostersToSave[club.id] = club.rosterIds;
    }

    final data = SaveData(
      currentRound: currentRound,
      myClubId: widget.myClub.id,
      div1Ids: widget.div1.map((c) => c.id).toList(),
      div2Ids: widget.div2.map((c) => c.id).toList(),
      stats: stats,
      customRosters: rostersToSave,
    );
    
    if (manualSlot == null) {
      await SaveManager.saveAuto(data);
    } else {
      await SaveManager.saveManual(manualSlot, data);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('슬롯 $manualSlot 저장 완료')));
    }
  }
}
