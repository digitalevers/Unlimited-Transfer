// ignore: slash_for_doc_comments
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:uri_to_file/uri_to_file.dart';
import 'package:woniu/controllers/controllers.dart';
import 'package:path/path.dart' as p;

import 'commclass.dart';
import 'config.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'global_variable.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:bot_toast/bot_toast.dart';


// ignore: slash_for_doc_comments
/**
 * 打印日志 输出所在文件及所在行
 */
void log(var msg, [StackTrace? st]) {
  st ??= StackTrace.current;
  if (debug) {
    CustomPrint customPrint = CustomPrint(st);
      // ignore: avoid_print
    print("打印信息:$msg, 所在文件:${customPrint.fileName},所在行:${customPrint.lineNumber}");
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

//转换文件大小的规格
String fommatFileSize(int fileSizeBytes){
  int power = 0;
  List<String> units = ['Bytes','KB','MB','GB','TB'];
  int numLength = fileSizeBytes.toString().length;
  power = (numLength - 1) ~/ 3;
  num divisor = pow(1000,power);
  String formatedFileSize = (fileSizeBytes / divisor).toStringAsFixed(1);
  return "$formatedFileSize${units[power]}";
}

//获取文件名的简略形式 以免文件名过长
//params limLengh 限制的简略文件名字符长度（包含后缀）
String getShortFileName(String baseName,[int limLengh = 6]){
  if(baseName.length <= limLengh){
    return baseName;
  }
  baseName = baseName.substring(baseName.length - limLengh);
  return "...$baseName";
}

//根据 storageUri 或 privateUri 获取文件基本信息
Map<String,String>  getFileInfo(String storageOrPrivateUri){
  Map<String,String> fileInfo = {};
  fileInfo['baseName'] = p.basename(storageOrPrivateUri);
  fileInfo['fileName'] = p.withoutExtension(fileInfo['baseName']!);
  fileInfo['shortFileName'] = getShortFileName(fileInfo['baseName']!);
  fileInfo['extension'] = p.extension(fileInfo['baseName']!);
  File tempFile = File(storageOrPrivateUri);
  fileInfo['fileSize'] = tempFile.lengthSync().toString();
  return fileInfo;
}

//发送文件信息 客户端发送到服务端
Future<void> sendFileInfo(HttpClient client_, String serverIP_, int serverPort_, List<Map<String,String>> fileList_, context_) async {
  int fileCount = fileList_.length;  //待发送文件数量
  int fileSize = 0;                   //待发送文件大小 单位M
  for(int i = 0;i < fileCount;i++){
    fileSize += int.parse(fileList_[i]['fileSize']!);
  }
  
  String url      = "http://$serverIP_:$serverPort_/fileinfo";
  String formBody = "fileSize=$fileSize&fileCount=$fileCount";

  HttpClientRequest request = await  client.postUrl(Uri.parse(url));
  request.add(utf8.encode(formBody));
  HttpClientResponse response = await request.close();
  String result = await response.transform(utf8.decoder).join();
  //log(result, StackTrace.current);
  if(result == ""){
    log("服务器无返回");
  } else {
    //分析服务端响应 如果同意接收则开始发送文件
    Map resMap = jsonDecode(result);
    if(resMap['code'] == HttpResponseCode.acceptFile){
      //preSendFile();
      if(fileList_.isNotEmpty){
        for(int i = 0; i < fileList_.length; i++){
          //若不使用await 则发送多文件时会并发进行从而会让进度条闪烁
          await sendFile(client_, serverIP_, serverPort_, fileList_[i], i, fileList_.length);
        }
      } else {
        BotToast.showText(text:"无文件内容可发送");
      }
    } else {
      BotToast.showText(text:"对方${HttpResponseCodeMsg[resMap['code']]!}");
    }
  }
  //client.close();// 这里若关闭了 就不能再次发送请求了
}

//发送单个文件
//index 待发送文件在发送队列中的索引
Future<String> sendFile(HttpClient client_, String serverIP_, int serverPort_, Map<String,String> filelistItem, int index, int length) async {
  Uri uri = Uri(scheme: 'http', host: serverIP_, port: serverPort_, path: '/fileupload');
  HttpClientRequest request = await client_.postUrl(uri);
  //log(filelist_,StackTrace.current);
  try{
    String filePath = filelistItem["originUri"]!;
    File file = File(filePath); 
    //request.headers.set(HttpHeaders.contentTypeHeader, "multipart/form-data");
    //针对某些机型 比如redmi 12C 上莫名无法读取 /storage/emulator/0/下的文件 而且跟文件后缀有关 只有jpg等媒体文件可以读取 改成json或者其他后缀就无法读取
    //暂时没有找到完美解决方案 只能先将其复制到私域空间得到类似/data/data/的地址来进行访问
    //上述现象其实是没有授权所有文件访问权限引起
    request.headers.set("baseName", Uri.encodeComponent(filelistItem["baseName"]!));
    request.headers.set("content-length", filelistItem["fileSize"]!);
    request.headers.set("client-hostname", deviceInfo["model"]);
    request.headers.set("client-lanip", deviceInfo["lanIP"]);

    Stream<List<int>> fileStream = file.openRead();
    //已发送长度
    int byteCount = 0;
    //待发送文件总长度
    int fileSize = int.parse(filelistItem["fileSize"]!);
    //发送进度
    int currentSentProgress = remoteDevicesData[serverIP_]!["progress"] ?? 0;
    //fileStream添加interceptor
    Stream<List<int>> sendStream = fileStream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          byteCount += data.length;
          int latestSentProgress = (byteCount * 100 / fileSize).ceil();
          //log(latestSentProgress,StackTrace.current);
          if(latestSentProgress != currentSentProgress){
              currentSentProgress = latestSentProgress;
              remoteDevicesData[serverIP_]!["progress"] = latestSentProgress;
              remoteDevicesData[serverIP_]!["remoteDeviceWidgetKey"].currentState.setState((){});
          }
          //发送完毕提示
          if(latestSentProgress >= 100){
            log(latestSentProgress,StackTrace.current);
            if(index < length - 1){
              BotToast.showText(text:"第${index+1}个文件发送完毕");
            } else {
              BotToast.showText(text:"发送完毕");
            }
          }
          sink.add(data);
        },
        handleError: (error, stack, sink) {

        },
        handleDone: (sink) {
          //文件发送完毕 重新初始化step indicator组件
          remoteDevicesData[serverIP_]!["progress"] = 0;
          remoteDevicesData[serverIP_]!["remoteDeviceWidgetKey"].currentState.setState((){});
          sink.close();
        },
      ),
    );
    await request.addStream(sendStream);

  } on FileSystemException {
    //这里一定要关闭request 并重新打开一个request
    request.close();
    request = await client_.postUrl(uri);
    request.headers.set("baseName", Uri.encodeComponent(filelistItem["baseName"]!));
    request.headers.set("content-length", filelistItem["fileSize"]!);
    const platform = MethodChannel("AndroidApi");
    String newPrivatePath = await platform.invokeMethod("copyFileToPrivateSpace",[filelistItem["contentUri"], filelistItem["fileName"], filelistItem["extension"]]);
    File newFile = File(newPrivatePath);
    //log(newFile,StackTrace.current);
    await request.addStream(newFile.openRead());
  } catch(e,stack) {
    print(e);
    print(stack);
    request.close();
  }

  HttpClientResponse response = await request.close();
  String result = await response.transform(utf8.decoder).join();
  return result;
}

