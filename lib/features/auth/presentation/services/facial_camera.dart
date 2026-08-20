import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

typedef CapturedFaceDelete = Future<void> Function();

class CapturedFace {
  const CapturedFace({required this.path, required CapturedFaceDelete delete})
    : _delete = delete;

  final String path;
  final CapturedFaceDelete _delete;

  Future<void> delete() => _delete();
}

abstract interface class FacialCamera {
  Future<void> initialize();

  Widget buildPreview();

  Future<CapturedFace> capture();

  Future<void> dispose();
}

class PluginFacialCamera implements FacialCamera {
  CameraController? _controller;

  @override
  Future<void> initialize() async {
    await dispose();
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No camera is available');
    }
    final camera = cameras.firstWhere(
      (candidate) => candidate.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    await controller.initialize();
  }

  @override
  Widget buildPreview() {
    final controller = _readyController();
    return CameraPreview(controller);
  }

  @override
  Future<CapturedFace> capture() async {
    final image = await _readyController().takePicture();
    return CapturedFace(
      path: image.path,
      delete: () async {
        final file = File(image.path);
        if (await file.exists()) {
          await file.delete();
        }
      },
    );
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  CameraController _readyController() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Camera is not initialized');
    }
    return controller;
  }
}
