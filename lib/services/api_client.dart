import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiClient {
// PHP 8.2 backend base
static const String base = 'https://ido05.tw1.ru/api';


final http.Client _client;
ApiClient([http.Client? client]) : _client = client ?? http.Client();


Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body,
{Map<String, String>? headers}) async {
final res = await _client.post(Uri.parse('$base$path'),
headers: {'Content-Type': 'application/json', ...?headers},
body: jsonEncode(body));
return _decode(res);
}


Future<Map<String, dynamic>> get(String path,
{Map<String, String>? headers}) async {
final res = await _client.get(Uri.parse('$base$path'), headers: headers);
return _decode(res);
}


Map<String, dynamic> _decode(http.Response r) {
if (r.statusCode < 200 || r.statusCode >= 300) {
throw HttpException('HTTP ${r.statusCode}: ${r.body}');
}
final data = jsonDecode(r.body);
if (data is Map<String, dynamic>) return data;
throw const FormatException('Invalid JSON');
}
}


class HttpException implements Exception {
final String message;
const HttpException(this.message);
@override
String toString() => message;
}