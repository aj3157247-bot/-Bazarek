import 'dart:typed_data';

import 'video_probe_stub.dart'
    if (dart.library.html) 'video_probe_web.dart' as impl;

Future<double?> probeVideoSeconds(Uint8List bytes, String mimeType) =>
    impl.probeVideoSeconds(bytes, mimeType);
