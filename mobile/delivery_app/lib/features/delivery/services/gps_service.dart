import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  double _totalDistance = 0.0;
  Position? _lastPosition;
  bool _isPaused = false;

  double get currentDistance => _totalDistance;

  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  Future<bool> requestPermissions() async {
    final status = await Permission.locationAlways.request();
    if (status.isGranted) {
      if (await Geolocator.isLocationServiceEnabled()) {
        return true;
      } else {
        await Geolocator.openLocationSettings();
        return false;
      }
    }
    return false;
  }

  void startTracking() {
  print('🟢 GPS: startTracking() called');
  if (_isTracking) {
    print('🟡 GPS: already tracking, ignoring');
    return;
  }

  _isTracking = true;
  _isPaused = false;
  _totalDistance = 0.0;
  _lastPosition = null;
  print('🟢 GPS: tracking started, waiting for position...');

  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 1, // обновления только при перемещении > 1 метра
  );

  _positionStream = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  ).listen((Position position) {
    print('📍 GPS: position received - lat: ${position.latitude}, lon: ${position.longitude}');
    if (_isPaused) {
      print('⏸️ GPS: paused, ignoring position');
      return;
    }

    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      // Игнорируем слишком маленькие перемещения (шум)
      if (distance < 0.5) {
        print('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m), ignoring');
        return;
      }
      
      // Игнорируем слишком большие скачки (выбросы)
      if (distance > 20) { // максимум 20 метров за одно обновление (пешком ~20 км/ч)
        print('⚠️ GPS: suspicious jump (${distance.toStringAsFixed(2)}m), ignoring');
        return;
      }

      print('📏 GPS: distance since last update: ${distance.toStringAsFixed(2)} meters');
      _totalDistance += distance / 1000;
      print('📏 GPS: total distance: ${_totalDistance.toStringAsFixed(4)} km');
    } else {
      print('🟢 GPS: first position, initializing');
    }
    _lastPosition = position;
    _distanceStreamController.add(_totalDistance);
  });
}

  void pauseTracking() {
    _isPaused = true;
  }

  void resumeTracking() {
    _isPaused = false;
    _getCurrentPosition();
  }

  void stopTracking() {
    _isTracking = false;
    _isPaused = false;
    _positionStream?.cancel();
    _positionStream = null;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    _totalDistance = 0.0;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }

  Future<void> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _lastPosition = position;
    } catch (e) {
      // Игнорируем
    }
  }
}