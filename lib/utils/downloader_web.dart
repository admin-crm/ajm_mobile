import 'dart:html' as html;
import 'package:http/http.dart' as http;

class FileDownloader {
  static Future<void> downloadFile(String url, String filename, Map<String, String> headers) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'application/pdf');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: blobUrl)
          ..setAttribute("download", filename)
          ..click();
        html.Url.revokeObjectUrl(blobUrl);
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
