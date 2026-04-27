import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  String? _sessionCookie;
  bool _isInit = false;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get sessionCookie => _sessionCookie;
  bool get isInitialized => _isInit;

  static const _storage = FlutterSecureStorage();

  // 앱 진입 시 자동 로그인 시도
  Future<void> checkAutoLogin() async {
    if (_isInit) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAutoLogin = prefs.getBool('autoLogin') ?? false;

      if (isAutoLogin) {
        final loginId = prefs.getString('loginId');
        final password = await _storage.read(key: 'password');

        if (loginId != null && loginId.isNotEmpty && password != null && password.isNotEmpty) {
          final res = await login(loginId, password, saveCredentials: true);
          if (res['success'] != true) {
            // 실패 시 자동 로그인 정보 만료/삭제 처리 (이건 선택적이지만 안정성을 위해)
            await _clearCredentials();
          }
        }
      }
    } catch (e) {
      debugPrint('Auto Login Check Error: $e');
    } finally {
      _isInit = true;
      notifyListeners();
    }
  }

  // 1. 로그인 메서드
  Future<Map<String, dynamic>> login(String loginId, String password, {bool saveCredentials = false}) async {
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
        
        final String? rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          _sessionCookie = _extractSessionId(rawCookie);
        }

        // --- 자동 로그인 정보 저장 로직 ---
        final prefs = await SharedPreferences.getInstance();
        if (saveCredentials) {
          await prefs.setBool('autoLogin', true);
          await prefs.setString('loginId', loginId);
          await _storage.write(key: 'password', value: password);
        } else {
          // 자동로그인 해제 상태로 로그인했다면 정보 파기
          await _clearCredentials();
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
    } catch (e) {
      debugPrint('Logout Request Error: $e'); // 실패해도 클라이언트 세션은 종료
    } finally {
      _user = null;
      _sessionCookie = null;
      await _clearCredentials();
      notifyListeners();
    }
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('autoLogin');
    await prefs.remove('loginId');
    await _storage.delete(key: 'password');
  }

  // 쿠키에서 세션 ID 부분만 추출하는 헬퍼 (JSESSIONID=...; Path=...)
  String? _extractSessionId(String rawCookie) {
    if (rawCookie.isEmpty) return null;
    return rawCookie.split(';').first;
  }
}
