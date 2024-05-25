import 'dart:ffi';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//import 'package:text_zoom_wrap/fileimage_page.dart';
import 'prop.dart';
import 'saf_filer.dart';
import 'interactive_image_viewer.dart';

List<CameraDescription>? _cameras;

/// CameraApp is the Main Application.
class CameraView extends StatefulWidget {
  /// Default Constructor
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraAppState();

  static void init() async {
    _cameras = await availableCameras();
  }
  static bool isEnable(){
    if(_cameras==null){
      return false;
    }
    return _cameras?.isNotEmpty ?? false;
  }
}

class _CameraAppState extends State<CameraView> {
  late CameraController controller;
  late InteractiveImageViewer ivmain;
  final _transformationController = TransformationController();
  //Image? img;
  static const platform = MethodChannel("jp.picpie.book_scan_camera/saf");

  static bool inCapture = false;
  String? selectedDirectory;

  late DateTime laspcaptime; 

  late final GlobalKey<InteractiveImageViewerState> viewerKey;

  @override
  void initState() {
    super.initState();

    laspcaptime = DateTime.now();

    viewerKey = GlobalKey();
    ivmain = InteractiveImageViewer(key:viewerKey);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    controller = CameraController(_cameras![0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });

    SafFiler.setKeyCallback(takePicture, takePicture);
  }

  void selectDirectory() async {
    selectedDirectory = await SafFiler.getDirectoryList(
      (String dlist) async {
        print(dlist);
      });
  }

  void dispatchKeycode(){
    Timer(Duration(milliseconds: 300), () async {
      var key = await platform.invokeMethod('getKeyCode',{ });
      if( key=="24"){
        takePicture();
      }
      dispatchKeycode();
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    selectDirectory();
    //dispatchKeycode();
  }

  @override
  void dispose() {
    controller.dispose();
    SafFiler.setKeyEnable(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void takePicture() async {
    if (inCapture) {
      return;
    }
    final startTime = DateTime.now();
    debugPrint('Picture capture started at: $startTime');

    final difftime = startTime.difference(laspcaptime).inMilliseconds;
    laspcaptime = startTime;
    if(difftime < 500){
      debugPrint('Picture capture ignore $startTime $laspcaptime');
      return;
    }

    inCapture = true;

    final takePictureStart = DateTime.now();
    XFile picfile = await controller.takePicture();
    final takePictureEnd = DateTime.now();
    debugPrint('takePicture duration: ${takePictureEnd.difference(takePictureStart).inMilliseconds} milliseconds');

    final saveStart = DateTime.now();
    String capPath = "${Prop.getTempPath()}/cap.jpg";
    await picfile.saveTo(capPath);
    final saveEnd = DateTime.now();
    debugPrint('saveTo duration: ${saveEnd.difference(saveStart).inMilliseconds} milliseconds');

    final copyStart = DateTime.now();
    final savefilename = generateFileName();
    SafFiler.copyToPublicA("image/png", savefilename, capPath);
    debugPrint('takePicture savefilename: $savefilename');
    final copyEnd = DateTime.now();
    debugPrint('copyToPublicA duration: ${copyEnd.difference(copyStart).inMilliseconds} milliseconds');

    final loadImageStart = DateTime.now();
    //ivmain.loadimageFileSS(capPath);
      Uint8List  imageData = File(capPath).readAsBytesSync();
      Image img = Image.memory(imageData);
      ivmain = InteractiveImageViewer(img: img, key: viewerKey);

    final loadImageEnd = DateTime.now();
    debugPrint('loadimageFileSS duration: ${loadImageEnd.difference(loadImageStart).inMilliseconds} milliseconds');

    inCapture = false;

    final endTime = DateTime.now();
    debugPrint('Picture capture ended at: $endTime');
    final duration = endTime.difference(startTime);
    debugPrint('Picture capture duration: ${duration.inMilliseconds} milliseconds');

    setState(() {
      
    });
  }

  String generateFileName() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final millisecond = now.millisecond.toString().padLeft(3, '0');

    return 'pic${year}${month}${day}_${hour}${minute}${second}_${millisecond}.png';
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }



    double previewWidth = MediaQuery.of(context).size.width / 4;

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(controller),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: CrosshairPainter(),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('close'),
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: 40,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              Text('shutter'),
              IconButton(
                icon: const Icon(Icons.camera),
                iconSize: 40,
                onPressed: () {
                  takePicture();
                },
              ),
              SizedBox(
                width: previewWidth,
                child: ivmain,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in_map),
                iconSize: 40,
                onPressed: () {
                  setState(() {
                    viewerKey.currentState?.setTransformation(Matrix4.identity());
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1;

    // 縦の線
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width / 4, 0),
      Offset(size.width / 4, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 3 / 4, 0),
      Offset(size.width * 3 / 4, size.height),
      paint,
    );


    // 横の線
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 8),
      Offset(size.width, size.height / 8),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 7 / 8),
      Offset(size.width, size.height * 7 / 8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}