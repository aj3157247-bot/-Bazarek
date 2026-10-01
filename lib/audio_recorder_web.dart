import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

html.MediaStream? _stream;
html.MediaRecorder? _recorder;
final List<html.Blob> _chunks = [];
bool isRecording = false;
String _mimeType = 'audio/webm';

Future<bool> start() async {
  if (isRecording) return true;
  try {
    final devices = html.window.navigator.mediaDevices;
    if (devices == null) return false;

    _stream = await devices.getUserMedia({'audio': true});
    _chunks.clear();

    _mimeType = 'audio/webm';
    try {
      if (!html.MediaRecorder.isTypeSupported('audio/webm')) {
        _mimeType = 'audio/ogg';
      }
    } catch (_) {}

    _recorder = html.MediaRecorder(_stream!, {'mimeType': _mimeType});
    _recorder!.on['dataavailable'].listen((event) {
      try {
        final blobEvent = event as html.BlobEvent;
        final data = blobEvent.data;
        if (data != null && data.size > 0) {
          _chunks.add(data);
        }
      } catch (_) {}
    });

    _recorder!.start(250);
    isRecording = true;
    return true;
  } catch (_) {
    await cancel();
    return false;
  }
}

Future<Uint8List?> stop() async {
  if (!isRecording || _recorder == null) return null;

  final recorder = _recorder!;
  final completer = Completer<void>();
  late StreamSubscription sub;
  sub = recorder.on['stop'].listen((_) {
    if (!completer.isCompleted) completer.complete();
    sub.cancel();
  });

  try {
    recorder.stop();
    await completer.future.timeout(const Duration(seconds: 5));

    if (_chunks.isEmpty) return null;

    final blob = html.Blob(_chunks, _mimeType);
    final reader = html.FileReader();
    final read = Completer<Uint8List?>();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        read.complete(Uint8List.view(result));
      } else if (result is Uint8List) {
        read.complete(result);
      } else {
        read.complete(null);
      }
    });
    reader.onError.listen((_) {
      if (!read.isCompleted) read.complete(null);
    });

    reader.readAsArrayBuffer(blob);
    return await read.future.timeout(const Duration(seconds: 10));
  } catch (_) {
    return null;
  } finally {
    isRecording = false;
    _stream?.getTracks().forEach((track) => track.stop());
    _stream = null;
    _recorder = null;
    _chunks.clear();
  }
}

Future<void> cancel() async {
  try {
    if (_recorder != null && isRecording) _recorder!.stop();
  } catch (_) {}
  isRecording = false;
  _stream?.getTracks().forEach((track) => track.stop());
  _stream = null;
  _recorder = null;
  _chunks.clear();
}
