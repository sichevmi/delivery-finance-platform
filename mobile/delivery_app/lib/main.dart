// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/features/auth/ui/screens/login_screen.dart';
import 'package:delivery_app/features/delivery/ui/screens/home_screen.dart';
import 'package:delivery_app/features/delivery/services/permission_service.dart';
import 'package:delivery_app/features/auth/providers/auth_provider.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/core/database/database_provider.dart';
import 'package:delivery_app/logger_simple.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  // ПРИНУДИТЕЛЬНО создаём лог-файл и пишем в него
  try {
    // Сначала выводим в консоль
    print('🔴 MAIN: START');
    
    // Получаем папку приложения
    final dir = await getApplicationDocumentsDirectory();
    print('🔴 DOC DIR: ${dir.path}');
    
    // Создаём папку logs
    final logDir = Directory('${dir.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
      print('🔴 LOG DIR CREATED');
    } else {
      print('🔴 LOG DIR ALREADY EXISTS');
    }
    
    // Создаём файл
    final fileName = 'app_log_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.txt';
    final logFile = File('${logDir.path}/$fileName');
    print('🔴 LOG FILE: ${logFile.path}');
    
    // Пишем в файл
    logFile.writeAsStringSync(
      '${DateTime.now().toIso8601String()} 🚀 ПРИЛОЖЕНИЕ ЗАПУЩЕНО\n',
      mode: FileMode.append,
    );
    print('🔴 LOG WRITTEN TO FILE');
    
    // Сохраняем в глобальную переменную для дальнейшего использования
    AppLogger._logFile = logFile;
    AppLogger._isReady = true;
    
  } catch (e) {
    print('❌ LOGGER INIT ERROR: $e');
  }
  
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.log('✅ Flutter инициализирован');
  
  final container = ProviderContainer();
  AppLogger.log('✅ Контейнер создан');
  
  try {
    final db = container.read(appDatabaseProvider);
    AppLogger.log('📁 База данных инициализирована');
  } catch (e) {
    AppLogger.log('⚠️ Ошибка БД: $e');
  }
  
  ref.read(gpsInitProvider);
  AppLogger.log('🟢 GPS инициализирован');
  
  AppLogger.log('🚀 ЗАПУСК APP');
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DeliveryApp(),
    ),
  );
  
  AppLogger.log('✅ APP ЗАПУЩЕН');
}

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
    AppLogger.log('🔐 DeliveryApp: инициализация...');
    
    final hasPermission = await PermissionService.requestLocationPermission(context);
    AppLogger.log('🔐 DeliveryApp: разрешение = $hasPermission');
    
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
      AppLogger.log('🔐 DeliveryApp: авторизован = $isAuthenticated');
      
      ref.read(gpsInitProvider);
      AppLogger.log('🟢 GPS провайдер инициализирован');
      
      setState(() {
        _hasPermission = true;
        _isAuthenticated = isAuthenticated;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.log('🔐 DeliveryApp: ошибка: $e');
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