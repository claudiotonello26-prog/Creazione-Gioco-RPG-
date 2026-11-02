import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

enum StepAccess {
  /// Né Android né iOS (test, desktop).
  unsupported,

  /// Android senza Health Connect installato o da aggiornare.
  needsHealthConnect,

  /// Health Connect / Salute c'è, ma manca il permesso di leggere i passi.
  needsPermission,
  ready,
}

/// Passi del giorno da Health Connect (Android) o Salute (iOS). Samsung
/// Health, Google Fit e gli smartwatch scrivono lì: basta un'unica fonte.
class StepSource {
  final Health _health = Health();
  bool _configured = false;

  static const _types = [HealthDataType.STEPS];

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<StepAccess> access() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return StepAccess.unsupported;
    try {
      await _configure();
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) return StepAccess.needsHealthConnect;
      }
      // Su iOS la lettura non dice mai se è concessa: si prova e basta.
      if (Platform.isIOS) return StepAccess.ready;
      final ok = await _health.hasPermissions(_types) ?? false;
      return ok ? StepAccess.ready : StepAccess.needsPermission;
    } catch (e) {
      debugPrint('Health non disponibile: $e');
      return StepAccess.needsHealthConnect;
    }
  }

  Future<bool> requestPermission() async {
    try {
      await _configure();
      return await _health.requestAuthorization(_types,
          permissions: const [HealthDataAccess.READ]);
    } catch (e) {
      debugPrint('Permesso passi non concesso: $e');
      return false;
    }
  }

  Future<void> installHealthConnect() async {
    try {
      await _configure();
      await _health.installHealthConnect();
    } catch (e) {
      debugPrint('Impossibile aprire lo store: $e');
    }
  }

  /// Passi da mezzanotte a ora, o null se non leggibili.
  Future<int?> stepsToday() async {
    try {
      await _configure();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      return await _health.getTotalStepsInInterval(midnight, now);
    } catch (e) {
      debugPrint('Lettura passi fallita: $e');
      return null;
    }
  }
}
