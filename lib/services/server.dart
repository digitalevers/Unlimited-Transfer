import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:hive/hive.dart';
import 'package:woniu/models/sender_model.dart';
import 'package:woniu/pages/tabs/send_to_app.dart';
import 'package:woniu/services/file_services.dart';
import 'package:woniu/controllers/controllers.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:woniu/common/func.dart';
import 'package:woniu/components/dialogs.dart';
import 'package:woniu/common/global_variable.dart';
import 'package:woniu/common/config.dart';
import 'package:bot_toast/bot_toast.dart';

import 'package:woniu/pages/modules/receive_files_log.dart';

class Server {
  static ServerStatus _serverStatus = ServerStatus.idle;
  static Map<String, Object>? serverInf;
  static Map<String, String>? fileList;
  static HttpServer? _server;
  //启动httpserver
  static Future<Map<String, dynamic>> startServer(GlobalKey key, GlobalKey<ReceiveFilesLogState> receiveFilesLogKey) async {
    try {
      _server = await HttpServer.bind('0.0.0.0', httpServerPort);
    } catch (e) {
      return {'hasErr': true, 'type': 'server', 'errMsg': '$e'};
    }

    bool? allowRequest;
    _server!.listen(
      (HttpRequest request) async {
        if (request.method.toLowerCase() == 'post') {
          String baseUri = p.basename(request.requestedUri.toString());
   
          if (baseUri == "fileinfo") {
            // String os = (request.headers['os']![0]);
            // String username = request.headers['receiver-name']![0];
            // //allowRequest = await senderRequestDialog(username, os);

            // if (allowRequest == true) {
            //   //appending receiver data
            //   //request.response.write(jsonEncode({'code': _randomSecretCode, 'accepted': true}));
            //   request.response.close();
            // } else {
            //   request.response.write(
            //     jsonEncode({'code': -1, 'accepted': false}),
            //   );
            //   request.response.close();
            // }
            if(_serverStatus == ServerStatus.idle){
              String jsonString = await request.bytesToString();
              Map<String,String> postData  = pathinfo(jsonString);
              int fileCount = int.parse(postData['fileCount']!);
              int fileSize = int.parse(postData['fileSize']!);
              if(fileCount > 0 && fileSize > 0){
                _serverStatus = ServerStatus.decision;
                //弹出提示框
                ServerIfReceiveFile res = await ifReceiveFile(key.currentContext, fileCount, fileSize);
                if(res == ServerIfReceiveFile.reject){
                  request.response.write(jsonEncode({'code': HttpResponseCode.rejectFile})); //告知客户端 "拒收"
                  _serverStatus = ServerStatus.idle;
                } else {
                  request.response.write(jsonEncode({'code': HttpResponseCode.acceptFile})); //告知客户端 "接收"
                  _serverStatus = ServerStatus.waiting;
                }
              }
            } else {
              request.response.write(jsonEncode({'code': HttpResponseCode.serverBusy})); //告知客户端 "服务端繁忙"
            }
            
            
          } else if (baseUri == "fileupload") {
            //Server端在8G的Win10系统中超过510M左右的文件传输便会产生OOM
            //而Client端在Android上，只要文件超过255M便会产生OOM
            //由此可见 OOM的文件大小上限与环境配置相关
            //1、请求头中没有boundary分界符 这种写入文件的方式会产生OOM
            // const uploadDirectory = './upload';
            // List<int> dataBytes = [];
            // await for (var data in request) {
            //   dataBytes.addAll(data);
            // }
            // var filename = request.headers['filename']![0];
            // await File('$uploadDirectory/$filename').writeAsBytes(dataBytes);

            //2、请求头中带有boundary分界符
            // List<int> dataBytes = [];
            // await for (var data in request) {
            //   dataBytes.addAll(data);
            // }
            // String? boundary = request.headers.contentType!.parameters['boundary'];
            // final transformer = MimeMultipartTransformer(boundary!);
            // const uploadDirectory = './upload';

            // final bodyStream = Stream.fromIterable([dataBytes]);
            // final parts = await transformer.bind(bodyStream).toList();

            // for (var part in parts) {
            //   print(part.headers);
            //   final contentDisposition = part.headers['content-disposition'];
            //   final filename = RegExp(r'filename="([^"]*)"')
            //       .firstMatch(contentDisposition!)
            //       ?.group(1);
            //   final content = await part.toList();

            //   if (!Directory(uploadDirectory).existsSync()) {
            //     await Directory(uploadDirectory).create();
            //   }

            //   await File('$uploadDirectory/$filename').writeAsBytes(content[0]);
            // }

            //3、流式写入文件 不会产生OOM
            //const uploadDirectory = './upload';
            //File file = File('$uploadDirectory/$filename');
            String filename = request.headers['filename']![0];
            String filenameWithoutExtension = p.withoutExtension(filename);
            String extension  = p.extension(filename);
            

            String downloadDir = "/storage/emulated/0/Download/";
            String filePath = downloadDir + filename;
            File file = File(filePath);
            //有同名文件 则在源文件后追加一个随机文件名生成一个新的文件名
            if(file.existsSync()){
              String randomFileSuffix = (100 + Random().nextInt(999 - 100)).toString();
              filePath = "$downloadDir${filenameWithoutExtension}_$randomFileSuffix$extension";
              file = File(filePath);
              if(file.existsSync()){
                throw const FileSystemException("The file have exist already");
              }
            }
            IOSink sink = file.openWrite(mode: FileMode.append);
            await sink.addStream(request);
            await sink.flush();
            await sink.close();
            //文件传输完毕 服务器置为空闲状态 并弹窗接收完成提示
            _serverStatus = ServerStatus.idle;
            //文件接收完毕 将文件路径写入SharedPreferences作为接收记录 
            List<String>? receviceFilesLog = prefs!.getStringList("receviceFilesLog") ?? [];
            receviceFilesLog.add(filePath);
            //log(receiveFilesLogKey,StackTrace.current);
            prefs!.setStringList("receviceFilesLog", receviceFilesLog).then((value){
              receiveFilesLogKey.currentState!.test111();
            });
            
            // 更新接收文件记录显示区的UI界面


            //print("接收完毕");
            // CherryToast.info(
            //   title:  const Text("接收完毕"),
            //   toastPosition: Position.bottom,
            //   displayCloseButton:false,
            //   actionHandler:(){},
            //   animationDuration: const Duration(milliseconds:  500),
            // ).show(key.currentContext as BuildContext);
            BotToast.showText(text:"接收完毕");
          } else {
            // print("server");
            // //uri should be in format http://ip:port/secretcode/file-index
            // List requriToList = request.requestedUri.toString().split('/');
            // if (int.parse(requriToList[requriToList.length - 2]) == _randomSecretCode) {

            // } else {
            //   request.response.write('Wrong secret-code.Photon-server denied access');
            // }
          }
        } else {
          //非post
           //print(request.requestedUri);
           request.response
        ..headers.contentType = ContentType.html
        ..write('''
          <html>
          <head>
            <title>Image Upload Server</title>
          </head>
          <body>
            <form method="post" action="/fileupload" enctype="multipart/form-data">
              <input type="file" name="fileupload" /><br /><br />
              <button type="submit">Upload to server</button>
            </form>
          </body>
          </html>
        ''');
        }
        request.response.close();
      },
    );
    return {
      'hasErr': false,
      'type': null,
      'errMsg': null,
    };
  }

  // static closeServer(context) async {
  //   try {
  //     await _server.close();
  //     await FileMethods.clearCache();
  //   } catch (e) {
  //     showSnackBar(context, 'Server not started yet');
  //   }
  // }
}
