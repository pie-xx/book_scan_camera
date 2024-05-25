import 'dart:io';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import 'prop.dart';

class SafFiler {
  static const platform = MethodChannel("jp.picpie.book_scan_camera/saf");

  static String dirlist = "";
  static String? diruri = "";

  static late Function? dirListCallback;
  static late Function? copyCallback;
  static late Function? onVUPcallback;
  static late Function? onVDOWNcallback;

  static bool copyOK = true;
  static bool isPrivate = false;

  static bool keyEnable = true;

//  static Map<String,String> uriCacheMap = {};

  static void init() async {
    platform.setMethodCallHandler(_platformCallHandler);
  }

  static Future<void> _platformCallHandler(MethodCall call) async {

    switch (call.method) {
      case 'dirlistOK':
        dirlist = call.arguments.toString();
        if(dirListCallback!=null){
          dirListCallback!( dirlist );
        }
        return;
      case 'copyOK':
        copyOK = true;
        if(copyCallback!=null){
          copyCallback!();
        }
        break;
      case 'onVUP':
        if(keyEnable && onVUPcallback!=null){
          onVUPcallback!();
        }
        break;
      case 'onVDOWN':
        if(keyEnable && onVDOWNcallback!=null){
          onVDOWNcallback!();
        }
        break;
      default:
        debugPrint('Unknowm method ${call.method} ${call.arguments}');
        throw MissingPluginException();
    }
  }

  static void setKeyCallback(Function? vupfunc, Function? vdownfunc){
    onVUPcallback = vupfunc;
    onVDOWNcallback = vdownfunc;
    keyEnable = true; 
  }

  static void setKeyEnable(bool enable){
    keyEnable = enable;
  }

  static Future<String?> getDirectoryList(Function dircallback) async {
    if(Platform.isAndroid){
      return selectDirectoryA(dircallback);
    }
    return selectDirectoryW(dircallback);
  }

  static bool isSAF(){
    if( diruri!.contains("content://")){
      return true;
    }
    return false;
  }

  static Future<void> selectDirectory(Function dircallback) async {
    diruri = await platform.invokeMethod('selectDirectory');  
    if(diruri!=null){
      dircallback();
    }
  }

  static Future<String?> selectDirectoryA(Function dircallback) async {
    try {
      diruri = await platform.invokeMethod('selectDirectory');
      debugPrint("selectDirectory is $diruri");
      if(diruri!=null){
        dirListCallback = dircallback;
        makeDirectoryList(diruri);
      }
      return diruri;
    } on PlatformException catch (e) {
      debugPrint("Failed to create file: '${e.message}'.");
    }
    return "";
  }

  static Future<String?> selectDirectoryW(Function dircallback) async {
    diruri = await FilePicker.platform.getDirectoryPath();
    if (diruri != null) {
      final dir = Directory(diruri!);
      List<FileSystemEntity> dlist = dir.listSync();

      String flist="";
      for( var fe in dlist){
        FileStat fstat = await fe.stat();
        Map<String, dynamic> data = {
          'name': path.basename(fe.path),
          'size': fstat.size,
          'lastModified': fstat.modified.millisecond,
          'type': filename2mimetype(fe.path),
        };

        String jsonString = jsonEncode(data);
        flist = "$flist$jsonString\n";
      }
      dircallback(flist);
      return diruri;
    }
    return null;
  }

  static String filename2mimetype(String fname){
    String ext = path.extension(fname).toLowerCase();

    if( ext==".txt" ){
      return "text/plain";
    }
    if( ext==".json" ){
      return "application/json";
    }
    if( ext==".jpg" || ext==".jpeg" ){
      return "image/jpeg";
    }
    if( ext==".png" ){
      return "image/png";
    }
    if( ext==".bmp" ){
      return "image/bmp";
    }
    if( ext==".md" ){
      return "text/markdown";
    }
    if( ext==".html" || ext==".htm" ){
      return "text/html";
    }
    if( ext==".webp" ){
      return "image/webp";
    }
    if( ext==".pdf" ){
      return "application/pdf";
    }
    if( ext==".csv" ){
      return "text/comma-separated-values";
    }

    return "application/octet-stream";
  }

  static Future<String> makeDirectoryList(String? uri) async {
      final String? directoryList = await platform.invokeMethod('makeDirectoryList',{'uri':uri});
      return directoryList ?? "";
  }

  static Future<String> getFileTextUri(String uri)async{
    if(isSAF()){
      return getFileTextUriA(uri);
    }
    return getFileTextW(uri);
  }

