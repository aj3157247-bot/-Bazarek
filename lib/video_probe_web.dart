import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// مدت ویدیو را (ثانیه) از متادیتای خودِ فایل می‌خواند؛ در صورت خطا null.
Future<double?> probeVideoSeconds(Uint8List bytes, String mimeType) async {
  final blob = html.Blob([bytes], mimeType.isEmpty ? 'video/mp4' : mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final video = html.VideoElement()
    ..preload = 'metadata'
    ..muted = true
    ..src = url;
  final done = Completer<double?>();
  video.onLoadedMetadata.first.then((_) {
    final d = video.duration.toDouble();
    if (!done.isCompleted) done.complete(d.isFinite && d > 0 ? d : null);
  });
  video.onError.first.then((_) {
    if (!done.isCompleted) done.complete(null);
  });
  try {
    return await done.future.timeout(const Duration(seconds: 8), onTimeout: () => null);
  } finally {
    html.Url.revokeObjectUrl(url);
    video.removeAttribute('src');
    video.load();
  }
}
