import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'camera_page.dart';
import 'prop.dart';
import 'saf_filer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 画面の向きを横向きに固定する
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  Prop.init();
  await CameraView.init();
  SafFiler.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:
        CameraView(),
    );
  }
}
/*
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[ 
             ListTile( leading: const Icon(Icons.camera_outlined, size: 40,),
                      title: const Text('Camera', style: TextStyle(fontSize: 20),),
                      onTap: () async{
                        await Navigator.push( context,
                          MaterialPageRoute( builder: (context) => CameraView( )));
                      }),
          ],
        ),
      ),
    );
  }
}
*/