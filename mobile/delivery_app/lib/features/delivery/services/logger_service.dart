import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  File? _logFile;
  IOSink? _logSink;
  bool _isEnabled = false;

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final fileName = 'gps_log_${now.year}_${now.month}_${now.day}_${now.hour}_${now.minute}.txt';
    _logFile = File('${directory.path}/$fileName');
    _isEnabled = true;
    _logSink = _logFile!.openWrite(mode: FileMode.append);
    await _write('=== GPS LOG STARTED: ${DateTime.now()} ===');
    await _write('Device: ${Platform.operatingSystem} ${Platform.version}');
    await _write('=== NEW SESSION ===');
  }

  Future<void> _write(String message) async {
    if (!_isEnabled || _logSink == null) return;
    final timestamp = DateTime.now().toIso8601String();
    _logSink!.writeln('[$timestamp] $message');
  }

  Future<void> log(String message) async {
    await _write(message);
    print(message); // дублируем в консоль для отладки
  }

  Future<void> logGps({
    required double lat,
    required double lon,
    required double? accuracy,
    required double? speed,
    required double distance,
    required double totalDistance,
    required bool isPaused,
    required bool isTracking,
  }) async {
    await _write(
      'GPS: lat=$lat, lon=$lon, acc=${accuracy?.toStringAsFixed(2) ?? 'N/A'}m, '
      'speed=${speed?.toStringAsFixed(2) ?? 'N/A'}m/s, '
      'dist=${distance.toStringAsFixed(2)}m, '
      'total=${totalDistance.toStringAsFixed(4)}km, '
      'paused=$isPaused, tracking=$isTracking'
    );
  }

  Future<void> logEvent(String event, {Map<String, dynamic>? data}) async {
    final dataStr = data != null ? ' | data: $data' : '';
    await _write('EVENT: $event$dataStr');
  }

  Future<void> close() async {
    if (_logSink != null) {
      await _write('=== GPS LOG ENDED: ${DateTime.now()} ===');
      await _logSink!.flush();
      await _logSink!.close();
      _logSink = null;
      _isEnabled = false;
    }
  }

  Future<String?> getLogFilePath() async {
    return _logFile?.path;
  }

  Future<String?> readLog() async {
    if (_logFile == null) return null;
    try {
      return await _logFile!.readAsString();
    } catch (e) {
      return 'Error reading log: $e';
    }
  }

  Future<void> shareLog() async {
    // TODO: implement sharing
  }
}