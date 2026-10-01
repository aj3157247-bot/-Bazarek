import 'dart:typed_data';

import 'audio_recorder_stub.dart'
    if (dart.library.html) 'audio_recorder_web.dart' as impl;

class AudioRecorderService {
  Future<bool> start() => impl.start();
  Future<Uint8List?> stop() => impl.stop();
  Future<void> cancel() => impl.cancel();
  bool get isRecording => impl.isRecording;
}
