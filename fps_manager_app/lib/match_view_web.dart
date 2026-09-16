// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class MatchView extends StatefulWidget {
  const MatchView({
    super.key,
    required this.configJson,
    required this.onMessage,
  });
  final String configJson;
  final ValueChanged<String> onMessage;

  @override
  State<MatchView> createState() => MatchViewState();
}

class MatchViewState extends State<MatchView> {
  static int nextId = 0;
  late final String viewType;

  void togglePause() {
    // Unsupported on web for now
  }
  late final html.IFrameElement iframe;
  StreamSubscription<html.MessageEvent>? messages;
  StreamSubscription<html.Event>? iframeLoads;
  bool initialized = false;

  void initializeFrame() {
    if (initialized) return;
    initialized = true;
    iframe.contentWindow?.postMessage(
      jsonEncode({
        'source': 'fps-manager-flutter',
        'type': 'fps_manager_initialize',
        'config': jsonDecode(widget.configJson),
      }),
      html.window.location.origin,
    );
  }

  @override
  void initState() {
    super.initState();
    viewType = 'fps-match-${nextId++}';
    iframe = html.IFrameElement()
      ..src = 'assets/assets/web/match/index.html'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = '0';
    iframeLoads = iframe.onLoad.listen((_) => initializeFrame());
    messages = html.window.onMessage.listen((event) {
      if (event.origin != html.window.location.origin ||
          event.data is! String) {
        return;
      }
      try {
        final raw = event.data as String;
        final decoded = jsonDecode(raw) as Map;
        if (decoded['source'] != 'fps-manager-match') return;
        if (decoded['type'] == 'fps_manager_ready') {
          initializeFrame();
        } else {
          widget.onMessage(raw);
        }
      } on FormatException {
        // Ignore unrelated same-origin window messages.
      }
    });
    ui_web.platformViewRegistry.registerViewFactory(viewType, (_) => iframe);
  }

  @override
  void dispose() {
    messages?.cancel();
    iframeLoads?.cancel();
    iframe.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: viewType);
}
