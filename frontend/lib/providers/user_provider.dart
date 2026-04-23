import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/api_config.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  String? _sessionCookie;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get sessionCookie => _sessionCookie;

  // 1. 로그인 메서드
  Future<Map<String, dynamic>> login(String loginId, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: ApiConfig.getHeaders(null),
        body: jsonEncode({
          'loginId': loginId,
          'password': password,
        }),
      );

      final Map<String, dynamic> result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        _user = UserModel.fromJson(result['data']);
        
        // 세션 쿠키 추출 및 저장 (JSESSIONID 등)
        final String? rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          _sessionCookie = _extractSessionId(rawCookie);
        }
        
        notifyListeners();
        return {'success': true};
      }
      return {'success': false, 'message': result['message'] ?? '로그인에 실패했습니다.'};
    } catch (e) {
      debugPrint('Login Error: $e');
      return {'success': false, 'message': '서버에 연결할 수 없습니다.'};
    }
  }

  // 2. 로그아웃 메서드
  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse(ApiConfig.logoutUrl),
        headers: ApiConfig.getHeaders(_sessionCookie),
      );
    } finally {
      _user = null;
      _sessionCookie = null;
      notifyListeners();
    }
  }

  // 쿠키에서 세션 ID 부분만 추출하는 헬퍼 (JSESSIONID=...; Path=...)
  String? _extractSessionId(String rawCookie) {
    if (rawCookie.isEmpty) return null;
    return rawCookie.split(';').first;
  }
}
