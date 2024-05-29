import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class InteractiveImageViewer extends StatefulWidget {
  final Image? img;  // finalじゃなくすると再描画されなくなる
  final GlobalKey<InteractiveImageViewerState>? key;

  const InteractiveImageViewer({this.img, this.key}) : super(key: key);

  void setTransformation(Matrix4 newTransformation) {
    key!.currentState?.setTransformation(newTransformation);
  }

  InteractiveImageViewer loadimageFile(String filename, {double? width, double? height})  {
    try{
      Uint8List  imageData = File(filename).readAsBytesSync();
      Image _img = Image.memory(imageData);
      
      return InteractiveImageViewer(img: _img, key: key,);
    }catch(e){
      debugPrint(e.toString());
    }
    return InteractiveImageViewer(img:img, key:key);
  }

  @override
  InteractiveImageViewerState createState() => InteractiveImageViewerState();
}

class InteractiveImageViewerState extends State<InteractiveImageViewer> {
  final TransformationController _transformationController = TransformationController();

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
