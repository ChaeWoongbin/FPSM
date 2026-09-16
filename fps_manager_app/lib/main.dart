import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_data.dart';
import 'models.dart';
import 'match_screen.dart';
import 'team_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FpsManagerApp());
}

class FpsManagerApp extends StatelessWidget {
  const FpsManagerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FPS Manager',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff49a995),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff0b1720),
      useMaterial3: true,
    ),
    home: const TitleScreen(),
  );
}

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Image.asset(
              'assets/main_bg.png',
              fit: BoxFit.fitHeight,
              alignment: Alignment.centerRight,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Positioned(
            left: 80,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TeamSelectionScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.tealAccent,
                    side: const BorderSide(color: Colors.tealAccent, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 22),
                    textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('게임 시작'),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('설정 화면은 준비 중입니다.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white70, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 22),
                    textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('설정 옵션'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MatchResult? lastResult;
  static const maps = <String, String>{
    'industrial': 'Industrial',
    'service_ring': 'Service Ring',
    'cross': 'Cross Yard',
    'switchback': 'Switchback',
    'pinhole': 'Pinhole',
  };
  late final Future<GameData> data = GameData.load();
  String mapId = maps.keys.first;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('FPS MANAGER'),
      actions: [
        if (lastResult != null)
          IconButton(
            onPressed: () => _showResult(lastResult!),
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: '최근 결과',
          ),
      ],
    ),
    body: FutureBuilder<GameData>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('데이터 로드 실패: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final game = snapshot.data!,
            a = game.clubs[0],
            b = game.clubs[1],
            rosterA = game.rosterFor(a),
            rosterB = game.rosterFor(b);
        return SafeArea(
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
                          .map(
                            (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => mapId = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final config = MatchConfig(
                        matchId: 'friendly_${DateTime.now().millisecondsSinceEpoch}',
                        seed: 54321,
                        mapId: mapId,
                        teamA: a,
                        teamB: b,
                        teamAPlayers: rosterA,
                        teamBPlayers: rosterB,
                      );
                      final result = await Navigator.of(context).push<MatchResult>(
                        MaterialPageRoute(
                          builder: (_) => MatchScreen(config: config),
                        ),
                      );
                      if (result != null && mounted) {
                        setState(() => lastResult = result);
                        _showResult(result);
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('경기 시작', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
      },
    ),
  );
  void _showResult(MatchResult result) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('${result.winnerName} 승리'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${result.teamAName} ${result.teamAScore} : ${result.teamBScore} ${result.teamBName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('맵 ${maps[result.mapId] ?? result.mapId} · ${result.matchId}'),
            const Divider(),
            ...result.players
                .take(5)
                .map(
                  (p) => ListTile(
                    dense: true,
                    title: Text('${p['name']}'),
                    trailing: Text(
                      '${p['kills'] ?? 0} / ${p['deaths'] ?? 0} / ${p['assists'] ?? 0}',
                    ),
                  ),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );
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
