import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'step_source.dart';

/// I passi di oggi aggiornati mentre cammini. Health Connect / Salute arriva
/// in ritardo, il contapassi del telefono no: si prende il più alto dei due,
/// così gli stessi passi non contano mai due volte.
class LiveSteps {
  LiveSteps(this.onSteps);

  /// Riceve la stima dei passi di oggi ogni volta che sale.
  final void Function(int stepsToday) onSteps;

  final _source = StepSource();
  StreamSubscription<StepCount>? _sensor;
  Timer? _poll;
  int _health = 0;
  int? _sensorBase;
  int _sensorSteps = 0;
  int _last = -1;

  /// Parte: true se almeno una fonte di passi funziona.
  Future<bool> start() async {
    final healthOk = await _source.access() == StepAccess.ready;
    if (healthOk) _health = await _source.stepsToday() ?? 0;
    final base = _health;
    var sensorOk = false;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final granted = await Permission.activityRecognition.request();
        if (granted.isGranted || Platform.isIOS) {
          _sensor = Pedometer.stepCountStream.listen(
            (e) {
              _sensorBase ??= e.steps;
              _sensorSteps = base + e.steps - _sensorBase!;
              _emit();
            },
            onError: (Object e) => debugPrint('Contapassi non disponibile: $e'),
            cancelOnError: true,
          );
          sensorOk = true;
        }
      } catch (e) {
        debugPrint('Contapassi non disponibile: $e');
      }
    }
    if (healthOk) {
      _poll = Timer.periodic(const Duration(seconds: 5), (_) async {
        final s = await _source.stepsToday();
        if (s != null) {
          _health = s;
          _emit();
        }
      });
    }
    _emit();
    return healthOk || sensorOk;
  }

  void _emit() {
    final now = max(_health, _sensorSteps);
    if (now <= _last) return;
    _last = now;
    onSteps(now);
  }

  void stop() {
    _sensor?.cancel();
    _poll?.cancel();
    _sensor = null;
    _poll = null;
  }
}
