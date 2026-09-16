import 'package:flutter/material.dart';
import 'models.dart';
import 'game_data.dart';
import 'league_system.dart';
import 'dart:math';

class OffseasonManager {
  static Future<Map<String, List<String>>?> runOffseason({
    required BuildContext context,
    required GameData data,
    required Club myClub,
    required List<Club> div1,
    required List<Club> div2,
    required Map<String, TeamStats> div1Stats,
    required Map<String, TeamStats> div2Stats,
  }) async {
    bool isDiv1 = div1.contains(myClub);
    List<Club> myDiv = isDiv1 ? div1 : div2;
    Map<String, TeamStats> myDivStats = isDiv1 ? div1Stats : div2Stats;

    // Determine Draft Order (worst first)
    List<Club> draftOrder = List.from(myDiv);
    draftOrder.sort((a, b) {
      final statA = myDivStats[a.id]!;
      final statB = myDivStats[b.id]!;
      if (statA.wins != statB.wins) return statA.wins.compareTo(statB.wins);
      return statA.pointDifference.compareTo(statB.pointDifference);
    });

    final random = Random();
    
    // 1. Release Phase
    List<Player> draftPool = [];
    Map<String, List<String>> updatedRosters = {};
    for (final club in data.clubs) {
      updatedRosters[club.id] = List.from(club.rosterIds);
    }

    // Determine my released player via UI
    final myRoster = data.rosterFor(myClub);
    final myReleasedPlayer = await showDialog<Player>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ReleasePhaseDialog(roster: myRoster),
    );

    if (myReleasedPlayer == null) return null; // user cancelled? Wait, barrierDismissible is false, but what if they press back?

    // Execute Release for all clubs in MY DIVISION
    // Wait, the prompt says "1부, 2부 따로 방출하고 따로 드래프트".
    // I will only run the draft for MY DIVISION for simplicity, or both?
    // Let's run both simultaneously in the background, but only show MY DIVISION.
    
    void processDivisionRelease(List<Club> div, List<Player> pool) {
      for (final club in div) {
        if (club == myClub) {
          updatedRosters[myClub.id]!.remove(myReleasedPlayer.id);
          pool.add(myReleasedPlayer);
        } else {
          final roster = data.rosterFor(club).toList();
          // AI Logic: Protect the highest OVR. Release a random from remaining.
          roster.sort((a, b) => b.overall.compareTo(a.overall));
          final protected = roster.first;
          roster.remove(protected);
          final released = roster[random.nextInt(roster.length)];
          updatedRosters[club.id]!.remove(released.id);
          pool.add(released);
        }
      }
    }

    List<Player> myDivPool = [];
    processDivisionRelease(myDiv, myDivPool);

    List<Player> otherDivPool = [];
    List<Club> otherDiv = isDiv1 ? div2 : div1;
    processDivisionRelease(otherDiv, otherDivPool);

    // 2. Draft Phase (My Division UI)
    // Run AI drafts for other div instantly
    List<Club> otherDraftOrder = List.from(otherDiv);
    Map<String, TeamStats> otherDivStats = isDiv1 ? div2Stats : div1Stats;
    otherDraftOrder.sort((a, b) {
      final statA = otherDivStats[a.id]!;
      final statB = otherDivStats[b.id]!;
      if (statA.wins != statB.wins) return statA.wins.compareTo(statB.wins);
      return statA.pointDifference.compareTo(statB.pointDifference);
    });
    
    for (final club in otherDraftOrder) {
      otherDivPool.sort((a, b) => b.overall.compareTo(a.overall));
      final pick = otherDivPool.removeAt(0);
      updatedRosters[club.id]!.add(pick.id);
    }

    // Run Draft UI for My Division
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DraftPhaseDialog(
        myClub: myClub,
        draftOrder: draftOrder,
        pool: myDivPool,
        updatedRosters: updatedRosters,
      ),
    );

    if (success == true) {
      return updatedRosters;
    }
    return null;
  }
}

class _ReleasePhaseDialog extends StatefulWidget {
  final List<Player> roster;
  const _ReleasePhaseDialog({required this.roster});

  @override
  State<_ReleasePhaseDialog> createState() => _ReleasePhaseDialogState();
}

class _ReleasePhaseDialogState extends State<_ReleasePhaseDialog> {
  Player? protectedPlayer;

