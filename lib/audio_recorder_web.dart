import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

html.MediaStream? _stream;
html.MediaRecorder? _recorder;
final List<html.Blob> _chunks = <html.Blob>[];
bool isRecording = false;

Future<bool> start() async {
  if (isRecording) return true;
  try {
    final devices = html.window.navigator.mediaDevices;
    if (devices == null) return false;

    _stream = await devices.getUserMedia(<String, dynamic>{'audio': true});
    _chunks.clear();

    // Let the browser choose its native supported audio format. Forcing
    // audio/webm can fail on some Android browsers/webviews.
    html.MediaRecorder? recorder;
    try {
      recorder = html.MediaRecorder(_stream!);
    } catch (_) {
      try {
        recorder = html.MediaRecorder(_stream!, 'audio/webm;codecs=opus');
      } catch (_) {
        try {
          recorder = html.MediaRecorder(_stream!, 'audio/ogg;codecs=opus');
        } catch (_) {
          await cancel();
          return false;
        }
      }
    }

    _recorder = recorder;
    _recorder!.onDataAvailable.listen((html.BlobEvent event) {
      final data = event.data;
      if (data != null && data.size > 0) {
        _chunks.add(data);
      }
    });

    _recorder!.start();
    isRecording = true;
    return true;
  } catch (_) {
    await cancel();
    return false;
  }
}

Future<Uint8List?> stop() async {
  final recorder = _recorder;
  if (!isRecording || recorder == null) return null;

  final completer = Completer<void>();
  late StreamSubscription<html.Event> sub;
  sub = recorder.onStop.listen((_) {
    if (!completer.isCompleted) completer.complete();
    sub.cancel();
  });

  try {
    try {
      recorder.requestData();
    } catch (_) {}
    recorder.stop();
    await completer.future.timeout(const Duration(seconds: 6));

    if (_chunks.isEmpty) return null;

    final mime = recorder.mimeType.isNotEmpty ? recorder.mimeType : 'audio/webm';
    final blob = html.Blob(_chunks, mime);
    final reader = html.FileReader();
    final read = Completer<Uint8List?>();
    late StreamSubscription loadSub;
    late StreamSubscription errorSub;

    void cleanup() {
      loadSub.cancel();
      errorSub.cancel();
    }

    loadSub = reader.onLoadEnd.listen((_) {
      if (read.isCompleted) return;
      final result = reader.result;
      if (result is ByteBuffer) {
        read.complete(Uint8List.view(result));
      } else if (result is Uint8List) {
        read.complete(result);
      } else {
        read.complete(null);
      }
    });
    errorSub = reader.onError.listen((_) {
      if (!read.isCompleted) read.complete(null);
    });

    reader.readAsArrayBuffer(blob);
    final result = await read.future.timeout(const Duration(seconds: 10));
    cleanup();
    return result;
  } catch (_) {
    return null;
  } finally {
    isRecording = false;
    try {
      _stream?.getTracks().forEach((track) => track.stop());
    } catch (_) {}
    _stream = null;
    _recorder = null;
    _chunks.clear();
  }
}

Future<void> cancel() async {
  try {
    if (_recorder != null && isRecording) {
      _recorder!.stop();
    }
  } catch (_) {}

  isRecording = false;
  try {
    _stream?.getTracks().forEach((track) => track.stop());
  } catch (_) {}
  _stream = null;
  _recorder = null;
  _chunks.clear();
}
