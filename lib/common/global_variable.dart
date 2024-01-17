//接收文件 & 拒收文件
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ServerIfReceiveFile { accept, reject }

//服务端状态
enum ServerStatus {
  idle, //空闲
  decision, //收到客户端发送文件请求处于决策阶段
  waiting, //同意接收 等待客户端发送文件
  receiving //文件传输中
}

enum ClientStatus {
  idel, //空闲
  waiting, //等待服务端决策
  sending //文件发送中
}

class HttpResponseCode {
  static const rejectFile = 0;
  static const acceptFile = 1;
  static const serverBusy = 2;
}

//项目官网
String website = "https://sc.digitalevers.com";
//本地设备和网络信息
Map deviceInfo = {
  'model': '',
  'lanIP': '',
  'networkText': '',
  'deviceType': ''
};

//日志开关
bool LogFlag = true;
//服务器返回标识
Map<int, String> HttpResponseCodeMsg = {0: '已拒收', 1: '接收文件', 2: '服务器繁忙'};
//远程设备数据
Map<String, Map<String, dynamic>> remoteDevicesData = {};
//发送文件的客户端
final HttpClient client = HttpClient();
//待发送的文件列表
List<Map<String, String>> fileList = []; //_fileList 前面加_会让变量私有 从而无法全局引用
//全局key - nav(MaterialApp)
final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
//全局key - stack 远程设备item容器
final GlobalKey remoteDevicesKey = GlobalKey();
final GlobalKey MyHomePageKey = GlobalKey();
final GlobalKey TabsKey = GlobalKey();

Offset remoteDevicesOffset = Offset(0, 0);
//缓存实例
SharedPreferences? prefs;

class GlobalVariable {
  //static const bool _logDebug = false;
  //static get logDebug => _logDebug;
}
