import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'match_view.dart';
import 'models.dart';

Map<String, dynamic> decodeMatchBridgeMessage(String message) {
  final event = Map<String, dynamic>.from(jsonDecode(message) as Map);
  if (event['source'] != 'fps-manager-match') {
    throw const FormatException('Unexpected match bridge source');
  }
  return event;
}

@visibleForTesting
EdgeInsets matchSafeAreaMinimum(bool isWeb) => isWeb
    ? EdgeInsets.zero
    : const EdgeInsets.symmetric(horizontal: 16);

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key, required this.config});
  final MatchConfig config;
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final GlobalKey<MatchViewState> _matchViewKey = GlobalKey<MatchViewState>();
  String? error;
  bool resultHandled = false;
  int viewAttempt = 0;
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _onBridgeMessage(String message) {
    try {
      final event = decodeMatchBridgeMessage(message);
      if (event['type'] == 'error') {
        setState(
          () => error =
              (event['payload'] as Map?)?['message']?.toString() ??
              'HTML 엔진 오류',
        );
      } else if (event['type'] == 'match_end' && !resultHandled) {
        resultHandled = true;
        Navigator.of(context).pop(
          MatchResult.fromJson(
            Map<String, dynamic>.from(event['payload'] as Map),
          ),
        );
      }
    } catch (e) {
      setState(() => error = '브리지 메시지 해석 실패: $e');
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      _matchViewKey.currentState?.togglePause();
    },
    child: Scaffold(
      backgroundColor: const Color(0xff07121d),
      body: SafeArea(
        left: !kIsWeb,
        top: false,
        right: !kIsWeb,
        bottom: false,
        minimum: matchSafeAreaMinimum(kIsWeb),
        child: error == null
            ? MatchView(
                key: _matchViewKey,
                configJson: widget.config.encode(),
                onMessage: _onBridgeMessage,
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 54),
                    const SizedBox(height: 12),
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          error = null;
                          viewAttempt++;
                          // Replace the key on retry to create a fresh view
                        });
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
      ),
    ),
  );
}
