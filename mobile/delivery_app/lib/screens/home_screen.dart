import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/providers/auth_provider.dart';
import 'package:delivery_app/providers/api_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final dio = ref.read(dioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authNotifier.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Привет, ${authState.user?.email ?? ''}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await dio.get('/auth/hello');
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Hello World'),
                      content: Text(response.data['message'] ?? 'No message'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        )
                      ],
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Ошибка получения приветствия')),
                  );
                }
              },
              child: const Text('Получить Hello World'),
            ),
          ],
        ),
      ),
    );
  }
}
