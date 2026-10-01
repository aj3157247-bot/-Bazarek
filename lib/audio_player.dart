import 'package:flutter/material.dart';

import 'audio_player_stub.dart'
    if (dart.library.html) 'audio_player_web.dart' as impl;

class BazarekAudioPlayer extends StatelessWidget {
  final String url;
  const BazarekAudioPlayer({super.key, required this.url});

  @override
  Widget build(BuildContext context) => impl.buildAudioPlayer(context, url);
}
