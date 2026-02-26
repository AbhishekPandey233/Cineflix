import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

class ShakeSensorService {
  ShakeSensorService({
    this.threshold = 18.0,
    this.debounce = const Duration(milliseconds: 900),
  });

  final double threshold;
  final Duration debounce;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);

  void start(void Function() onShakeDetected) {
    stop();

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final now = DateTime.now();
      if (now.difference(_lastShakeAt) < debounce) {
        return;
      }

      final magnitude =
          math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude < threshold) {
        return;
      }

      _lastShakeAt = now;
      onShakeDetected();
    });
  }

  void stop() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }
}