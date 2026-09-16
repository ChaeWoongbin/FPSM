import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MatchView extends StatefulWidget {
  const MatchView({super.key, required this.configJson, required this.onMessage});
  final String configJson;
  final ValueChanged<String> onMessage;

  @override
  State<MatchView> createState() => MatchViewState();
}

class MatchViewState extends State<MatchView> with WidgetsBindingObserver {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xff07121d))
      ..addJavaScriptChannel(
        'MatchBridge',
        onMessageReceived: (message) => widget.onMessage(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => isLoading = false);
            _initialize();
          },
        ),
      )
      ..loadFlutterAsset('assets/web/match/index.html');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-resume when app comes back to foreground
      controller.runJavaScript('if(window.MatchGame) window.MatchGame.resume();');
    }
  }

  void togglePause() {
    controller.runJavaScript('if(typeof togglePause === "function") togglePause();');
  }

  Future<void> _initialize() => controller.runJavaScript(
    'window.MatchGame.initializeJson(${jsonEncode(widget.configJson)}); '
    'window.MatchGame.setSpeed(1); window.MatchGame.start();',
  );

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      WebViewWidget(controller: controller),
      if (isLoading)
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.tealAccent),
              SizedBox(height: 16),
              Text(
                '경기장 이동 중...',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
    ],
  );
}
