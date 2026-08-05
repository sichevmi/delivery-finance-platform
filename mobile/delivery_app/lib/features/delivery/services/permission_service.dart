import 'package:flutter/material.dart';
import 'package:delivery_app/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:html' as html;

class PermissionService {
  static Future<bool> requestLocationPermission(BuildContext context) async {
    logMessage('🔵 PermissionService: requestLocationPermission called');

    // ===== ВЕБ-ВЕРСИЯ =====
    if (const bool.fromEnvironment('dart.library.html')) {
      return _requestWebPermission(context);
    }

    // ===== NATIVE (Android/iOS) =====
    return _requestNativePermission(context);
  }

  // ===== ВЕБ =====
  static Future<bool> _requestWebPermission(BuildContext context) async {
    try {
      // Проверяем, доступен ли Permissions API
      final permissions = html.window.navigator.permissions;
      if (permissions != null) {
        try {
          final permission = await permissions.query({'name': 'geolocation'});
          logMessage('🔵 Web permission state: ${permission.state}');

          if (permission.state == 'granted') {
            return true;
          }

          if (permission.state == 'prompt') {
            // Запрашиваем доступ, получая позицию
            try {
              await html.window.navigator.geolocation.getCurrentPosition();
              return true;
            } catch (e) {
              logMessage('❌ Web geolocation error: $e');
              return false;
            }
          }

          if (permission.state == 'denied') {
            await _showWebSettingsDialog(context);
            return false;
          }
        } catch (e) {
          logMessage('❌ Permissions API error: $e');
          // Если ошибка – пробуем напрямую запросить
        }
      }

      // Если Permissions API недоступен или упал – пробуем напрямую
      try {
        await html.window.navigator.geolocation.getCurrentPosition();
        return true;
      } catch (_) {
        return false;
      }
    } catch (e) {
      logMessage('❌ Web permission error: $e');
      return false;
    }
  }

  static Future<void> _showWebSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Доступ к геолокации',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Доступ к геолокации запрещён в браузере.\n'
          'Пожалуйста, разрешите доступ в настройках сайта.\n\n'
          'В Chrome: нажмите на иконку замка🔒 слева от адресной строки → '
          'Разрешения → Местоположение → Разрешить.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Закрыть',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Пытаемся обновить страницу для повторного запроса
              html.window.location.reload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Обновить страницу'),
          ),
        ],
      ),
    );
  }

  // ===== NATIVE =====
  static Future<bool> _requestNativePermission(BuildContext context) async {
    var status = await Permission.location.status;
    logMessage('🔵 PermissionService: current status = $status');

    if (status.isGranted) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showEnableGpsDialog(context);
        return false;
      }
      return true;
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(context);
      return false;
    }

    if (status.isDenied) {
      final shouldRequest = await _showExplanationDialog(context);
      if (!shouldRequest) {
        return false;
      }
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showEnableGpsDialog(context);
        return false;
      }
      return true;
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(context);
      return false;
    }

    return false;
  }

  // ===== ДИАЛОГИ (только для нативных платформ) =====
  static Future<bool> _showExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Доступ к геолокации',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Для отслеживания маршрута доставки приложению '
          'необходим доступ к вашему местоположению.\n\n'
          'Данные используются только во время активной доставки.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Не сейчас',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Разрешить'),
          ),
        ],
      ),
    ) ?? false;
  }

  static Future<void> _showEnableGpsDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Включите GPS',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Для работы приложения необходимо включить '
          'определение местоположения на устройстве.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Включить'),
          ),
        ],
      ),
    );

    if (result == true) {
      await Geolocator.openLocationSettings();
    }
  }

  static Future<void> _showSettingsDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Требуется доступ к геолокации',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Вы запретили доступ к геолокации.\n'
          'Пожалуйста, разрешите доступ в настройках устройства.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );

    if (result == true) {
      await openAppSettings();
    }
  }
}