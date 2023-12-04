import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:hive/hive.dart';
import 'package:woniu/models/sender_model.dart';
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

class Server {
  static ServerStatus _serverStatus = ServerStatus.idle;
  static Map<String, Object>? serverInf;
  static Map<String, String>? fileList;
  static HttpServer? _server;
  //启动httpserver
  static Future<Map<String, dynamic>> startServer(GlobalKey key) async {
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
                ServerIfReceiveFile res = await ifReceiveFile(key.currentContext,fileCount,fileSize);
                if(res == ServerIfReceiveFile.reject){
                  request.response.write(jsonEncode({'code': HttpResponseCode.rejectFile})); //向客户端发送拒收消息
                  _serverStatus = ServerStatus.idle;
                } else {
                  request.response.write(jsonEncode({'code': HttpResponseCode.acceptFile})); //向客户端发送接收消息
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
            //print('receive file');
            const uploadDirectory = './upload';
            var filename = request.headers['filename']![0];
            var file = File('$uploadDirectory/$filename');
            var sink = file.openWrite(mode: FileMode.append);
            await sink.addStream(request);
            // await for (Uint8List data in request) {
            //   sink.write(data);
            // }
            await sink.flush();
            await sink.close();
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
