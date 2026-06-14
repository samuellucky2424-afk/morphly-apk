import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../services/supabase_gateway.dart';

class EdgeFunctionException implements Exception {
  const EdgeFunctionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EdgeFunctionClient {
  const EdgeFunctionClient({this.gateway = const SupabaseGateway()});

  final SupabaseGateway gateway;

  Future<Map<String, dynamic>> invokeMap(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    if (AppConfig.hasVercelBackend) {
      return _invokeVercel(functionName, body: body);
    }

    final response = await gateway.client.functions.invoke(
      functionName,
      body: body,
    );

    if (response.status >= 400) {
      throw EdgeFunctionException(
        'Morphly backend error (${response.status}) from $functionName.',
      );
    }

    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw EdgeFunctionException('Unexpected response from $functionName.');
  }

  Future<Map<String, dynamic>> _invokeVercel(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    final baseUrl = AppConfig.vercelApiBaseUrl.replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (gateway.isConfigured) {
      final token = gateway.client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await http.post(
      Uri.parse('$baseUrl/$functionName'),
      headers: headers,
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );

    if (response.statusCode >= 400) {
      throw EdgeFunctionException(
        'Morphly backend error (${response.statusCode}) from $functionName.',
      );
    }

    if (response.body.isEmpty) return const <String, dynamic>{};
    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw EdgeFunctionException('Unexpected response from $functionName.');
  }
}
