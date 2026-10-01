import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

int _nextId = 0;
final Map<String, String> _views = {};

Widget buildAudioPlayer(BuildContext context, String url) {
  final key = url;
  var viewId = _views[key];
  if (viewId == null) {
    viewId = 'bazarek-audio-${_nextId++}';
    _views[key] = viewId;
    final id = viewId;
    ui_web.platformViewRegistry.registerViewFactory(id, (int _) {
      final audio = html.AudioElement()
        ..src = url
        ..controls = true
        ..preload = 'metadata'
        ..style.width = '100%'
        ..style.height = '44px';
      return audio;
    });
  }
  return SizedBox(height: 48, child: HtmlElementView(viewType: viewId));
}
