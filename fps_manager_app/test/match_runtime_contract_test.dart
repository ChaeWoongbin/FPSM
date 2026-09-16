import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter and browser bridges auto-start at real-time speed', () {
    final mobileBridge = File(
      'lib/match_view_mobile.dart',
    ).readAsStringSync();
    final htmlEngine = File(
      'assets/web/match/index.html',
    ).readAsStringSync();

    expect(
      mobileBridge,
      contains('window.MatchGame.setSpeed(1); window.MatchGame.start();'),
    );
    expect(
      htmlEngine,
      contains(
        'window.MatchGame.initialize(command.config);\n'
        '  window.MatchGame.setSpeed(1);\n'
        '  window.MatchGame.start();',
      ),
    );
  });

  test('HTML game view retains cutout-aware safe-area fallbacks', () {
    final htmlEngine = File(
      'assets/web/match/index.html',
    ).readAsStringSync();

    expect(
      htmlEngine,
      contains('--safe-left:max(26px,env(safe-area-inset-left));'),
    );
    expect(
      htmlEngine,
      contains('--safe-right:max(26px,env(safe-area-inset-right));'),
    );
    expect(
      htmlEngine,
      contains(
        'padding:var(--safe-top) var(--safe-right) '
        'var(--safe-bottom) var(--safe-left)',
      ),
    );
  });
}
