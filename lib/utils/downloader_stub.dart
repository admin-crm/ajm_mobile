abstract class FileDownloader {
  static Future<void> downloadFile(String url, String filename, Map<String, String> headers) {
    throw UnsupportedError('Cannot download file without platform implementation.');
  }
}
