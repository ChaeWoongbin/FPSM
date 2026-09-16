import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fps_manager_app/models.dart';
import 'package:fps_manager_app/match_screen.dart';

void main() {
  test('player bridge attributes are flattened and clamped', () {
    const player = Player(
      id: 'p1',
      name: 'Ace',
      clubId: 'c1',
      slot: 0,
      portrait: '',
      aim: 99,
      reaction: 75,
      judgment: 1,
      aggression: 70,
      description: '',
      tag: '',
    );
    final json = player.toMatchJson(0);
    final attributes = json['attributes'] as Map<String, dynamic>;
    expect(attributes['aim'], 99);
    expect(attributes['judgment'], 1);
    expect(json['slot'], 0);
  });

  test('overall is the rounded mean of every HTML match attribute', () {
    const player = Player(
      id: 'p1',
      name: 'Ace',
      clubId: 'c1',
      slot: 0,
      portrait: '',
      aim: 99,
      reaction: 75,
      judgment: 1,
      aggression: 70,
      description: '',
      tag: '',
    );

    final attributes = player.toMatchJson(0)['attributes']
        as Map<String, dynamic>;
    final recoil = attributes['recoil'] as Map<String, dynamic>;
    final matchRatings = <int>[
      attributes['aim'] as int,
      attributes['reaction'] as int,
      attributes['judgment'] as int,
      attributes['aggression'] as int,
      ...recoil.values.cast<int>(),
    ];

    expect(matchRatings, [99, 75, 1, 70, 97, 99, 99, 50, 84]);
    expect(player.overall, 75);
  });

  test('overall remains within the player rating range', () {
    const lowPlayer = Player(
      id: 'low',
      name: 'Low',
      clubId: 'c1',
      slot: 0,
      portrait: '',
      aim: 1,
      reaction: 1,
      judgment: 1,
      aggression: 1,
      description: '',
      tag: '',
    );
    const highPlayer = Player(
      id: 'high',
      name: 'High',
      clubId: 'c1',
      slot: 0,
      portrait: '',
      aim: 99,
      reaction: 99,
      judgment: 99,
      aggression: 99,
      description: '',
      tag: '',
    );

    expect(lowPlayer.overall, 1);
    expect(highPlayer.overall, 99);
  });

  test('result keeps external map and team names', () {
    final result = MatchResult.fromJson({
      'matchId': 'm1',
      'map': {'id': 'service_ring'},
      'winner': 'EMBER',
      'scores': {'EMBER': 4, 'TIDE': 2},
      'teams': {
        'EMBER': {'name': 'Aurora'},
        'TIDE': {'name': 'Titan'},
      },
      'totals': [],
    });
    expect(result.winnerName, 'Aurora');
    expect(result.mapId, 'service_ring');
    expect(result.teamAScore, 4);
  });

  test('web and Android match messages use the trusted bridge envelope', () {
    final event = decodeMatchBridgeMessage(
      '{"source":"fps-manager-match","type":"match_end","payload":{"matchId":"web-1"}}',
    );
    expect(event['type'], 'match_end');
    expect((event['payload'] as Map)['matchId'], 'web-1');
  });

  test('bridge messages from another source are rejected', () {
    expect(
      () => decodeMatchBridgeMessage(
        '{"source":"other","type":"match_end","payload":{}}',
      ),
      throwsFormatException,
    );
  });

  test('native match view reserves landscape cutout space', () {
    expect(
      matchSafeAreaMinimum(false),
      const EdgeInsets.symmetric(horizontal: 16),
    );
    expect(matchSafeAreaMinimum(true), EdgeInsets.zero);
  });
}
