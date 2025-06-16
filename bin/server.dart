import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

final users = <Map<String, String>>[];

void main() async {
  final router = Router();

  // Тестовая ручка
  router.get('/ping', (Request request) {
    return Response.ok(
      jsonEncode({'response': 'pong'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Регистрация
  router.post('/register', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final email = data['email'];
    final password = data['password'];

    final exists = users.any((u) => u['email'] == email);
    if (exists) {
      return Response(
        400,
        body: jsonEncode({'error': 'Пользователь уже существует'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    users.add({'email': email, 'password': password});
    return Response.ok(
      jsonEncode({'message': 'Пользователь зарегистрирован'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Логин
  router.post('/login', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final email = data['email'];
    final password = data['password'];

    final user = users.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (user.isEmpty) {
      return Response(
        401,
        body: jsonEncode({'error': 'Неверный email или пароль'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({'message': 'Вход выполнен'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('✅ Сервер запущен на http://${server.address.host}:${server.port}');
}
