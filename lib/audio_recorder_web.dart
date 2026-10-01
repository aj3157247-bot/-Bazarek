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

    // Let the browser choose its native format first. If that fails, try
    // common WebM/OGG MIME types using the current dart:html constructor API.
    html.MediaRecorder? recorder;
    try {
      recorder = html.MediaRecorder(_stream!);
    } catch (_) {
      for (final mime in <String>[
        'audio/webm;codecs=opus',
        'audio/webm',
        'audio/ogg;codecs=opus',
        'audio/ogg',
      ]) {
        try {
          if (!html.MediaRecorder.isTypeSupported(mime)) continue;
          recorder = html.MediaRecorder(_stream!, <String, dynamic>{'mimeType': mime});
          break;
        } catch (_) {}
      }
    }

    if (recorder == null) {
      await cancel();
      return false;
    }

    _recorder = recorder;

    // MediaRecorder exposes these as generic DOM events in the current
    // dart:html bindings, so use the generic event accessor instead of
    // removed onDataAvailable/onStop getters.
    _recorder!.on['dataavailable'].listen((html.Event event) {
      if (event is html.BlobEvent) {
        final data = event.data;
        if (data != null && data.size > 0) {
          _chunks.add(data);
        }
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
  sub = recorder.on['stop'].listen((_) {
    if (!completer.isCompleted) completer.complete();
    sub.cancel();
  });

  try {
    // The final dataavailable event is emitted when stop() is called.
    recorder.stop();
    await completer.future.timeout(const Duration(seconds: 6));

    if (_chunks.isEmpty) return null;

    final mime = recorder.mimeType ?? 'audio/webm';
    final blob = html.Blob(_chunks, mime);
    final reader = html.FileReader();
    final read = Completer<Uint8List?>();
    late StreamSubscription<html.Event> loadSub;
    late StreamSubscription<html.Event> errorSub;

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
