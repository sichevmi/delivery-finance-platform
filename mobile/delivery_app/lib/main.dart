// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/features/auth/ui/screens/login_screen.dart';
import 'package:delivery_app/features/delivery/ui/screens/home_screen.dart';
import 'package:delivery_app/features/delivery/services/permission_service.dart';
import 'package:delivery_app/features/auth/providers/auth_provider.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/database/database_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ПРОВЕРКА: создаём папку вручную и логируем
  try {
    final directory = await getApplicationDocumentsDirectory();
    print('🔴 DOC DIR: ${directory.path}');
    
    final logDir = Directory('${directory.path}/logs');
    print('🔴 LOG DIR PATH: ${logDir.path}');
    
    final exists = await logDir.exists();
    print('🔴 LOG DIR EXISTS: $exists');
    
    if (!exists) {
      await logDir.create(recursive: true);
      print('🔴 LOG DIR CREATED');
    }
    
    // Проверяем, что папка действительно создалась
    final checkExists = await logDir.exists();
    print('🔴 LOG DIR EXISTS AFTER CREATE: $checkExists');
    
    // Создаём тестовый файл
    final testFile = File('${logDir.path}/test.txt');
    await testFile.writeAsString('Тестовый файл');
    print('🔴 TEST FILE CREATED: ${testFile.path}');
    
  } catch (e) {
    print('🔴 ERROR: $e');
  }
  
  // ... дальше инициализация логгера
  await LoggerService().init();
  
  // Теперь можно использовать logMessage
  logMessage('🚀 Приложение запущено', category: 'SYSTEM');
  
  // Создаём контейнер для провайдеров
  final container = ProviderContainer();
  
  // Инициализируем базу данных
  try {
    final db = container.read(appDatabaseProvider);
    logMessage('📁 База данных инициализирована', category: 'DATABASE');
  } catch (e) {
    logMessage('⚠️ Ошибка инициализации БД: $e', category: 'DATABASE', level: LogLevel.error);
  }
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DeliveryApp(),
    ),
  );
}

// ... остальной код без изменений

class DeliveryApp extends ConsumerStatefulWidget {
  const DeliveryApp({super.key});

  @override
  ConsumerState<DeliveryApp> createState() => _DeliveryAppState();
}

class _DeliveryAppState extends ConsumerState<DeliveryApp> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    logMessage('🔐 DeliveryApp: инициализация...', category: 'SYSTEM');
    
    final hasPermission = await PermissionService.requestLocationPermission(context);
    logMessage('🔐 DeliveryApp: разрешение на геолокацию = $hasPermission', category: 'SYSTEM');
    
    if (!hasPermission) {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
      return;
    }

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final isAuthenticated = await authNotifier.autoLogin();
      logMessage('🔐 DeliveryApp: isAuthenticated = $isAuthenticated', category: 'SYSTEM');
      
      // Инициализируем GPS
      ref.read(gpsInitProvider);
      logMessage('🟢 GPS провайдер инициализирован', category: 'SYSTEM');
      
      setState(() {
        _hasPermission = true;
        _isAuthenticated = isAuthenticated;
        _isLoading = false;
      });
    } catch (e) {
      logMessage('🔐 DeliveryApp: ошибка: $e', category: 'SYSTEM', level: LogLevel.error);
      setState(() {
        _hasPermission = true;
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinFlow Delivery',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 20),
              Text('Загрузка...', style: TextStyle(color: Color(0xFF888888))),
            ],
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delivery_dining, size: 80, color: Color(0xFF6C63FF)),
              const SizedBox(height: 20),
              const Text('FinFlow Доставка', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                'Для работы приложения требуется доступ к геолокации',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Разрешить доступ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}