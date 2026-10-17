import 'package:flutter/material.dart';

import 'video_player_stub.dart'
    if (dart.library.html) 'video_player_web.dart' as impl;

/// پخش‌کننده‌ی ویدیوی آگهی (روی وب با تگ <video> بومی مرورگر).
class BazarekVideoPlayer extends StatelessWidget {
  final String url;
  const BazarekVideoPlayer({super.key, required this.url});

  @override
  Widget build(BuildContext context) => impl.buildVideoPlayer(context, url);
}
