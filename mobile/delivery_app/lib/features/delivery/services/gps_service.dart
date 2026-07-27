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
    if (_isTracking) return;

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_isPaused) return;

      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        _totalDistance += distance / 1000;
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