import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

http.Client getClient() {
  final browserClient = BrowserClient();
  browserClient.withCredentials = true;
  return browserClient;
}