//将 List<String?> 转成 List<Map<String,String>>的形式
List<Map<String,String>> transformList(List<String?> list){
  List<Map<String,String>> result = [];
  //Map<String,String> map = {"contentUri":"","storageUri":"","privateUri":"","baseName":"","fileName":"","extension":""};
  for(int i = 0; i < list.length; i++){
    Map<String,String> map = {};
    map["contentUri"] = list[i]!;
    result.add(map);
  }
  
  return result;
}


ContentType getHeaderContentType(String extension){
  ContentType ct = ContentType.text;
  switch(extension){
    case ".html":
      ct = ContentType.html;
      break;
    case ".js":
      ct = ContentType.parse("application/javascript; charset=utf-8");
      break;
    case ".css":
      ct = ContentType.parse("text/css; charset=utf-8");
      break;
    case ".gif":
      ct = ContentType.parse("image/gif");
      break;
    case ".png":
      ct = ContentType.parse("image/png");
      break;
    case ".ico":
      ct = ContentType.parse("image/ico");
      break;
    case ".apk":
      ct = ContentType.parse("application/vnd.android.package-archive");
      break;
    case ".json":
      ct = ContentType.json;
      break;
  }
  return ct;
}

// getEstimatedTime(receivedBits, totalBits, currentSpeed) {
//   ///speed in [mega bits  x * 10^6 bits ]
//   double estBits = (totalBits - receivedBits) / 1000000;
//   int estTimeInInt = (estBits ~/ currentSpeed);
//   int mins = 0;
//   int seconds = 0;
//   int hours = 0;
//   hours = estTimeInInt ~/ 3600;
//   mins = (estTimeInInt % 3600) ~/ 60;
//   seconds = ((estTimeInInt % 3600) % 60);
//   if (hours == 0) {
//     if (mins == 0) {
//       return 'About $seconds seconds left';
//     }
//     return 'About $mins m and $seconds s left';
//   }
//   return 'About $hours h $mins m $seconds s left';
// }

// storeHistory(Box box, String savePath) {
//   if (box.get('fileInfo') == null) {
//     box.put('fileInfo', []);
//   }
//   List fileInfo = box.get('fileInfo') as List;
//   fileInfo.insert(
//     0,
//     {
//       'fileName': savePath.split(Platform.pathSeparator).last,
//       'date': DateTime.now(),
//       'filePath': savePath
//     },
//   );

//   box.put('fileInfo', fileInfo);
// }

// int getRandomNumber() {
//   Random rnd;
//   try {
//     rnd = Random.secure();
//   } catch (_) {
//     rnd = Random();
//   }
//   return rnd.nextInt(10000);
// }


// processReceiversData(Map<String, dynamic> newReceiverData) {
//   var inst = GetIt.I.get<ReceiverDataController>();
//   inst.receiverMap.addAll(
//     {
//       "${newReceiverData["receiverID"]}": {
//         "hostName": newReceiverData["hostName"],
//         "os": newReceiverData["os"],
//         "currentFileName": newReceiverData["currentFileName"],
//         "currentFileNumber": newReceiverData["currentFileNumber"],
//         "filesCount": newReceiverData['filesCount'],
//         "isCompleted": newReceiverData["isCompleted"],
//       }
//     },
//   );
// }

// Future<void> storeSentFileHistory(List<String?> files) async {
//   Box box = await Hive.openBox('appData');
//   if (box.get('sentHistory') == null) {
//     box.put('sentHistory', []);
//   }
//   List sentFiles = box.get('sentHistory');

//   sentFiles.insertAll(
//     0,
//     files
//         .map((e) => {
//               "fileName": e!.split(Platform.pathSeparator).last,
//               "date": DateTime.now(),
//               "filePath": e
//             })
//         .toList(),
//   );
// }
