import 'package:flutter/material.dart';

class InteractiveImageViewer extends StatefulWidget {
  final Image? img;
  final GlobalKey<InteractiveImageViewerState> key;

  InteractiveImageViewer({this.img, required this.key}) : super(key: key);

  @override
  InteractiveImageViewerState createState() => InteractiveImageViewerState();
}

class InteractiveImageViewerState extends State<InteractiveImageViewer> {
  TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void setTransformation(Matrix4 newTransformation) {
    _transformationController.value = newTransformation;
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.1,
      maxScale: 64,
      child: Container(
        child: Center(
          child: widget.img ?? const Text("no file."),
        ),
      ),
    );
  }
}
