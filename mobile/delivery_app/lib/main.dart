import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/features/auth/ui/screens/login_screen.dart';
import 'package:delivery_app/features/delivery/ui/screens/home_screen.dart';
import 'package:delivery_app/features/delivery/services/permission_service.dart';
import 'package:delivery_app/features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DeliveryApp()));
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinFlow Delivery',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

// ============================================================
// AuthWrapper с проверкой при восстановлении
// ============================================================
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> with WidgetsBindingObserver {
  bool _isChecking = true;
  bool _isAuthChecked = false;

  @override
  void initState() {
    super.initState();
    print('🔐🔐🔐 AuthWrapper: initState ВЫЗВАН 🔐🔐🔐');
    WidgetsBinding.instance.addObserver(this);
    _checkAuthAndPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔐 AuthWrapper: didChangeAppLifecycleState = $state');
    if (state == AppLifecycleState.resumed && _isAuthChecked) {
      // При возвращении на передний план проверяем авторизацию заново
      print('🔐 AuthWrapper: приложение возобновлено, проверяем авторизацию...');
      _checkAuthAndPermissions();
    }
  }

  Future<void> _checkAuthAndPermissions() async {
    print('🔐 AuthWrapper: началась проверка...');
    
    final hasPermission = await PermissionService.requestLocationPermission(context);
    print('🔐 AuthWrapper: разрешение на геолокацию = $hasPermission');
    
    if (!hasPermission) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
      return;
    }

    try {
      print('🔐 AuthWrapper: проверка авторизации...');
      final authNotifier = ref.read(authProvider.notifier);
      final isAuthenticated = await authNotifier.autoLogin();
      print('🔐 AuthWrapper: isAuthenticated = $isAuthenticated');
      _isAuthChecked = true;

      if (!mounted) return;

      if (isAuthenticated) {
        print('🔐 AuthWrapper: пользователь авторизован, переход на /home');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print('🔐 AuthWrapper: пользователь НЕ авторизован, переход на /login');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('🔐 AuthWrapper: ошибка при проверке авторизации: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔐 AuthWrapper: build вызван, _isChecking = $_isChecking');
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF6C63FF),
              ),
              SizedBox(height: 20),
              Text(
                'Загрузка...',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delivery_dining,
              size: 80,
              color: Color(0xFF6C63FF),
            ),
            const SizedBox(height: 20),
            const Text(
              'FinFlow Доставка',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Для работы приложения требуется доступ к геолокации',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _isChecking = true);
                _checkAuthAndPermissions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Разрешить доступ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}