import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:get/get.dart';
import 'package:woniu/common/func.dart';
//import 'package:woniu/models/file_model.dart';
//import 'package:woniu/models/sender_model.dart';
//import 'package:woniu/models/share_error_model.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
//import 'package:hive/hive.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';

//import 'package:woniu/components/dialogs.dart';
//import 'package:woniu/components/snackbar.dart';
import 'file_services.dart';
import 'package:woniu/main.dart';
//import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:woniu/common/config.dart';
import 'package:woniu/common/global_variable.dart';

import 'package:uri_to_file/uri_to_file.dart';

class Sender{
  //static final HttpClient _client = HttpClient() ;
  //static String? _address;
  //static List<String?>? _fileList= [];
  //static int? _randomSecretCode;
  static String? photonLink;
  static Uint8List? avatar;
  

  //用户点击选择文件
  static handleSharing(context,{bool externalIntent = false, List<String> appList = const <String>[]}) async {
    if (Platform.isAndroid) {
      // cause in case of android bottom sheet opens up when share is tapped
      //Android 需要注释 否则选择文件后会黑屏
      //Navigator.pop(nav.currentContext!);
    }
    List<String?>? shareFilesList = await Sender.share(nav.currentContext, externalIntent: externalIntent);
    return shareFilesList;
    // Log(shareRespMap, StackTrace.current);
    // ShareError shareErr = ShareError.fromMap(shareRespMap);

    // switch (shareErr.hasError) {
    //   case true:
    //     showSnackBar(nav.currentContext, '${shareErr.errorMessage}');
    //     break;
    //   case false:
    //     Navigator.pushNamed(nav.currentContext!, '/sharepage');
    //     break;
    // }
  }

    // ignore: slash_for_doc_comments
    /**
     * 分享文件 包括外部意图和内部主动选择文件进行分享
     * /storage/emulated/0/
     * /data/data/0/com.example.woniu/files/uri_to_files
     */
  static Future<List<String?>?> share(context, { bool externalIntent = false, List<String> appList = const <String>[]}) async {
    if (externalIntent) {
      List<SharedMediaFile> sharedMediaFiles = await ReceiveSharingIntent.getInitialMedia();
      fileList = sharedMediaFiles.map((e) => e.path).toList();
      
      //await assignIP();
      //Future<Map<String, dynamic>> res = _startServer(_fileList, context);
      //return await res;
    } else {
      fileList  = await FileMethods.pickFiles();
      ///print(fileList);

      for(int i = 0; i < fileList!.length; i++){
        //第一种方式 使用插件试图转换成 /data/data 开头的内部链接 但是会将文件复制一份放到 "/data/data/0/包名" 的内部空间中 如果文件很大造成空间浪费而且复制会特别耗时
        //fileList![i] = (await toFile(fileList![i]!)).path;

        //第二种方式 使用 Android Api 转译地址来访问文件
        fileList![i] = Uri.decodeComponent(fileList![i]!);
        //print(fileList![i]);
        const platform = MethodChannel("AndroidApi");
        String originFilePath = await platform.invokeMethod("getOriginFilePathByUri",[fileList![i]]);
        fileList![i] = originFilePath;

        //fileList![i] = fileList![i]?.replaceAll("content://com.android.externalstorage.documents/document/primary:", "/storage/emulated/0/");
        //print(fileList![i]);
      }
      
    }
    return fileList;
  }

  //发送文件的一些修饰工作
  static preSendFile(){

  }

  //使用HttpClient发送文件
  //待发送的文件列表
  static sendFile(HttpClient client, List<String?>? applist) async {
    //1、第一种发送方式 (可多次发送http请求) 这种方式会产生OOM-在红米note9 pro上文件超过255M 就会OOM
    // var uri = Uri(scheme: 'http',host: '192.168.1.193',port:8888,path: '/fileupload');
    // var file = File(applist![0]!); 
    // var hfile = await file.open();
    // var fileSize = file.lengthSync();
    // var content = hfile.readSync(fileSize).toList();
    // //Log(content,StackTrace.current);
    // for(int i = 0;i < 2;i++){
    //   HttpClientRequest request = await client.postUrl(uri);
    //   request.headers.set("filename", p.basename(applist![0]!));
    //   request.add(content); // 加入http发送缓冲区
    //   //await request.flush();// bug 使用flush无法发送文件内容
    //   await request.close();
    // }
    // client.close();

    //2、第二种发送方式 流式发送client端不会OOM - 优先使用该方式
    // var file = File(applist![0]!); 
    // var uri = Uri(scheme: 'http',host: testServer,port:httpServerPort,path: '/fileupload');
    // HttpClientRequest request = await  client.postUrl(uri);
    // //request.headers.set(HttpHeaders.contentTypeHeader, "multipart/form-data");
    // request.headers.set("filename", p.basename(applist[0]!));
    // await request.addStream(file.openRead());
    // HttpClientResponse response = await request.close();
    // var result = await response.transform(utf8.decoder).join();
    // Log(result, StackTrace.current);
    // client.close();

    //3、第三种发送方式
    // var request3 = http.MultipartRequest("POST", uri);
    // request3.files.add(await http.MultipartFile.fromPath(
    //     'package',
    //     applist[0]!));
    // var response = await request3.send();
    // if (response.statusCode == 200) print('Uploaded!');
  }

  //使用HttpClient发信息 "待发送文件信息"
  // static sendFileInfo(HttpClient client, List<String?>? fileList, context) async {
  //   int fileSize = 1;   //待发送文件大小 单位M
  //   int fileCount = 10;  //待发送文件数量
  //   String url = "http://$testServer:$httpServerPort/fileinfo";
  //   String formBody = "fileSize=$fileSize&fileCount=$fileCount";

  //   HttpClientRequest request = await  client.postUrl(Uri.parse(url));
  //   request.add(utf8.encode(formBody));
  //   HttpClientResponse response = await request.close();
  //   String result = await response.transform(utf8.decoder).join();
  //   Log(result, StackTrace.current);
  //   //分析服务端响应 如果同意接收则开始发送文件
  //   Map resMap = jsonDecode(result);
  //   if(resMap['code'] == HttpResponseCode.acceptFile){
  //     preSendFile();
  //     //sendFile(client, applist);
  //   } else {
  //     CherryToast.warning(
  //       title:  Text(HttpResponseCodeMsg[resMap['code']]!),
  //       toastPosition: Position.bottom,
  //       displayCloseButton:false,
  //       actionHandler:(){},
  //       //animationDuration: const Duration(milliseconds:  500),
  //     ).show(context);
  //   }
    
  //   //client.close();// 这里若关闭了 就不能再次发送请求了
  // }



  //get details about server
  // static getServerInfo() {
  //   var info = {
  //     'ip': _server.address.address,
  //     'port': _server.port,
  //     'host': Platform.localHostname,
  //     'os': Platform.operatingSystem,
  //     'version': Platform.operatingSystemVersion,
  //     'files-count': _fileList.length,
  //     'avatar': avatar
  //   };
  //   SenderModel senderData = SenderModel.fromJson(info);

  //   return senderData;
  // }

  //bool get hasMultipleFiles => _fileList.length > 1;
  //static String get getPhotonLink => photonLink;
}
