import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../domain/exercise.dart';
import '../widgets/exercise_demo.dart';
import '../widgets/oath_bar.dart';

/// Esercizi che si fanno a terra con il telefono appoggiato di lato: tra uno
/// in piedi e uno a terra va spostato il telefono.
bool onFloor(ExerciseId id) => switch (id) {
      ExerciseId.pushUp || ExerciseId.crunch || ExerciseId.legRaise || ExerciseId.plank => true,
      _ => false,
    };

/// Riordina un circuito per posizione del telefono (prima in piedi, poi a
/// terra) così lo si sposta una volta sola.
List<T> byPhonePosition<T>(List<T> items, ExerciseId Function(T) id) => [
      ...items.where((m) => !onFloor(id(m))),
      ...items.where((m) => onFloor(id(m))),
    ];

/// Pausa fra due esercizi di un circuito: si riparte da soli. Mostra il
/// prossimo esercizio in grande; se il telefono va spostato la pausa è più
/// lunga e lo dice. true = avanti, false = fermati qui.
class RestScreen extends StatefulWidget {
  const RestScreen({
    super.key,
    required this.name,
    required this.exercise,
    required this.index,
    required this.total,
    this.movePhone = false,
  });

  final String name;
  final ExerciseId exercise;
  final int index;
  final int total;
  final bool movePhone;

  static const int rest = 10;
  static const int restMovePhone = 25;

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  late int _left = widget.movePhone ? RestScreen.restMovePhone : RestScreen.rest;
  bool _paused = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      setState(() => _left--);
      if (_left == 3) HapticFeedback.mediumImpact();
      if (_left <= 0) _go(true);
    });
  }

  void _go(bool next) {
    _timer?.cancel();
    if (next) SystemSound.play(SystemSoundType.alert);
    if (mounted) Navigator.of(context).pop(next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OathBar(title: Text('RECUPERO')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('PROSSIMO · ${widget.index}/${widget.total}',
                style: titleStyle(size: 14, color: Palette.ash)),
            const SizedBox(height: 6),
            Text(widget.name.toUpperCase(),
                textAlign: TextAlign.center, style: titleStyle(size: 28, spacing: 2)),
            const SizedBox(height: 16),
            Expanded(
              child: FittedBox(
                child: ExerciseDemo(move: demoFor(widget.name, widget.exercise), size: 200),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.movePhone)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.screen_rotation, color: Palette.ember, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          onFloor(widget.exercise)
                              ? 'Sposta il telefono: a terra, di lato, a 2 metri.'
                              : 'Sposta il telefono: in piedi davanti a te, a 2–3 metri.',
                          style: const TextStyle(fontSize: 16, color: Palette.holy),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text('$_left',
                style: titleStyle(size: 72, color: _paused ? Palette.ash : Palette.goldBright)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _paused = !_paused),
                    child: Text(_paused ? 'RIPRENDI' : 'PAUSA'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(onPressed: () => _go(true), child: const Text('VIA')),
                ),
              ],
            ),
            TextButton(onPressed: () => _go(false), child: const Text('Mi fermo qui')),
          ],
        ),
      ),
    );
  }
}
