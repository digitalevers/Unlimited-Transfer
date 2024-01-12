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
import 'package:woniu/controllers/controllers.dart';

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
  

    // ignore: slash_for_doc_comments
    /**
     * 分享文件 包括外部意图和内部主动选择文件进行分享
     * /storage/emulated/0/
     * /data/data/0/com.digitalevers.transfer/files/uri_to_files
     */
  static Future<List<Map<String,String>>> share(context, { bool externalIntent = false, List<String> appList = const <String>[]}) async {
    if (externalIntent) {
      //分享意图
      if(Platform.isIOS){
        //TODO iOS分享意图
      } else if(Platform.isAndroid){
        List<SharedMediaFile> sharedMediaFiles = await ReceiveSharingIntent.getInitialMedia();
        fileList = transformList(sharedMediaFiles.map((e) => e.path).toList());
      }
    } else {
      //主动选择
      if(Platform.isIOS){
        //TODO iOS文件选择

      } else if(Platform.isAndroid){
        fileList  = transformList(await FileMethods.pickFiles());
        //log(fileList,StackTrace.current);
        for(int i = 0; i < fileList.length; i++){
          //第一种方式 使用插件试图转换成 /data/data 开头的内部链接 但是会将文件复制一份放到 "/data/data/0/包名" 的内部空间中 如果文件很大造成空间浪费而且复制会特别耗时
          //fileList![i] = (await toFile(fileList![i]!)).path;
          //print(fileList![i]);

          //第二种方式 使用 Android Api 转译地址来访问文件
          String? decodeContentUri = Uri.decodeComponent(fileList[i]["contentUri"]!);
          const platform = MethodChannel("AndroidApi");
          String originFilePath = await platform.invokeMethod("getOriginFilePathByUri",[decodeContentUri]);
          fileList[i]["originUri"] = originFilePath;
          if(originFilePath.startsWith("/storage/")){
            fileList[i]["storageUri"] = originFilePath;
          } else if(originFilePath.startsWith("/data/")){
            fileList[i]["privateUri"] = originFilePath;
          } else {
            throw Exception("无法转换File Uri");
          }
          //获取文件基本信息
          fileList[i]["baseName"] = getFileInfo(originFilePath)["baseName"]!;
          fileList[i]["fileName"] = getFileInfo(originFilePath)["fileName"]!;
          fileList[i]["shortFileName"] = getFileInfo(originFilePath)["shortFileName"]!;
          fileList[i]["extension"] = getFileInfo(originFilePath)["extension"]!;
          fileList[i]["fileSize"] = getFileInfo(originFilePath)["fileSize"]!;
        }
      }
    }
  
    //log(fileList,StackTrace.current);
    return fileList;
  }

}
