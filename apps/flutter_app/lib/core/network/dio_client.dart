import 'package:dio/dio.dart';

class DioClient {
  DioClient({
    required this.baseUrl,
    required this.apiPrefix,
    required this.userId,
  }) {
    final normalizedBase = baseUrl.replaceFirst(RegExp(r'/$'), '');
    final basePath = Uri.parse(normalizedBase).path;
    final baseAlreadyContainsPrefix =
        basePath == apiPrefix || basePath.endsWith('$apiPrefix');

    dio = Dio(
      BaseOptions(
        baseUrl: normalizedBase,
        headers: {'x-user-id': userId},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final path = options.path;
          if (!baseAlreadyContainsPrefix &&
              path.startsWith('/') &&
              !path.startsWith(apiPrefix)) {
            options.path = '$apiPrefix$path';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final uri = error.requestOptions.uri.toString();
          final status = error.response?.statusCode;
          // Helps quickly distinguish timeout/DNS/404/server-side failures on devices.
          print(
            '[NET] ${error.type} status=$status uri=$uri message=${error.message}',
          );
          handler.next(error);
        },
      ),
    );
  }

  final String baseUrl;
  final String apiPrefix;
  final String userId;
  late final Dio dio;
}
