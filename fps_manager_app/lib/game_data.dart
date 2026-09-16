import 'dart:convert';
import 'package:flutter/services.dart';
import 'models.dart';

class GameData {
  const GameData(this.clubs, this.players);
  final List<Club> clubs;
  final List<Player> players;
  static Future<GameData> load() async {
    final values = await Future.wait([
      rootBundle.loadString('assets/data/clubs.json'),
      rootBundle.loadString('assets/data/players.json'),
    ]);
    final clubs = (jsonDecode(values[0]) as List)
        .map((e) => Club.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final players = (jsonDecode(values[1]) as List)
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return GameData(clubs, players);
  }

  List<Player> rosterFor(Club club) => club.rosterIds
      .map((id) => players.firstWhere((p) => p.id == id))
      .take(5)
      .toList();
}
