import 'package:http/http.dart' as http;

http.Client getClient() => throw UnsupportedError('Cannot create client without platform context');
