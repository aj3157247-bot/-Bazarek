import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

html.MediaStream? _stream;
html.MediaRecorder? _recorder;
final List<html.Blob> _chunks = [];
bool isRecording = false;

Future<bool> start() async {
  if (isRecording) return true;
  try {
    _stream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
    _chunks.clear();
    _recorder = html.MediaRecorder(_stream!, {'mimeType': 'audio/webm'});
    _recorder!.on['dataavailable'].listen((event) {
      final blobEvent = event as html.BlobEvent;
      final data = blobEvent.data;
      if (data != null && data.size > 0) _chunks.add(data);
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
    final blob = html.Blob(_chunks, 'audio/webm');
    final reader = html.FileReader();
    final read = Completer<Uint8List?>();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        read.complete(Uint8List.view(result));
      } else {
        read.complete(null);
      }
    });
    reader.onError.listen((_) => read.complete(null));
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
