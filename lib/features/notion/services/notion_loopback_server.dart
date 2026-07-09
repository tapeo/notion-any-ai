import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class NotionCallbackResult {
  const NotionCallbackResult({
    this.code,
    this.state,
    this.error,
  });

  final String? code;
  final String? state;
  final String? error;
}

class NotionLoopbackServer {
  NotionLoopbackServer();

  HttpServer? _server;
  int? _port;
  final _completer = Completer<NotionCallbackResult>();

  String get redirectUri => 'http://localhost:$_port/callback';

  bool get isRunning => _server != null;

  Future<String> start() async {
    if (_server != null) {
      await stop();
    }
    _completer;
    final handler = const Pipeline().addHandler(_handle);
    _server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    return redirectUri;
  }

  Future<NotionCallbackResult> waitForCallback({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    return _completer.future.timeout(timeout, onTimeout: () {
      throw TimeoutException('OAuth callback timed out');
    });
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
  }

  Response _handle(Request request) {
    if (request.url.path != 'callback') {
      return Response.notFound('Not found');
    }
    final params = request.requestedUri.queryParameters;
    final code = params['code'];
    final state = params['state'];
    final error = params['error'];

    if (!_completer.isCompleted) {
      _completer.complete(NotionCallbackResult(code: code, state: state, error: error));
    }

    final html = _buildResponseHtml(error != null, error);
    return Response.ok(html, headers: {'Content-Type': 'text/html'});
  }

  String _buildResponseHtml(bool isError, String? error) {
    final title = isError ? 'Connection failed' : 'Connected';
    final message = isError
        ? 'Notion connection failed${error != null ? ': $error' : ''}.'
        : 'Notion connected. You can close this tab and return to the app.';
    return '''
<!DOCTYPE html>
<html>
<head><title>$title</title></head>
<body style="font-family: system-ui, sans-serif; padding: 40px; text-align: center;">
  <h2>$title</h2>
  <p style="color: #666;">$message</p>
</body>
</html>
''';
  }
}