import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../core/i18n.dart';
import '../domain/combat.dart';
import '../domain/exercise.dart';
import 'pose_frame.dart';
import 'rep_counter.dart';

/// Sorgente di rep per le schermate di allenamento, combattimento e Arena.
abstract class RepInput extends ChangeNotifier {
  RepInput(this.exercise);

  final ExerciseId exercise;
  final _reps = StreamController<RepEvent>.broadcast();

  Stream<RepEvent> get reps => _reps.stream;

  /// Ultimo scheletro rilevato (per il disegno e, in futuro, per il PvP live:
  /// si trasmettono solo questi punti, mai le immagini).
  PoseFrame? get pose;
  FormHint get hint;
  int get count;
  Duration get held;
  bool get isHold => exercise.isHold;
  String? get error;

  Future<void> start();

  @protected
  void emit(RepEvent e) {
    if (!_reps.isClosed) _reps.add(e);
  }

  @override
  void dispose() {
    _reps.close();
    super.dispose();
  }
}

/// Fotocamera frontale + ML Kit Pose Detection, tutto sul telefono.
class CameraRepInput extends RepInput {
  CameraRepInput(super.exercise) : _tracker = ExerciseTracker(exercise);

  final ExerciseTracker _tracker;
  final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );
  CameraController? controller;
  CameraDescription? _camera;
  bool _busy = false;
  PoseFrame? _pose;
  String? _error;
  final _clock = Stopwatch();

  @override
  PoseFrame? get pose => _pose;
  @override
  FormHint get hint => _tracker.hint;
  @override
  int get count => _tracker.count;
  @override
  Duration get held => _tracker.held;
  @override
  String? get error => _error;

  @override
  Future<void> start() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('none', tr('Nessuna fotocamera'));
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final c = CameraController(
        _camera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      controller = c;
      await c.initialize();
      _clock.start();
      await c.startImageStream(_onImage);
      notifyListeners();
    } catch (e) {
      _error = tr('Fotocamera non disponibile: {e}', {'e': e});
      notifyListeners();
    }
  }

  Future<void> _onImage(CameraImage image) async {
    if (_busy) return;
    _busy = true;
    try {
      final input = _toInputImage(image);
      if (input == null) return;
      final poses = await _detector.processImage(input);
      if (poses.isEmpty) {
        _pose = null;
      } else {
        _pose = _toFrame(poses.first, _clock.elapsed,
            image.width > image.height ? image.width.toDouble() : image.height.toDouble());
        final event = _tracker.add(_pose!);
        if (event != null) emit(event);
      }
      notifyListeners();
    } catch (_) {
      // Un frame perso non ferma l'allenamento.
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _camera;
    if (camera == null) return null;
    // L'app è bloccata in verticale: la rotazione dipende solo dal sensore.
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (rotation == null || format == null || image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  static const _map = {
    Joint.nose: PoseLandmarkType.nose,
    Joint.leftShoulder: PoseLandmarkType.leftShoulder,
    Joint.rightShoulder: PoseLandmarkType.rightShoulder,
    Joint.leftElbow: PoseLandmarkType.leftElbow,
    Joint.rightElbow: PoseLandmarkType.rightElbow,
    Joint.leftWrist: PoseLandmarkType.leftWrist,
    Joint.rightWrist: PoseLandmarkType.rightWrist,
    Joint.leftHip: PoseLandmarkType.leftHip,
    Joint.rightHip: PoseLandmarkType.rightHip,
    Joint.leftKnee: PoseLandmarkType.leftKnee,
    Joint.rightKnee: PoseLandmarkType.rightKnee,
    Joint.leftAnkle: PoseLandmarkType.leftAnkle,
    Joint.rightAnkle: PoseLandmarkType.rightAnkle,
  };

  static PoseFrame _toFrame(Pose pose, Duration t, double scale) => PoseFrame({
        for (final e in _map.entries)
          if (pose.landmarks[e.value] != null)
            e.key: JointPoint(
              pose.landmarks[e.value]!.x,
              pose.landmarks[e.value]!.y,
              pose.landmarks[e.value]!.likelihood,
            ),
      }, timestamp: t, scale: scale);

  @override
  void dispose() {
    final c = controller;
    controller = null;
    if (c != null) {
      if (c.value.isStreamingImages) c.stopImageStream().catchError((_) {});
      c.dispose();
    }
    _detector.close();
    super.dispose();
  }
}

/// Inserimento manuale: per emulatori, accessibilità e sviluppo. Le rep
/// manuali non sono verificate e non entrano nelle classifiche.
class ManualRepInput extends RepInput {
  ManualRepInput(super.exercise);

  int _count = 0;
  Duration _held = Duration.zero;
  Timer? _holdTimer;

  @override
  PoseFrame? get pose => null;
  @override
  FormHint get hint => FormHint.none;
  @override
  int get count => _count;
  @override
  Duration get held => _held;
  @override
  String? get error => null;

  bool get holding => _holdTimer != null;

  @override
  Future<void> start() async {}

  void tapRep(RepQuality q) {
    _count++;
    HapticFeedback.lightImpact();
    emit(RepEvent(q));
    notifyListeners();
  }

  void toggleHold() {
    if (_holdTimer != null) {
      _holdTimer!.cancel();
      _holdTimer = null;
    } else {
      _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _held += const Duration(milliseconds: 100);
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }
}
