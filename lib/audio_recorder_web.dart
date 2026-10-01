import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

html.MediaStream? _stream;
html.MediaRecorder? _recorder;
final List<html.Blob> _chunks = <html.Blob>[];
bool isRecording = false;
String _mimeType = 'audio/webm';

String _pickMimeType() {
  const candidates = <String>[
    'audio/webm;codecs=opus',
    'audio/webm',
    'audio/ogg;codecs=opus',
    'audio/ogg',
  ];
  for (final type in candidates) {
    try {
      if (html.MediaRecorder.isTypeSupported(type)) return type;
    } catch (_) {}
  }
  return '';
}

Future<bool> start() async {
  if (isRecording) return true;
  try {
    final devices = html.window.navigator.mediaDevices;
    if (devices == null) return false;

    _stream = await devices.getUserMedia({'audio': true});
    _chunks.clear();

    _mimeType = _pickMimeType();
    _recorder = _mimeType.isEmpty
        ? html.MediaRecorder(_stream!)
        : html.MediaRecorder(_stream!, {'mimeType': _mimeType});

    _recorder!.on['dataavailable'].listen((event) {
      try {
        final data = (event as html.BlobEvent).data;
        if (data != null && data.size > 0) _chunks.add(data);
      } catch (_) {}
    });

    // Do not rely on a browser-specific timeslice. Some Android browsers
    // produce no chunks with start(timeslice), but do produce them after
    // requestData()/stop().
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
  final stopped = Completer<void>();

  late StreamSubscription stopSub;
  stopSub = recorder.on['stop'].listen((_) {
    if (!stopped.isCompleted) stopped.complete();
    stopSub.cancel();
  });

  try {
    // Force any buffered audio to be emitted before stopping.
    try {
      recorder.requestData();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 150));
    recorder.stop();
    await stopped.future.timeout(const Duration(seconds: 6));

    if (_chunks.isEmpty) return null;

    final type = _mimeType.isEmpty ? 'audio/webm' : _mimeType.split(';').first;
    final blob = html.Blob(_chunks, type);
    final reader = html.FileReader();
    final read = Completer<Uint8List?>();

    reader.onLoadEnd.listen((_) {
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
    reader.onError.listen((_) {
      if (!read.isCompleted) read.complete(null);
    });
    reader.readAsArrayBuffer(blob);

    return await read.future.timeout(const Duration(seconds: 10));
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
    if (_recorder != null && isRecording) _recorder!.stop();
  } catch (_) {}
  isRecording = false;
  try {
    _stream?.getTracks().forEach((track) => track.stop());
  } catch (_) {}
  _stream = null;
  _recorder = null;
  _chunks.clear();
}