  void _confirm() {
    if (protectedPlayer == null) return;
    final remaining = widget.roster.where((p) => p != protectedPlayer).toList();
    final released = remaining[Random().nextInt(remaining.length)];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('방출 결과'),
        content: Text('${protectedPlayer!.name} 선수를 보호했습니다.\n나머지 4명 중 랜덤 추첨 결과, [${released.name}] 선수가 드래프트 풀로 방출되었습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close alert
              Navigator.pop(context, released); // return released player
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('오프시즌: 선수 보호 (1명)'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('다음 시즌까지 팀에 남길 핵심 선수 1명을 보호 지정하세요. 지정된 선수 외의 4명 중 랜덤으로 1명이 방출되어 드래프트에 오릅니다.'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.roster.map((p) {
                final isSelected = p == protectedPlayer;
                return InkWell(
                  onTap: () => setState(() => protectedPlayer = p),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: isSelected ? Colors.amber : Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? Colors.amber.withOpacity(0.2) : Colors.transparent,
                    ),
                    width: 110,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(backgroundImage: AssetImage(p.portrait)),
                        const SizedBox(height: 4),
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        Text('OVR ${p.overall}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: protectedPlayer == null ? null : _confirm,
          child: const Text('결정'),
        ),
      ],
    );
  }
}

class _DraftPhaseDialog extends StatefulWidget {
  final Club myClub;
  final List<Club> draftOrder;
  final List<Player> pool;
  final Map<String, List<String>> updatedRosters;

  const _DraftPhaseDialog({
    required this.myClub,
    required this.draftOrder,
    required this.pool,
    required this.updatedRosters,
  });

  @override
  State<_DraftPhaseDialog> createState() => _DraftPhaseDialogState();
}

class _DraftPhaseDialogState extends State<_DraftPhaseDialog> {
  int currentPickIndex = 0;
  List<String> pickLog = [];
  bool get isMyTurn => widget.draftOrder[currentPickIndex] == widget.myClub;

  @override
  void initState() {
    super.initState();
    _processAIPicks();
  }

  void _processAIPicks() async {
    while (currentPickIndex < widget.draftOrder.length && !isMyTurn) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      
      final club = widget.draftOrder[currentPickIndex];
      widget.pool.sort((a, b) => b.overall.compareTo(a.overall));
      final pick = widget.pool.removeAt(0);
      widget.updatedRosters[club.id]!.add(pick.id);
      
      setState(() {
        pickLog.add('${club.name} -> ${pick.name} (OVR ${pick.overall})');
        currentPickIndex++;
      });
    }
    
    if (currentPickIndex >= widget.draftOrder.length) {
      _finish();
    }
  }

  void _finish() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('드래프트 종료'),
        content: const Text('드래프트가 완료되었습니다. 새로운 시즌을 시작합니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('확인'),
          )
        ],
      )
    );
  }

  void _pickPlayer(Player p) {
    if (!isMyTurn) return;
    setState(() {
      widget.pool.remove(p);
      widget.updatedRosters[widget.myClub.id]!.add(p.id);
      pickLog.add('${widget.myClub.name} -> ${p.name} (OVR ${p.overall})');
      currentPickIndex++;
    });
    _processAIPicks();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('오프시즌: 방출 선수 드래프트'),
      content: SizedBox(
        width: 800,
        height: 500,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('드래프트 픽 순서 (성적 역순)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.draftOrder.length,
                      itemBuilder: (context, index) {
                        final club = widget.draftOrder[index];
                        final isCurrent = index == currentPickIndex;
                        return ListTile(
                          leading: CircleAvatar(backgroundImage: AssetImage(club.logo)),
                          title: Text(club.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? Colors.amber : Colors.white)),
                          trailing: isCurrent ? const Icon(Icons.arrow_left, color: Colors.amber) : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 32),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('드래프트 풀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: widget.pool.length,
                      itemBuilder: (context, index) {
                        final p = widget.pool[index];
                        return Card(
                          color: isMyTurn ? Colors.grey[850] : Colors.grey[900],
                          child: InkWell(
                            onTap: isMyTurn ? () => _pickPlayer(p) : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(backgroundImage: AssetImage(p.portrait)),
                                  const SizedBox(height: 4),
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  Text('OVR ${p.overall}', style: const TextStyle(color: Colors.amber)),
                                  Text(p.tag, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
