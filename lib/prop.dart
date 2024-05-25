import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Prop {
  static Map<String,String> props={};

  static String? tmpdirpath;

  static void init() async {
    Directory tempDir = await getTemporaryDirectory();
    tmpdirpath = tempDir.path;
  }

  static String getTempPath(){
    return tmpdirpath ?? "";
  }

  static Future <String> getProp(String key, {String defaultStr=""}) async {
    if( props[key] == null){
      SharedPreferences prefs = await SharedPreferences.getInstance();
      props[key] = prefs.getString(key) ?? defaultStr;
    }
    return props[key]??defaultStr;
  }
  static setProp( String key, String value ) async {
    props[key] = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }
  static rmProp(String key)async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
    props.remove(key);
  }

  static Future <String> getLastURL() async { return await getProp("LastURL", defaultStr: "https://dl.ndl.go.jp/"); }
  static setLastURL( String value ) async { await setProp("LastURL", value); }

  static Future <String> getBookmarkStr() async { return await getProp("Bookmark", defaultStr: "{'url':'https://dl.ndl.go.jp/'}"); }
  static setBookmarkStr( String value ) async { await setProp("Bookmark", value); }

  static Future <int> getBookmarkInt() async { 
    String bm = await getProp("BookmarkInt", defaultStr: "0");
    try{
      return int.parse(bm);
    }catch(e){    }
    return 0;
  }
  static setBookmarkInt( int value ) async { await setProp("BookmarkInt", "$value"); }

  static bool isTablet(context) {
    return MediaQuery.of(context).size.width >= 533;
  }


/////////////////////////////////////////////////////////////////////////////////////
  static bool onkurukuru = false;
  static String kmsg = "";

  static void kurukuru(context, {msg=""}){
    kmsg = msg;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 250), // ダイアログフェードインmsec
      barrierColor: Colors.black.withOpacity(0.4), // 画面マスクの透明度
      pageBuilder: (BuildContext context, Animation animation,
          Animation secondaryAnimation) {
        return Center(
            child:Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text( msg,
                  style: const TextStyle(
                            fontSize: 18.0,
                            color: Colors.white,
                            decoration: TextDecoration.none),),
                const CircularProgressIndicator(), 
              ],                      
          )
        );
      });
    onkurukuru = true;
  }

  static void kurukuruOff(context){
    if( onkurukuru ){
      Navigator.pop(context);
    }
    onkurukuru = false;
  }

  static void kurukuruMsg(context, msg){
    if( msg != kmsg ){
      Navigator.pop(context);
      kurukuru(context, msg:msg);
    }
  }


}

class FifoProps {
  static const int _keylimit = 20;
  static const String basekey = "fifoprops";

  static Future<String> get( String keyname) async {
    try {
    String jsonstr = await Prop.getProp(basekey);
    List keyfiles = jsonDecode(jsonstr);
    if( !keyfiles.contains(keyname) ){
      return "";
    }
  
    return await Prop.getProp(keyname);
    }catch(e){
      debugPrint(e.toString());
    }

    return "";
  }

  static Future<void> put( String keyname, String value, {int? keylimit}) async {
    String jsonstr = await Prop.getProp(basekey);
    List keyfiles = [];
    try {
      keyfiles = jsonDecode(jsonstr);
      int p = keyfiles.indexOf(keyname);
      if( p != -1 ){
        await Prop.setProp(keyname, value);
        return;
      }
      if( keyfiles.length >= (keylimit ?? _keylimit) ){
        var rmfilename = keyfiles[0];
        Prop.rmProp(rmfilename);
        keyfiles.removeAt(0);
      }
    }catch(e){
      debugPrint(e.toString());
    }
    await Prop.setProp(keyname, value);
    keyfiles.add(keyname);
    String liststr = jsonEncode(keyfiles);
    await Prop.setProp(basekey, liststr);

  }
}