// lib/services/sensor_controls.dart
import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

import 'playback_controller.dart';

class SensorControls {
  final PlaybackController playbackController;
  StreamSubscription? _gyroscopeSubscription;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _proximitySubscription;

  // Thresholds for gesture detection
  static const double _flipThreshold = 8.0; // rad/s
  static const double _shakeThreshold = 20.0; // m/s^2

  // Debounce to prevent multiple triggers
  DateTime _lastTriggerTime = DateTime.now();
  static const int _debounceMs = 1000;

  // State tracking
  bool _isFlipped = false;

  SensorControls({required this.playbackController});

  void initialize() {
    // Listen to gyroscope for flip detection
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      // Check for flip gesture (rotation around X axis)
      if (event.x.abs() > _flipThreshold) {
        _handleFlipGesture(event.x > 0);
      }
    });

    // Listen to accelerometer for shake detection
    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      // Simple shake detection
      if (_isShakeGesture(event)) {
        _handleShakeGesture();
      }
    });

    // For proximity sensor, check if the device has this capability
    // This is a simplified approach and may need device-specific handling
    /*
    if (hasProximitySensor) {
      _proximitySubscription = proximityEvents.listen((ProximityEvent event) {
        final bool isNear = event.distance < 5; // typically in cm
        if (isNear != _isNearby) {
          _isNearby = isNear;
          if (_isNearby) {
            _handleProximityGesture();
          }
        }
      });
    }
    */
  }

  // Detect shake gesture using accelerometer
  bool _isShakeGesture(AccelerometerEvent event) {
    final double acceleration =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z) - 9.8;

    if (acceleration.abs() > _shakeThreshold) {
      if (_canTriggerGesture()) {
        return true;
      }
    }
    return false;
  }

  // Handle flip gesture
  void _handleFlipGesture(bool isFlippingUp) {
    // Debounce to prevent multiple triggers
    if (!_canTriggerGesture()) return;

    if (isFlippingUp && !_isFlipped) {
      _isFlipped = true;
      playbackController.pause();
    } else if (!isFlippingUp && _isFlipped) {
      _isFlipped = false;
      playbackController.play();
    }
  }

  // Handle shake gesture
  void _handleShakeGesture() {
    // Skip to next track on shake
    playbackController.playNext();
  }

  // Handle proximity gesture (hand over phone)
  void _handleProximityGesture() {
    // Only trigger if we can
    if (!_canTriggerGesture()) return;

    // Toggle playback state
    if (playbackController.isPlaying) {
      playbackController.pause();
    } else {
      playbackController.play();
    }
  }

  // Check if we can trigger a gesture (debounce)
  bool _canTriggerGesture() {
    final now = DateTime.now();
    if (now.difference(_lastTriggerTime).inMilliseconds > _debounceMs) {
      _lastTriggerTime = now;
      return true;
    }
    return false;
  }

  // Stop listening to sensors
  void dispose() {
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _proximitySubscription?.cancel();
  }
}
