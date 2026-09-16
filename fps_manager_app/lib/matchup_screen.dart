import 'package:flutter/material.dart';
import 'game_data.dart';
import 'models.dart';
import 'match_screen.dart';
import 'league_system.dart';

class MatchupScreen extends StatefulWidget {
  const MatchupScreen({
    super.key,
    required this.data,
    required this.matchup,
    required this.roundIndex,
  });

  final GameData data;
  final Matchup matchup;
  final int roundIndex;

  @override
  State<MatchupScreen> createState() => _MatchupScreenState();
}

class _MatchupScreenState extends State<MatchupScreen> {
  static const maps = <String, String>{
    'industrial': 'Industrial',
    'service_ring': 'Service Ring',
    'cross': 'Cross Yard',
    'switchback': 'Switchback',
    'pinhole': 'Pinhole',
  };
  String mapId = 'industrial';

  @override
  Widget build(BuildContext context) {
    final a = widget.matchup.home;
    final b = widget.matchup.away;
    final rosterA = widget.data.rosterFor(a);
    final rosterB = widget.data.rosterFor(b);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roundIndex + 1}주차 매치업'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _TeamCard(club: a, players: rosterA),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                      child: Text(
                        'VS',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: _TeamCard(club: b, players: rosterB),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: mapId,
                      decoration: const InputDecoration(
                        labelText: '경기 맵',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: maps.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (value) => setState(() => mapId = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final config = MatchConfig(
                        matchId: 'league_r${widget.roundIndex}_${a.id}_${b.id}',
                        seed: DateTime.now().millisecondsSinceEpoch,
                        mapId: mapId,
                        teamA: a,
                        teamB: b,
                        teamAPlayers: rosterA,
                        teamBPlayers: rosterB,
                      );
                      final result = await Navigator.of(context).push<MatchResult>(
                        MaterialPageRoute(builder: (_) => MatchScreen(config: config)),
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop(result);
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('게임 시작', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.club, required this.players});
  final Club club;
  final List<Player> players;
  @override
  Widget build(BuildContext context) {
    const roles = ['엔트리', '서포트', '스나이퍼', '러커', '앵커'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Image.asset(
                  club.logo,
                  height: 36,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.shield, size: 36),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    club.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(players.length, (index) {
                    final p = players[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundImage: p.portrait.isEmpty
                                  ? null
                                  : AssetImage(p.portrait),
                              child: p.portrait.isEmpty
                                  ? Text(p.name.characters.first, style: const TextStyle(fontSize: 9))
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 3,
                              child: Text(
                                p.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                roles[index % roles.length],
                                style: const TextStyle(fontSize: 10, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Text(
                              'OVR ${p.overall}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
