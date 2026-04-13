class ApiConfig {
  // 백엔드 주소 (에뮬레이터 사용 시 10.0.2.2, 실제 기기나 웹은 localhost/IP 사용)
  static const String baseUrl = 'http://localhost:8080';
  
  static const String loginUrl = '$baseUrl/api/users/login';
  static const String logoutUrl = '$baseUrl/api/users/logout';
  static const String registerUrl = '$baseUrl/api/users/register';
  static const String companiesUrl = '$baseUrl/api/system/companies';
  
  // 공통 헤더
  static Map<String, String> getHeaders(String? cookie) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (cookie != null) {
      headers['Cookie'] = cookie;
    }
    return headers;
  }
}
