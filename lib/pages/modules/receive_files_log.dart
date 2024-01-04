import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../common/global_variable.dart';
import 'package:path/path.dart' as p;
import 'package:woniu/common/func.dart';

import 'package:open_file/open_file.dart';


//组件单独放在一个文件里则无法访问到 _ReceiveFilesLogState 该类为文件私有
class ReceiveFilesLog extends StatefulWidget {
  const ReceiveFilesLog(Key key):super(key:key);

  @override
  State<ReceiveFilesLog> createState() => _ReceiveFilesLogState();
  
}



// ignore: camel_case_types
class _ReceiveFilesLogState extends State<ReceiveFilesLog> {
  List<Map<String,dynamic>> receviceFilesLog = [];
  final ScrollController _scrollController = ScrollController();  //ListView 滑动控制器

  @override
  void initState() {
    super.initState();
    _initState();

    //界面build完成后执行回调函数
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    // });
  }

  void _initState() async{
    List<String> filesLog = prefs!.getStringList("receviceFilesLog") ?? [];
    //遍历文件是否存在
    for(int i = 0; i < filesLog.length; i++){
      String fileFullPath = jsonDecode(filesLog[i])["fileFullPath"];
      bool fileExist = await File(fileFullPath).exists();
      if(fileExist == false){
        filesLog.removeAt(i);
      }
    }
    // ignore: unnecessary_this
    this.receviceFilesLog = _getBaseName(filesLog);
    await prefs!.setStringList("receviceFilesLog", filesLog);
  }

  @override
  Widget build(BuildContext context) {
    return receviceFilesLog.isEmpty ? receviceFilesLogIsEmpty() : receviceFilesLogNotEmpty();
  }

  Widget receviceFilesLogIsEmpty(){
    return Container(
      color: Colors.blue,
      alignment: Alignment.center,
      child: const Text(
        '接收文件记录',
        style: TextStyle(color: Color(0xffEDF1F2)),
      )
    );
  }

  Widget receviceFilesLogNotEmpty(){
    return 
      Scrollbar(
        child: 
          ListView.separated(
            controller: _scrollController,
            padding:const EdgeInsets.all(5),
            reverse: false,
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(height: 5);
            },
            itemCount: receviceFilesLog.length,
            itemBuilder: (BuildContext context, int index) {
              return
                Container(
                  color: index == receviceFilesLog.length - 1 ? const Color(0xffFC6621) : const Color(0xffFF9E3D),
                  child: 
                    ListTile(
                      //contentPadding: const EdgeInsets.all(5),
                      //tileColor: const Color(0xffFF9E3D),
                      //selectedTileColor:const Color(0xff1122dd),
                      iconColor:const Color(0xffFFFFFF),
                      textColor:const Color(0xffFFFFFF),
                      //selectedColor:const Color(0xff1122dd),
                      //focusColor:Color.fromARGB(255, 197, 30, 30),
                      //hoverColor:Color.fromARGB(255, 185, 28, 216),
                      //splashColor: Color.fromARGB(255, 62, 204, 44),

                      isThreeLine: false,
                      title: Text(getShortFileName(p.basename(receviceFilesLog[index]["fileFullPath"]!),15)),
                      subtitle: Text("From ${receviceFilesLog[index]["from"]!}\nDate ${receviceFilesLog[index]["date"]!}",style: const TextStyle(fontSize:10.0,color: Color.fromARGB(255, 250, 250, 250))),
                      trailing: SizedBox(
                        width: 120,
                        child: Row(
                          children: [
                            InkWell(
                            onTap: () async {
                              //call your onpressed function here
                              if(Platform.isAndroid){
                                const platform = MethodChannel("AndroidApi");
                                bool openResult = await platform.invokeMethod("openDir",["/Download"]);
                              } else {
                                //TODO 预留iOS打开指定文件夹
                              }
                            },
                            child: const Icon(Icons.drive_file_move_rounded),
                            ),
                            const SizedBox(width: 20),
                            InkWell(
                            onTap: () {
                              //call your onpressed function here
                              OpenFile.open(receviceFilesLog[index]["fileFullPath"]!).then(
                                (value) => 
                                log(value.message,StackTrace.current)
                              );
                            },
                            child: const Icon(Icons.file_open),
                            ),
                            const SizedBox(width: 20),
                            InkWell(
                              onTap: () {
                                // ignore: unnecessary_this
                                this.delFilesLog(receviceFilesLog[index]["fileFullPath"]);
                              },
                              child: const Icon(Icons.delete),
                            ),
                          ],
                      )
                      )
                    )
                  );
            },
          )
      );
  }

  void insertFilesLog(String fileInfoJson) async {
    List<String>? filesLog = prefs!.getStringList("receviceFilesLog") ?? [];
    filesLog.add(fileInfoJson);
    //遍历文件是否存在
    for(int i = 0; i < filesLog.length; i++){
      String fileFullPath = jsonDecode(filesLog[i])["fileFullPath"];
      bool fileExist = await File(fileFullPath).exists();
      if(fileExist == false){
        filesLog.removeAt(i);
      }
    }
    await prefs!.setStringList("receviceFilesLog", filesLog);
    // ignore: unnecessary_this
    this.receviceFilesLog = _getBaseName(filesLog);
    setState(() {});
    // 延迟500毫秒，再进行滑动
    Future.delayed(Duration(milliseconds: 500), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void delFilesLog(String filePath) async{
    File file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
    } else {
      log("文件不存在",StackTrace.current);
    }
    //遍历文件是否存在
    List<String>? filesLog = prefs!.getStringList("receviceFilesLog") ?? [];
    for(int i = 0; i < filesLog.length; i++){
      String fileFullPath = jsonDecode(filesLog[i])["fileFullPath"];
      bool fileExist = File(filesLog[i]).existsSync();
      if(fileExist == false || fileFullPath == filePath){
        filesLog.removeAt(i);
      }
    }
    await prefs!.setStringList("receviceFilesLog", filesLog);
    // ignore: unnecessary_this
    this.receviceFilesLog = _getBaseName(filesLog);
    setState(() {});
  }

  void selectFilesLog() async{
    List<String>? filesLog = prefs!.getStringList("receviceFilesLog") ?? [];
    //遍历文件是否存在
    for(int i = 0; i < filesLog.length; i++){
      String fileFullPath = jsonDecode(filesLog[i])["fileFullPath"];
      bool fileExist = await File(fileFullPath).exists();
      if(fileExist == false){
        filesLog.removeAt(i);
      }
    }
    
    await prefs!.setStringList("receviceFilesLog", filesLog);
    // ignore: unnecessary_this
    this.receviceFilesLog = _getBaseName(filesLog);
    setState(() {});
  }

  List<Map<String,dynamic>> _getBaseName(List<String> filesLog){
    List<Map<String,dynamic>> baseNameFilesLog = [];
    for(int i = 0; i < filesLog.length; i++){
      Map<String,dynamic> fileInfoMap = jsonDecode(filesLog[i]);
      fileInfoMap["fileFullPath"] = fileInfoMap["fileFullPath"];
      baseNameFilesLog.add(fileInfoMap);
      //baseNameFilesLog.add(filesLog[i]);
    }
    return baseNameFilesLog;
  }
}