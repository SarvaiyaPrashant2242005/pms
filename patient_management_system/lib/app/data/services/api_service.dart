// import 'dart:convert';
// import 'dart:async';
// import 'dart:io';
// import 'package:http/http.dart' as http;

// class ApiService {
//   static const String baseUrl = 'http://192.168.1.6:3000';

//   static Map<String, String> defaultHeaders({String? token}) {
//     return {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (token != null) 'Authorization': 'Bearer $token',
//     };
//   }

//   static Future<dynamic> post(String endpoint, Map<String, dynamic> data, {String? token}) async {
//     final uri = Uri.parse('$baseUrl/$endpoint');
//     try {
//       final response = await http
//           .post(
//             uri,
//             headers: defaultHeaders(token: token),
//             body: jsonEncode(data),
//           )
//           .timeout(const Duration(seconds: 15));
//       return _handleResponse(response);
//     } on TimeoutException {
//       throw Exception('Request timed out. Please check your network/server.');
//     } on SocketException catch (e) {
//       throw Exception('Network error: ${e.message}. Is the server reachable at $baseUrl?');
//     } catch (e) {
//       throw Exception('Unexpected error: $e');
//     }
//   }

//   static dynamic _handleResponse(http.Response response) {
//     final bodyText = response.body.isNotEmpty ? response.body : null;
//     final isJson = response.headers['content-type']?.contains('application/json') ?? false;
//     final parsed = isJson && bodyText != null
//         ? _tryParseJson(bodyText)
//         : bodyText;

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       return parsed is Map || parsed is List ? parsed : {};
//     }

//     final message = parsed is Map && parsed['message'] != null
//         ? parsed['message']
//         : parsed is Map && parsed['error'] != null
//             ? parsed['error']
//             : 'Request failed with status: ${response.statusCode}';
//     throw Exception(message);
//   }

//   static dynamic _tryParseJson(String text) {
//     try {
//       return jsonDecode(text);
//     } catch (_) {
//       return text;
//     }
//   }
// }
