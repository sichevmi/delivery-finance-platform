import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  /// Проверка и запрос разрешений с объяснением
  static Future<bool> requestLocationPermission(BuildContext context) async {
    // Проверяем текущий статус
    var status = await Permission.location.status;

    // Если разрешение уже есть — возвращаем true
    if (status.isGranted) {
      return true;
    }

    // Если разрешение отклонено навсегда — открываем настройки
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(context);
      return false;
    }

    // Если разрешение отклонено, но не навсегда — показываем объяснение
    if (status.isDenied) {
      final shouldRequest = await _showExplanationDialog(context);
      if (!shouldRequest) {
        return false;
      }
      status = await Permission.location.request();
    }

    // Повторно проверяем статус после запроса
    if (status.isGranted) {
      // Проверяем, включена ли служба геолокации
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showEnableGpsDialog(context);
        return false;
      }
      return true;
    }

    // Если разрешение всё ещё отклонено — редирект в настройки
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(context);
      return false;
    }

    return false;
  }

  /// Диалог-объяснение перед запросом разрешения
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

  /// Диалог для включения GPS
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

  /// Диалог для перехода в настройки приложения
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