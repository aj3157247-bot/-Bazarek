import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

int _nextId = 0;
final Map<String, String> _views = {};

Widget buildVideoPlayer(BuildContext context, String url) {
  var viewId = _views[url];
  if (viewId == null) {
    viewId = 'bazarek-video-${_nextId++}';
    _views[url] = viewId;
    final id = viewId;
    ui_web.platformViewRegistry.registerViewFactory(id, (int _) {
      final video = html.VideoElement()
        ..src = url
        ..controls = true
        ..preload = 'metadata'
        ..setAttribute('playsinline', 'true')
        ..setAttribute('controlsList', 'nodownload')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#000'
        ..style.objectFit = 'contain';
      return video;
    });
  }
  return AspectRatio(
    aspectRatio: 16 / 9,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: HtmlElementView(viewType: viewId),
    ),
  );
}
