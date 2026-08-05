import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/auth/providers/auth_provider.dart';
import 'package:delivery_app/features/auth/ui/screens/login_screen.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/providers/logger_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MoreTab extends ConsumerStatefulWidget {
  const MoreTab({super.key});

  @override
  ConsumerState<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends ConsumerState<MoreTab> {
  bool _isLoggingEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoggingStatus();
    });
  }

  void _checkLoggingStatus() {
    // Статус логирования в GpsService
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final gpsService = ref.read(gpsServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Ещё'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: Icon(
              _isLoggingEnabled ? Icons.record_voice_over : Icons.record_voice_over_outlined,
              color: _isLoggingEnabled ? Colors.green : Colors.grey,
            ),
            onPressed: () => _toggleLogging(gpsService),
            tooltip: _isLoggingEnabled ? 'Остановить логирование' : 'Начать логирование',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildUserCard(authState),
          const SizedBox(height: 24),

          const Text(
            'Настройки',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined, color: Color(0xFF6C63FF)),
              title: const Text('Уведомления', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF888888)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Настройки уведомлений в разработке'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Material(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              leading: const Icon(Icons.language_outlined, color: Color(0xFF6C63FF)),
              title: const Text('Язык', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF888888)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Смена языка в разработке'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Логирование',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          Material(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              leading: Icon(
                _isLoggingEnabled ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: const Color(0xFF6C63FF),
              ),
              title: Text(
                _isLoggingEnabled ? 'Остановить запись GPS' : 'Начать запись GPS',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                _isLoggingEnabled ? 'Логирование активно' : 'Логирование выключено',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
              trailing: _isLoggingEnabled
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Активно',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const Icon(Icons.chevron_right, color: Color(0xFF888888)),
              onTap: () => _toggleLogging(gpsService),
            ),
          ),
          const SizedBox(height: 4),
          
          Material(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              leading: const Icon(Icons.gps_fixed_outlined, color: Color(0xFF6C63FF)),
              title: const Text('Просмотр GPS логов', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Открыть файл с логами GPS', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF888888)),
              onTap: () => _showGpsLogFile(gpsService),
            ),
          ),
          const SizedBox(height: 4),
          
          Material(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              leading: const Icon(Icons.description_outlined, color: Color(0xFF6C63FF)),
              title: const Text('Все логи приложения', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                kIsWeb ? 'Логи хранятся в памяти' : 'Полные логи работы приложения',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF888888)),
              onTap: () => _showAppLogs(),
            ),
          ),
          const SizedBox(height: 4),
          
          if (!kIsWeb) ...[
            Material(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              child: ListTile(
                leading: const Icon(Icons.share_outlined, color: Color(0xFF6C63FF)),
                title: const Text('Отправить логи', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Отправить файл с логами', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF888888)),
                onTap: () => _shareLogs(gpsService),
              ),
            ),
            const SizedBox(height: 4),
            
            Material(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              child: ListTile(
                leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                title: const Text(
                  'Очистить старые логи',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text(
                  'Удалить логи старше 7 дней',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () => _cleanLogs(),
              ),
            ),
            const SizedBox(height: 4),
          ],

          const SizedBox(height: 24),

          const Text(
            'О приложении',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF6C63FF)),
              title: const Text('Версия 1.0.0', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                kIsWeb ? 'Web версия' : 'Mobile версия',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF888888)),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 4),
          Material(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF6C63FF)),
              title: const Text('Политика конфиденциальности', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF888888)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Политика конфиденциальности в разработке'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: const Icon(Icons.logout_outlined, color: Colors.red),
              title: const Text(
                'Выйти',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: () => _showLogoutDialog(context, authNotifier),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUserCard(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF6C63FF),
            child: Text(
              authState.user?.name.isNotEmpty == true
                  ? authState.user!.name[0].toUpperCase()
                  : 'К',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.user?.name ?? 'Курьер',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  authState.user?.email ?? 'email@example.com',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLogging(GpsService gpsService) async {
    setState(() {
      _isLoggingEnabled = !_isLoggingEnabled;
    });

    if (_isLoggingEnabled) {
      await gpsService.startLogging();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📁 GPS логирование включено'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      await gpsService.stopLogging();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📁 GPS логирование остановлено'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showGpsLogFile(GpsService gpsService) async {
    try {
      final content = await gpsService.readLogFile();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'GPS Логи',
            style: TextStyle(color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Text(
                content.isNotEmpty ? content : 'Лог-файл пуст',
                style: const TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Закрыть',
                style: TextStyle(color: Color(0xFF6C63FF)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка чтения GPS логов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAppLogs() async {
    try {
      final logger = ref.read(loggerServiceProvider);
      final path = await logger.getLogFilePath();
      final content = await logger.readLogs();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  kIsWeb ? 'Логи (память)' : 'Логи приложения',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (path != null) ...[
                  Text(
                    '📁 $path',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content.isNotEmpty ? content : 'Логи пусты',
                      style: const TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📋 Логи скопированы в буфер обмена'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'Копировать',
                style: TextStyle(color: Color(0xFF6C63FF)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Закрыть',
                style: TextStyle(color: Color(0xFF6C63FF)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка чтения логов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareLogs(GpsService gpsService) async {
    try {
      final logger = ref.read(loggerServiceProvider);
      final content = await logger.readLogs();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Логи для отправки',
            style: TextStyle(color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📋 Логи скопированы в буфер обмена'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text(
                'Копировать',
                style: TextStyle(color: Color(0xFF6C63FF)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Закрыть',
                style: TextStyle(color: Color(0xFF6C63FF)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cleanLogs() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Очистка логов',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Удалить все логи, кроме последних 10 файлов?',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final logger = ref.read(loggerServiceProvider);
                await logger.cleanOldLogs(keepCount: 10);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🧹 Старые логи очищены'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка очистки: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthNotifier authNotifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Выход из аккаунта',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Вы уверены, что хотите выйти из аккаунта?',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authNotifier.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}