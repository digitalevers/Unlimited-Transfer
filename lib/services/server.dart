import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuotu/models/sender_model.dart';
import 'package:tuotu/pages/tabs/send_to_app.dart';
import 'package:tuotu/services/fileManager.dart';
import 'package:tuotu/services/file_services.dart';
import 'package:tuotu/controllers/controllers.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:tuotu/common/func.dart';
import 'package:tuotu/components/dialogs.dart';
import 'package:tuotu/common/global_variable.dart';
import 'package:tuotu/common/config.dart';
import 'package:bot_toast/bot_toast.dart';

class Server {
  static ServerStatus _serverStatus = ServerStatus.idle;
  static Map<String, Object>? serverInf;
  //static Map<String, String>? fileList;
  static HttpServer? _server;
  //启动httpserver
  static Future<Map<String, dynamic>> startServer(
      GlobalKey key, dynamic receiveFilesLogKey) async {
    try {
      _server = await HttpServer.bind('0.0.0.0', httpServerPort);
    } catch (e) {
      return {'hasErr': true, 'type': 'server', 'errMsg': '$e'};
    }

    _server!.listen(
      (HttpRequest request) async {
        if (request.method.toLowerCase() == 'post') {
          String baseUri = p.basename(request.requestedUri.toString());
          //log(baseUri,StackTrace.current);
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
            if (_serverStatus == ServerStatus.idle) {
              String jsonString = await request.bytesToString();
              Map<String, String> postData = pathinfo(jsonString);
              int fileCount = int.parse(postData['fileCount']!);
              int fileSize = int.parse(postData['fileSize']!);
              if (fileCount > 0 && fileSize > 0) {
                _serverStatus = ServerStatus.decision;
                //弹出提示框
                ServerIfReceiveFile res = await ifReceiveFile(
                    key.currentContext, fileCount, fileSize);
                if (res == ServerIfReceiveFile.reject) {
                  request.response.write(jsonEncode(
                      {'code': HttpResponseCode.rejectFile})); //告知客户端 "拒收"
                  _serverStatus = ServerStatus.idle;
                } else {
                  request.response.write(jsonEncode(
                      {'code': HttpResponseCode.acceptFile})); //告知客户端 "接收"
                  _serverStatus = ServerStatus.waiting;
                }
              }
            } else {
              request.response.write(jsonEncode(
                  {'code': HttpResponseCode.serverBusy})); //告知客户端 "服务端繁忙"
            }
          } else if (baseUri == "webfileupload") {
            //处理web端的文件POST上传请求
            const rootDir = '/storage/emulated/0';
            List<int> dataBytes = [];
            await for (var data in request) {
              dataBytes.addAll(data);
            }
            String? boundary = request.headers.contentType!.parameters['boundary'];
            final transformer = MimeMultipartTransformer(boundary!);
            final bodyStream = Stream.fromIterable([dataBytes]);
            final parts = await transformer.bind(bodyStream).toList();

            //默认上传目录
            String dir = "/Download";
            try {
              for (MimeMultipart part in parts) {
                //log(part.headers,StackTrace.current);
                final contentDisposition = part.headers['content-disposition'];
                final filename = RegExp(r'filename="([^"]*)"')
                    .firstMatch(contentDisposition!)
                    ?.group(1);
                final content = await part.toList();
                //log(filename,StackTrace.current);
                String? postKey = RegExp(r'name="([^"]*)"')
                    .firstMatch(contentDisposition)
                    ?.group(1);
                //默认POST 的dir键会排在filename前面 所以会先循环访问到
                if (filename == null) {
                  //log("$postKey-$postValue",StackTrace.current);
                  if (postKey == "dir") {
                    String postValue = String.fromCharCodes(content[0]);
                    dir = postValue;
                  }
                } else {
                  //log("$postKey-$filename",StackTrace.current);
                  String filePath = "$rootDir$dir/$filename";
                  File file = File(filePath);
                  //log(filePath,StackTrace.current);
                  IOSink sink = file.openWrite(mode: FileMode.write);
                  await sink.addStream(Stream.fromIterable(content));
                  await sink.flush();
                  await sink.close();

                  
                }
                // if (!Directory(uploadDirectory).existsSync()) {
                //   await Directory(uploadDirectory).create();
                // }
                // await File('$uploadDirectory/$filename').writeAsBytes(content[0]);
              }
            } catch (e) {
              print(e);
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
            // const uploadDirectory = '/storage/emulated/0/Download/';

            // final bodyStream = Stream.fromIterable([dataBytes]);
            // final parts = await transformer.bind(bodyStream).toList();

            // for (var part in parts) {
            //   print(part.headers);
            //   final contentDisposition = part.headers['content-disposition'];
            //   final filename = RegExp(r'filename="([^"]*)"')
            //       .firstMatch(contentDisposition!)
            //       ?.group(1);
            //   final content = await part.toList();
            //   print(String.fromCharCodes(content[0]));    //获得post值 上传目录和文件名
            //   if (!Directory(uploadDirectory).existsSync()) {
            //     await Directory(uploadDirectory).create();
            //   }

            //   await File('$uploadDirectory/$filename').writeAsBytes(content[0]);
            // }

            //3、流式写入文件 不会产生OOM
            try {
              String basename = Uri.decodeComponent(request.headers['baseName']![0]);

              int fileSize = int.parse(request.headers['content-length']![0]);
              String clientHostName = request.headers['client-hostname']![0];
              //开启热点的时候clientIP会与lanIP有所不同
              //String clientIP = request.connectionInfo!.remoteAddress.address;
              String clientIP = request.headers['client-lanip']![0];

              //log(await utf8.decoder.bind(request).join(),StackTrace.current);
              String fileName = p.withoutExtension(basename);
              String extension = p.extension(basename);
              String downloadDir = "${await getDownloadDir()}/";
              //log(downloadDir, StackTrace.current);

              String filePath = downloadDir + basename;
              File file = File(filePath);
              //有同名文件 则在源文件后追加一个随机文件名生成一个新的文件名
              if (file.existsSync()) {
                String randomFileSuffix = (100 + Random().nextInt(999 - 100)).toString();
                filePath ="$downloadDir${fileName}_$randomFileSuffix$extension";
                file = File(filePath);
                if (file.existsSync()) {
                  throw const FileSystemException("The file have exist already");
                }
              }
              IOSink sink = file.openWrite(mode: FileMode.append);

              int currentReceiveProgress = remoteDevicesData[clientIP]!["progress"] ?? 0;
              //添加 request拦截器实时统计已发送文件大小 每+1%的文件大小setState更新进度条
              int byteCount = 0;
              Stream<List<int>> requestStream = request.transform(
                StreamTransformer.fromHandlers(
                  handleData: (data, sink) {
                    byteCount += data.length;
                    int latestTransferProgress =
                        (byteCount * 100 / fileSize).ceil();
                    if (latestTransferProgress != currentReceiveProgress) {
                      currentReceiveProgress = latestTransferProgress;
                      remoteDevicesData[clientIP]!["progress"] = latestTransferProgress;
                      remoteDevicesData[clientIP]!["remoteDeviceWidgetKey"].currentState.setState(() {});
                    }
                    sink.add(data);
                  },
                  handleError: (error, stack, sink) {
                    log(error, StackTrace.current);
                    sink.close();
                  },
                  handleDone: (sink) {
                    //文件传输完毕 重新初始化step indicator组件
                    remoteDevicesData[clientIP]!["progress"] = 0;
                    remoteDevicesData[clientIP]!["remoteDeviceWidgetKey"]
                        .currentState
                        .setState(() {});
                    sink.close();
                  },
                ),
              );

              await sink.addStream(requestStream);
              await sink.flush();
              await sink.close();
              //文件传输完毕 服务器置为空闲状态 并弹窗接收完成提示
              _serverStatus = ServerStatus.idle;
              // 更新接收文件记录显示区的UI界面
              String fileInfoJson = jsonEncode({
                "fileFullPath": filePath,
                "from": "$clientIP  ( $clientHostName )",
                "date": DateTime.now().toString().substring(0, 19)
              });
              receiveFilesLogKey.currentState!.insertFilesLog(fileInfoJson);
              BotToast.showText(text: "接收完毕");
            } catch (e) {
              e.printError();
              _serverStatus = ServerStatus.idle;
              request.response.close();
            }
          } else if (baseUri == "fileManager.php") {
            //log(await getExternalCacheDirectories(),StackTrace.current); // /storage/emulated/0/Android/data/包名/cache
            //log(await getExternalStorageDirectories(),StackTrace.current);  // /storage/emulated/0/Android/data/包名/files
            //log(await getExternalStorageDirectory(),StackTrace.current);      // /storage/emulated/0/Android/data/包名/files
            //log(await getApplicationSupportDirectory(),StackTrace.current);   // /data/user/0/包名/files
            Map<String, String> options = {"rootDir": "/storage/emulated/0"};
            FileManager manager = FileManager(FileSystemFileStorage(), options);
            String postParams = await request.bytesToString(utf8);
            List<String> params = postParams.split('&');
            Map<String, String> postKeyValue = {};
            for (String val in params) {
              if (val.split('=')[0] == 'dir') {
                postKeyValue[val.split('=')[0]] =
                    Uri.decodeFull(val.split('=')[1]);
              } else {
                postKeyValue[val.split('=')[0]] = val.split('=')[1];
              }
            }
            String result = "";
            try {
              //log(postKeyValue,StackTrace.current);
              result = manager.process(postKeyValue);
            } catch (e) {
              //result = '{result: \'0\', gserror: \''.addslashes($e->getMessage()).'\', code: \''.$e->getCode().'\'}';
              e.printError();
            }
            request.response.write(result);
          } else {
            request.response.write('Request Path denied access');
          }
          request.response.close();
        } else {
          //GET 请求
          //下载文件的GET请求
          String path = request.requestedUri.path;
          if (p.basename(path) == "fileManager.php") {
            Map<String, List<String>> params =
                request.requestedUri.queryParametersAll;
            //log(params,StackTrace.current);
            //调用fileManager引擎处理opt
            Map<String, String> options = {"rootDir": "/storage/emulated/0"};
            FileManager manager = FileManager(FileSystemFileStorage(), options);
            Map<String, dynamic> requestArgs = {
              "dir": params["dir"]![0],
              "request": request,
              "opt": params["opt"]![0],
              "filename": params["filename"]![0]
            };
            //log(requestArgs,StackTrace.current);
            try {
              manager.process(requestArgs);
            } catch (e) {
              print(e);
            }
          } else {
            //其他静态资源的GET请求
            if (path == '/') {
              path = '/index.html';
            }
            String extension = p.extension(path);
            //log(extension,StackTrace.current);
            request.response.headers.contentType =
                getHeaderContentType(extension);

            //log(path,StackTrace.current);
            if (extension == ".html" ||
                extension == ".js" ||
                extension == ".css") {
              String data = await rootBundle.loadString("assets$path");

              request.response.write(data);
              request.response.close();
            } else if (extension == ".png" ||
                extension == ".jpg" ||
                extension == ".gif") {
              //HTTP SERVER不直接支持 reponse.write 写入二进制数据
              //暂时有两个解决方案 一种是将 assets下的图片读取到/data/data私域目录 然后打开 file stream 再 reponse.addstream输出
              //还有一种是在html和css文件内直接用base64图片编码
              ByteData img = await rootBundle.load("assets$path");
              String dir = (await getApplicationSupportDirectory()).path;
              String privateFilePath = "$dir/assets$path";
              File privateFile = File(privateFilePath);
              if (!privateFile.existsSync()) {
                privateFile.createSync(recursive: true);
                await privateFile.writeAsBytes(img.buffer
                    .asUint8List(img.offsetInBytes, img.lengthInBytes));
              }
              request.response
                  .addStream(privateFile.openRead())
                  .then((value) => request.response.close());
            }
          }
        }
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
