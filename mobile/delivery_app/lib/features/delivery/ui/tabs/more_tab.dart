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
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Уведомления',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Настройки уведомлений в разработке'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.language_outlined,
            title: 'Язык',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Смена языка в разработке'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
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
          _buildMenuItem(
            icon: _isLoggingEnabled ? Icons.pause_circle_outline : Icons.play_circle_outline,
            title: _isLoggingEnabled ? 'Остановить запись GPS' : 'Начать запись GPS',
            subtitle: _isLoggingEnabled ? 'Логирование активно' : 'Логирование выключено',
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
                : null,
            onTap: () => _toggleLogging(gpsService),
          ),
          _buildMenuItem(
            icon: Icons.folder_open_outlined,
            title: 'Просмотр логов',
            subtitle: 'Открыть файл с логами GPS',
            onTap: () => _showLogFile(gpsService),
          ),
          _buildMenuItem(
            icon: Icons.share_outlined,
            title: 'Отправить логи',
            subtitle: 'Отправить файл с логами',
            onTap: () => _shareLogFile(gpsService),
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
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'Версия 1.0.0',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Политика конфиденциальности',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Политика конфиденциальности в разработке'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Кнопка выхода
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.logout_outlined,
                color: Colors.red,
              ),
              title: const Text(
                'Выйти',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.red,
              ),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF6C63FF),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              )
            : null,
        trailing: trailing ?? const Icon(
          Icons.chevron_right,
          color: Color(0xFF888888),
        ),
        onTap: onTap,
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

      // TODO: реализовать отправку логов (через share_plus или email)
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