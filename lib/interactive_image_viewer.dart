import 'package:flutter/material.dart';

class InteractiveImageViewer extends StatefulWidget {
  final Image? img;
  TransformationController _transformationController = TransformationController();

  InteractiveImageViewer({this.img});

  void setTransformation(Matrix4 newTransformation) {
      _transformationController.value = newTransformation;
  }

  @override
  _InteractiveImageViewerState createState() => _InteractiveImageViewerState();
}

class _InteractiveImageViewerState extends State<InteractiveImageViewer> {

  @override
  void dispose() {
    widget._transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: widget._transformationController,
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
