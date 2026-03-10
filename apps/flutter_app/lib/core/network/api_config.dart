class ApiConfig {
  ApiConfig._();

  static const _baseUrlDefine = String.fromEnvironment('API_BASE_URL');
  static const _userIdDefine = String.fromEnvironment('API_USER_ID');
  static const _apiPrefixDefine = String.fromEnvironment('API_PREFIX');

  static String get baseUrl {
    if (_baseUrlDefine.trim().isNotEmpty) {
      return _baseUrlDefine.trim().replaceFirst(RegExp(r'/$'), '');
    }

    // Default host for Windows/Android builds.
    return 'https://ycoming.top';
  }

  static String get apiPrefix {
    if (_apiPrefixDefine.trim().isNotEmpty) {
      return _normalizePrefix(_apiPrefixDefine.trim());
    }
    return '/notes-api/v1';
  }

  static String get userId {
    if (_userIdDefine.trim().isNotEmpty) {
      return _userIdDefine.trim();
    }
    return 'demo-user-id';
  }

  static String _normalizePrefix(String value) {
    var v = value.trim();
    if (v.isEmpty) {
      return '';
    }
    if (!v.startsWith('/')) {
      v = '/$v';
    }
    return v.replaceFirst(RegExp(r'/$'), '');
  }
}
