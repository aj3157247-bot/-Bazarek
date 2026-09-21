String currentWebPath() => '/';

void setBrowserPath(String path) {}

void setWebSeo({
  required String title,
  required String description,
  String? urlPath,
  String? imageUrl,
  Map<String, dynamic>? product,
}) {}

Future<bool> shareWeb({
  required String title,
  required String text,
  required String url,
}) async => false;
