import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SaveData {
  final int currentRound;
  final String myClubId;
  final List<String> div1Ids;
  final List<String> div2Ids;
  final Map<String, dynamic> stats;
  final Map<String, List<String>> customRosters;

  SaveData({
    required this.currentRound,
    required this.myClubId,
    required this.div1Ids,
    required this.div2Ids,
    required this.stats,
    this.customRosters = const {},
  });

  Map<String, dynamic> toJson() => {
    'currentRound': currentRound,
    'myClubId': myClubId,
    'div1Ids': div1Ids,
    'div2Ids': div2Ids,
    'stats': stats,
    'customRosters': customRosters,
  };

  factory SaveData.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> parseRosters(dynamic val) {
      if (val == null) return {};
      final map = val as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, List<String>.from(v)));
    }
    return SaveData(
      currentRound: json['currentRound'] as int,
      myClubId: json['myClubId'] as String,
      div1Ids: List<String>.from(json['div1Ids']),
      div2Ids: List<String>.from(json['div2Ids']),
      stats: json['stats'] as Map<String, dynamic>,
      customRosters: parseRosters(json['customRosters']),
    );
  }
}

class SaveManager {
  static const String _autoSaveKey = 'save_auto';
  static String _manualKey(int slot) => 'save_manual_$slot';

  static Future<void> saveAuto(SaveData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_autoSaveKey, jsonEncode(data.toJson()));
  }

  static Future<void> saveManual(int slot, SaveData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_manualKey(slot), jsonEncode(data.toJson()));
  }

  static Future<SaveData?> loadAuto() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_autoSaveKey);
    if (str == null) return null;
    return SaveData.fromJson(jsonDecode(str));
  }

  static Future<SaveData?> loadManual(int slot) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_manualKey(slot));
    if (str == null) return null;
    return SaveData.fromJson(jsonDecode(str));
  }
}
