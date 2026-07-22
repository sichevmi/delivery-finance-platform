import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/screens/login_screen.dart';
import 'package:delivery_app/screens/register_screen.dart';
import 'package:delivery_app/screens/home_screen.dart';
import 'package:delivery_app/providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'FinFlow Delivery',
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            // Проверяем авторизацию
            final authState = ref.watch(authProvider);
            if (authState.user != null) {
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            } else {
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            }
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
