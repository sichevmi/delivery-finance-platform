import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
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

        if (distance < 2.0) {
          print('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m), ignoring');
          return;
        }

        if (distance > 200) {
          print('⚠️ GPS: extreme jump (${distance.toStringAsFixed(2)}m > 200m), ignoring');
          return;
        }

        print('📏 GPS: distance: ${distance.toStringAsFixed(2)}m, total: ${_totalDistance.toStringAsFixed(4)}km');
        _totalDistance += distance / 1000;
        _distanceStreamController.add(_totalDistance);
      } else {
        print('🟢 GPS: first position, initializing');
      }
      _lastPosition = position;
    }, onError: (error) {
      print('🔴 GPS error: $error');
    });
  }

  void pauseTracking() {
    print('⏸️ GPS: pauseTracking()');
    _isPaused = true;
  }

  void resumeTracking() {
    print('▶️ GPS: resumeTracking()');
    _isPaused = false;
  }

  void stopTracking() {
    print('🛑 GPS: stopTracking()');
    _isTracking = false;
    _isPaused = false;
    _positionStream?.cancel();
    _positionStream = null;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }

  void forceRefresh() async {
    print('🔄 GPS: forceRefresh() called');
    if (!_isTracking || _isPaused) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance > 2.0 && distance < 200) {
          _totalDistance += distance / 1000;
          _distanceStreamController.add(_totalDistance);
        }
      }
      _lastPosition = position;
    } catch (e) {
      print('⚠️ GPS: forceRefresh error - $e');
    }
  }

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    print('🔄 GPS: resetDistance()');
    _totalDistance = 0.0;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }
}