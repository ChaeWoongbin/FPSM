import 'package:flutter/material.dart';
import 'game_data.dart';
import 'models.dart';
import 'league_dashboard_screen.dart';
import 'league_system.dart';

class TeamSelectionScreen extends StatefulWidget {
  const TeamSelectionScreen({super.key});
  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  late final Future<GameData> _dataFuture = GameData.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('창단할 팀 선택')),
      body: FutureBuilder<GameData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('오류: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final game = snapshot.data!;
          // 1부, 2부 리그를 위해 domestic 팀 16개를 추립니다 (여기서는 임의로 앞 16개를 domestic이라고 가정하거나 kind로 필터).
          final domesticClubs = game.clubs.where((c) => c.kind == 'domestic').toList();
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: domesticClubs.length,
            itemBuilder: (context, index) {
              final club = domesticClubs[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    _startCareer(context, game, domesticClubs, club);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(club.logo, height: 60, errorBuilder: (_,__,___) => const Icon(Icons.shield, size: 60)),
                      const SizedBox(height: 12),
                      Text(club.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(index < 8 ? '1부 리그' : '2부 리그', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _startCareer(BuildContext context, GameData data, List<Club> domesticClubs, Club myClub) {
    // 1부 8팀, 2부 8팀으로 나누기 (현재는 index 순서대로)
    final div1 = domesticClubs.take(8).toList();
    final div2 = domesticClubs.skip(8).take(8).toList();

    // 상반기 대진표 생성
    final div1Schedule = LeagueSystem.generateDoubleRoundRobin(div1);
    final div2Schedule = LeagueSystem.generateDoubleRoundRobin(div2);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LeagueDashboardScreen(
          data: data,
          myClub: myClub,
          div1: div1,
          div2: div2,
          div1Schedule: div1Schedule,
          div2Schedule: div2Schedule,
        ),
      ),
    );
  }
}
