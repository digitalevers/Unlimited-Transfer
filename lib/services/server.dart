import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:woniu/models/sender_model.dart';
import 'package:woniu/pages/tabs/send_to_app.dart';
import 'package:woniu/services/fileManager.dart';
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


class Server {
  static ServerStatus _serverStatus = ServerStatus.idle;
  static Map<String, Object>? serverInf;
  //static Map<String, String>? fileList;
  static HttpServer? _server;
  //启动httpserver
  static Future<Map<String, dynamic>> startServer(GlobalKey key,dynamic receiveFilesLogKey) async {
    try {
      _server = await HttpServer.bind('0.0.0.0', httpServerPort);
    } catch (e) {
      return {'hasErr': true, 'type': 'server', 'errMsg': '$e'};
    }


    _server!.listen(
      (HttpRequest request) async {
        if (request.method.toLowerCase() == 'post') {
          String baseUri = p.basename(request.requestedUri.toString());
          log(baseUri,StackTrace.current);
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
            List<int> dataBytes = [];
            await for (var data in request) {
              dataBytes.addAll(data);
            }
            String? boundary = request.headers.contentType!.parameters['boundary'];
            final transformer = MimeMultipartTransformer(boundary!);
            const uploadDirectory = '/storage/emulated/0/Download/';

            final bodyStream = Stream.fromIterable([dataBytes]);
            final parts = await transformer.bind(bodyStream).toList();

            for (var part in parts) {
              print(part.headers);
              final contentDisposition = part.headers['content-disposition'];
              final filename = RegExp(r'filename="([^"]*)"')
                  .firstMatch(contentDisposition!)
                  ?.group(1);
              final content = await part.toList();
              print(String.fromCharCodes(content[0]));    //获得post值 上传目录和文件名
              if (!Directory(uploadDirectory).existsSync()) {
                await Directory(uploadDirectory).create();
              }

              await File('$uploadDirectory/$filename').writeAsBytes(content[0]);
            }
            return;
            //3、流式写入文件 不会产生OOM
            String basename = "test111.pdf";
            if(request.headers['baseName'] != null){
              basename = request.headers['baseName']![0];
            }
            //await utf8.decoder.bind(request).join();
            //print(await request.transform(utf8.decoder).join());


            String fileName = p.withoutExtension(basename);
            String extension  = p.extension(basename);
            String downloadDir = "/storage/emulated/0/Download/";
            String filePath = downloadDir + basename;
            File file = File(filePath);
            //有同名文件 则在源文件后追加一个随机文件名生成一个新的文件名
            if(file.existsSync()){
              String randomFileSuffix = (100 + Random().nextInt(999 - 100)).toString();
              filePath = "$downloadDir${fileName}_$randomFileSuffix$extension";
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
            // 更新接收文件记录显示区的UI界面
            receiveFilesLogKey.currentState!.insertFilesLog(filePath);
            
            //print("接收完毕");
            // CherryToast.info(
            //   title:  const Text("接收完毕"),
            //   toastPosition: Position.bottom,
            //   displayCloseButton:false,
            //   actionHandler:(){},
            //   animationDuration: const Duration(milliseconds:  500),
            // ).show(key.currentContext as BuildContext);
            BotToast.showText(text:"接收完毕");
          } else if(baseUri == "fileManager.php"){
            //log(await getExternalCacheDirectories(),StackTrace.current); // /storage/emulated/0/Android/data/包名/cache
            //log(await getExternalStorageDirectories(),StackTrace.current);  // /storage/emulated/0/Android/data/包名/files
            //log(await getExternalStorageDirectory(),StackTrace.current);      // /storage/emulated/0/Android/data/包名/files
            //log(await getApplicationSupportDirectory(),StackTrace.current);   // /data/user/0/包名/files
            Map<String,String> options = {"rootDir":"/storage/emulated/0"};
            FileManager manager = FileManager(FileSystemFileStorage(), options);
            String postParams = await request.bytesToString(utf8);
            List<String> params = postParams.split('=');
            //log(postParams,StackTrace.current);

            Map<String,String> requestArgs = {"dir":Uri.decodeFull(params[1])};
            String result = "";
            try {
              result = manager.process(requestArgs);
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
          //非post get 路由处理
           //print(request.requestedUri);
          String path = request.requestedUri.path;
          if(path == '/'){
            path = '/index.html';
          }
          String extension = p.extension(path);
          //log(extension,StackTrace.current);
          switch(extension){
            case ".html":
              request.response.headers.contentType = ContentType.html;
              break;
            case ".js":
              request.response.headers.contentType = ContentType.parse("application/javascript; charset=utf-8");
              break;
            case ".css":
              request.response.headers.contentType = ContentType.parse("text/css; charset=utf-8");
              break;
            case ".gif":
              request.response.headers.contentType = ContentType.parse("image/gif");
              break;
            case ".png":
              request.response.headers.contentType = ContentType.parse("image/png");
              break;
            case ".ico":
              request.response.headers.contentType = ContentType.parse("image/ico");
              break;
            case ".apk":
              request.response.headers.contentType = ContentType.parse("application/vnd.android.package-archive");
              break;
            default:
              request.response.headers.contentType = ContentType.json;
              break;
          }
          //log(path,StackTrace.current);
          if(extension == ".html" || extension == ".js" || extension == ".css"){
            String data = await rootBundle.loadString("assets$path");
            
            request.response.write(data);
            request.response.close();
          } else if(extension == ".png" || extension == ".jpg" || extension == ".gif"){
            //HTTP SERVER不直接支持 reponse.write 写入二进制数据
            //暂时有两个解决方案 一种是将 assets下的图片读取到/data/data私域目录 然后打开 file stream 再 reponse.addstream输出
            //还有一种是在html和css文件内直接用base64图片编码
            ByteData img = await rootBundle.load("assets$path");
            String dir = (await getApplicationSupportDirectory()).path;
            String privateFilePath = "$dir/assets$path";
            File privateFile  = File(privateFilePath);
            if(!privateFile.existsSync()){
              privateFile.createSync(recursive: true);
              await privateFile.writeAsBytes(img.buffer.asUint8List(img.offsetInBytes, img.lengthInBytes));
            }
            request.response.addStream(privateFile.openRead()).then((value) => request.response.close());
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
