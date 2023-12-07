// ignore: slash_for_doc_comments
import 'dart:io';
import 'dart:math';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:woniu/controllers/controllers.dart';
import 'commclass.dart';
import 'config.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'global_variable.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';


// ignore: slash_for_doc_comments
/**
 * 打印日志 输出所在文件及所在行
 */
void Log(var msg, StackTrace st) {
  if (debug) {
    CustomPrint customPrint = CustomPrint(st);
    // ignore: avoid_print
    print(
        "打印信息:$msg, 所在文件:${customPrint.fileName},所在行:${customPrint.lineNumber}");
  }
}


// ignore: slash_for_doc_comments
/**
   * 判断两个矩形是否有重叠部分
   * 若有重叠 返回true
   * 不重叠 则返回false
   */
bool rectInRect(Rect rect1, Rect rect2) {
  if ((rect1.top > rect2.top) &&
      (rect1.top < rect2.bottom) &&
      (rect1.left > rect2.left) &&
      (rect1.left < rect2.right)) {
    return true;
  }
  if ((rect1.top > rect2.top) &&
      (rect1.top < rect2.bottom) &&
      (rect1.right > rect2.left) &&
      (rect1.right < rect2.right)) {
    return true;
  }
  if ((rect1.bottom > rect2.top) &&
      (rect1.bottom < rect2.bottom) &&
      (rect1.left > rect2.left) &&
      (rect1.left < rect2.right)) {
    return true;
  }
  if ((rect1.bottom > rect2.top) &&
      (rect1.bottom < rect2.bottom) &&
      (rect1.right > rect2.left) &&
      (rect1.right < rect2.right)) {
    return true;
  }
  return false;
}

// ignore: slash_for_doc_comments
/**
 * 返回min-max之间的整数
 */
int randomInt(int min, int max) {
  final random = Random();
//将 参数min + 取随机数（最大值范围：参数max -  参数min）的结果 赋值给变量 result;
  int result = min + random.nextInt(max - min);
//返回变量 result 的值;
  return result;
}

//将 fileSize=0&fileCount=0 这样的拼接参数解析成 map
Map<String,String> pathinfo(String s){
  Map<String,String> map = {};
  List<String> token = s.split("&");
  for(String k in token){
    List<String> temp = k.split("=");
    map[temp[0]] = temp[1];
  }
  return map;
}

//判断给出的点是否在某个矩阵内
//位于矩阵内返回true 否则返回false
bool pointInsideRect(Offset point,double top,double left,double itemWidth,double itemHeight){
  //print(point); 
  //print(top); 
  //print(left);
  //print(itemWidth); 
  //print(itemHeight);
  if(point.dx > left && point.dx < (left + itemWidth) && point.dy > top && point.dy < (top + itemHeight)){
    return true;
  }
  return false;
}

//发送文件的一些修饰工作
void preSendFile(){

}

//发送文件信息
void sendFileInfo(HttpClient client_, String serverIP_, int serverPort_, List<String?>? fileList_, context_) async {
  int fileSize = 1;   //待发送文件大小 单位M
  int fileCount = 10;  //待发送文件数量
  String url = "http://$serverIP_:$serverPort_/fileinfo";
  String formBody = "fileSize=$fileSize&fileCount=$fileCount";

  HttpClientRequest request = await  client.postUrl(Uri.parse(url));
  request.add(utf8.encode(formBody));
  HttpClientResponse response = await request.close();
  String result = await response.transform(utf8.decoder).join();
  Log(result, StackTrace.current);
  //分析服务端响应 如果同意接收则开始发送文件
  Map resMap = jsonDecode(result);
  if(resMap['code'] == HttpResponseCode.acceptFile){
    preSendFile();
    sendFile(client_, serverIP_, serverPort_, fileList_);
  } else {
    CherryToast.warning(
      title:  Text(HttpResponseCodeMsg[resMap['code']]!),
      toastPosition: Position.bottom,
      displayCloseButton:false,
      actionHandler:(){},
      //animationDuration: const Duration(milliseconds:  500),
    ).show(context_);
  }
  
  //client.close();// 这里若关闭了 就不能再次发送请求了
}


//发送文件
void sendFile(HttpClient client_, String serverIP_, int serverPort_, List<String?>? filelist_) async {
  String filePath = Uri.decodeComponent(filelist_![0]!);
  var file = File(filePath); 
  var uri = Uri(scheme: 'http', host: serverIP_, port: serverPort_, path: '/fileupload');
  HttpClientRequest request = await  client.postUrl(uri);
  //request.headers.set(HttpHeaders.contentTypeHeader, "multipart/form-data");
  //request.headers.set("filename", p.basename(applist[0]!));
  await request.addStream(file.openRead());
  
  HttpClientResponse response = await request.close();
  var result = await response.transform(utf8.decoder).join();

  Log(result, StackTrace.current);
  client.close();
}



getEstimatedTime(receivedBits, totalBits, currentSpeed) {
  ///speed in [mega bits  x * 10^6 bits ]
  double estBits = (totalBits - receivedBits) / 1000000;
  int estTimeInInt = (estBits ~/ currentSpeed);
  int mins = 0;
  int seconds = 0;
  int hours = 0;
  hours = estTimeInInt ~/ 3600;
  mins = (estTimeInInt % 3600) ~/ 60;
  seconds = ((estTimeInInt % 3600) % 60);
  if (hours == 0) {
    if (mins == 0) {
      return 'About $seconds seconds left';
    }
    return 'About $mins m and $seconds s left';
  }
  return 'About $hours h $mins m $seconds s left';
}

storeHistory(Box box, String savePath) {
  if (box.get('fileInfo') == null) {
    box.put('fileInfo', []);
  }
  List fileInfo = box.get('fileInfo') as List;
  fileInfo.insert(
    0,
    {
      'fileName': savePath.split(Platform.pathSeparator).last,
      'date': DateTime.now(),
      'filePath': savePath
    },
  );

  box.put('fileInfo', fileInfo);
}

int getRandomNumber() {
  Random rnd;
  try {
    rnd = Random.secure();
  } catch (_) {
    rnd = Random();
  }
  return rnd.nextInt(10000);
}


processReceiversData(Map<String, dynamic> newReceiverData) {
  var inst = GetIt.I.get<ReceiverDataController>();
  inst.receiverMap.addAll(
    {
      "${newReceiverData["receiverID"]}": {
        "hostName": newReceiverData["hostName"],
        "os": newReceiverData["os"],
        "currentFileName": newReceiverData["currentFileName"],
        "currentFileNumber": newReceiverData["currentFileNumber"],
        "filesCount": newReceiverData['filesCount'],
        "isCompleted": newReceiverData["isCompleted"],
      }
    },
  );
}

Future<void> storeSentFileHistory(List<String?> files) async {
  Box box = await Hive.openBox('appData');
  if (box.get('sentHistory') == null) {
    box.put('sentHistory', []);
  }
  List sentFiles = box.get('sentHistory');

  sentFiles.insertAll(
    0,
    files
        .map((e) => {
              "fileName": e!.split(Platform.pathSeparator).last,
              "date": DateTime.now(),
              "filePath": e
            })
        .toList(),
  );
}
