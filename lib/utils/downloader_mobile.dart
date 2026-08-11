class FileDownloader {
  static Future<void> downloadFile(String url, String filename, Map<String, String> headers) async {
    // For mobile platforms, since we don't have path_provider or permission_handler added in pubspec,
    // we print a debug message. This avoids compilation errors on mobile/native devices.
    print('Downloading on mobile is not implemented. Target URL: $url');
    throw UnsupportedError('Download feature is currently supported on the Web platform. For mobile, please download via the HRM web portal.');
  }
}