  static Future<String> getFileTextUriA(String uri)async{
    final String filetext = await platform.invokeMethod('getFileTextUri',{'uri':uri});
    return filetext;
  }

  static Future<String> getFileText(String filename)async{
    if(isSAF()){
      return getFileTextA(filename);
    }
    return getFileTextW(filename);
  }

  static Future<String> getFileTextA(String filename)async{
    final String filetext = await platform.invokeMethod('getFileText',{'uri':diruri, 'filename':filename});
    return filetext;
  }

  static Future<String> getFileTextW(String filename)async{
    final String filetext = await platform.invokeMethod('getFileText',{'uri':diruri, 'filename':filename});
    return filetext;
  }
/*
  static void putFileText(String filename, String text) {
    if(isSAF()){
      putFileTextA(filename, text);
      return;
    }
    putFileTextW(filename, text);
  }

  static void putFileTextA(String filename, String text) {
    //platform.invokeMethod('putFileText',{'uri':diruri, 'filename':filename, 'outtext':text});    
    final ReceivePort receivePort = ReceivePort();
    Isolate.spawn( isoPutFile, TransCmd( receivePort.sendPort, diruri, filename, text) );
        // 通信側からのコールバック
    receivePort.listen(( message ) {
      if( message=="start"){
        try{
          platform.invokeMethod('putFileTextUri',{'diruri':diruri, 'uri':uriCacheMap[filename], 'filename':filename, 'outtext':text});
        }catch(e){
          debugPrint(e.toString());
        }
        receivePort.close();
      }
    });
    
  }
*/
  static Future<String> putFileTextUri(String? uri, String filename, String text) async {
    String wuri = await platform.invokeMethod('putFileTextUri',{'diruri':diruri, 'uri':uri, 'filename':filename, 'outtext':text});
    debugPrint( "putFileTextUri wuri = $wuri" );  
    return wuri;
/*
    final ReceivePort receivePort = ReceivePort();
    Isolate.spawn( isoPutFile, TransCmd( receivePort.sendPort, diruri, filename, text) );
        // 通信側からのコールバック
    receivePort.listen(( message ) async {
      if( message=="start"){
        try{
          String wuri = await platform.invokeMethod('putFileTextUri',{'diruri':diruri, 'uri':uri, 'filename':filename, 'outtext':text});
          debugPrint( "putFileTextUri wuri = $wuri" );
        }catch(e){
          debugPrint(e.toString());
        }
        receivePort.close();
      }
    });
  */  
  }

  static void putFileTextW(String filename, String text) {
    final ReceivePort receivePort = ReceivePort();
    Isolate.spawn( isoPutFileW, TransCmd( receivePort.sendPort, diruri, filename, text) );
  }

  static void isoPutFile( TransCmd cmd ) async {
    cmd.sendport?.send("start");
  }

  static void isoPutFileW( TransCmd cmd ) async {
    File wfile = File("${cmd.uri}/${cmd.filename}");
    wfile.writeAsStringSync(cmd.outtext ?? "");
  }

  static String copyToPrivate(String filename, String targetfilename, Function? copycallback){
    copyCallback = copycallback;
    if(isSAF()){
      copyToPrivateA(filename, targetfilename);
    }else{
      copyToPrivateW("$diruri/$filename", "${Prop.getTempPath()}/$targetfilename", copycallback);
    }
    return targetfilename;
  }

  static void copyToPrivateA(String filename, String targetpath) async {
      copyOK = false;
      platform.invokeMethod('copyToPrivate',{'uri':diruri, 'filename':filename, 'targetpath':targetpath});
  }

  static void copyToPrivateW(String sourcePath, String destinationPath, Function? copycallback) {
    File sourceFile = File(sourcePath);
    File destinationFile = File(destinationPath);
    if(destinationFile.existsSync()){
      destinationFile.deleteSync();
    }

    try {
      // コピー処理
      sourceFile.copySync(destinationPath);
      debugPrint('ファイルがコピーされました: $destinationPath');
    } catch (e) {
      debugPrint('ファイルのコピー中にエラーが発生しました: $e');
    }

    copycallback!();
  }
  
  static void copyToPublicA(String mimetype, String filename, String srcpath) async {
      copyOK = false;
      platform.invokeMethod('copyToPublic',{'diruri':diruri,'mimetype':mimetype, 'filename':filename, 'srcpath':srcpath, });
  }

}

class TransCmd {
  SendPort? sendport;
  String? uri;
  String? filename;
  String? outtext;
  
  TransCmd(this.sendport, this.uri, this.filename, this.outtext);
}
