import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/auth/providers/auth_provider.dart';
import 'package:delivery_app/features/auth/ui/screens/login_screen.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';

class MoreTab extends ConsumerStatefulWidget {
  const MoreTab({super.key});

  @override
  ConsumerState<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends ConsumerState<MoreTab> {
  bool _isLoggingEnabled = false;
  String? _logContent;

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
          // Карточка пользователя
          _buildUserCard(authState),
          const SizedBox(height: 24),

          // Раздел "Настройки"
          const Text(
            'Настройки',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Убираем Container с фоном, используем только Material
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

          // Раздел "Логирование GPS"
          const Text(
            'GPS Логирование',
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
              leading: const Icon(Icons.folder_open_outlined, color: Color(0xFF6C63FF)),
              title: const Text('Просмотр логов', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Открыть файл с логами GPS', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF888888)),
              onTap: () => _showLogFile(gpsService),
            ),
          ),
          const SizedBox(height: 4),
          Material(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              leading: const Icon(Icons.share_outlined, color: Color(0xFF6C63FF)),
              title: const Text('Отправить логи', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Отправить файл с логами', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF888888)),
              onTap: () => _shareLogFile(gpsService),
            ),
          ),
          const SizedBox(height: 24),

          // Раздел "О приложении"
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

          // Кнопка выхода (с Material)
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

  void _showLogFile(GpsService gpsService) async {
    try {
      final logPath = await gpsService.getLogFilePath();
      if (logPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Лог-файл не найден'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

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
          content: Text('Ошибка чтения логов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareLogFile(GpsService gpsService) async {
    try {
      final logPath = await gpsService.getLogFilePath();
      if (logPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Лог-файл не найден'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Функция отправки логов в разработке'),
          backgroundColor: Colors.orange,
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