import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
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
  List<String> receviceFilesLog = [];
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
      bool fileExist = await File(filesLog[i]).exists();
      if(fileExist == false){
        filesLog.removeAt(i);
      }
    }
    receviceFilesLog = _getBaseName(filesLog);
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
                      title: Text(getShortFileName(p.basename(receviceFilesLog[index]),15)),
                      subtitle: Text("From 172.16.28.133\nDate 2023-12-13 16:47",style: TextStyle(fontSize:10.0,color: Color.fromARGB(255, 250, 250, 250))),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                              InkWell(
                              onTap: () {
                                //call your onpressed function here
                                OpenFile.open(receviceFilesLog[index]).then((value) => 
                                  log(value.message,StackTrace.current)
                                );
                              },
                              child: const Icon(Icons.file_open),
                            ),
                            const SizedBox(width: 20),
                            InkWell(
                              onTap: () {
                                //call your onpressed function here
                                print('Delete Pressed');
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

  void insertFilesLog(String filePath) async {
    List<String>? filesLog = prefs!.getStringList("receviceFilesLog") ?? [];
    filesLog.add(filePath);
    //遍历文件是否存在
    for(int i = 0; i < filesLog.length; i++){
      bool fileExist = await File(filesLog[i]).exists();
      if(fileExist == false){
        filesLog.removeAt(i);
      }
    }
    receviceFilesLog = _getBaseName(filesLog);
    await prefs!.setStringList("receviceFilesLog", filesLog);
    setState(() {});
    // 延迟500毫秒，再进行滑动
    Future.delayed(Duration(milliseconds: 500), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void delFilesLog(String filePath) async{
    List<String>? filesLog = prefs!.getStringList("receviceFilesLog") ?? [];
    filesLog.remove(filePath);
    //遍历文件是否存在
    for(int i = 0; i < filesLog.length; i++){
      bool fileExist = await File(filesLog[i]).exists();
      if(fileExist == false){
        filesLog.removeAt(i);
      }
    }
    receviceFilesLog = _getBaseName(filesLog);
    await prefs!.setStringList("receviceFilesLog", filesLog);
    setState(() {});
  }

  void selectFilesLog() async{
    List<String>? filesLog = prefs!.getStringList("receviceFilesLog") ?? [];
    //遍历文件是否存在
    for(int i = 0; i < filesLog.length; i++){
      bool fileExist = await File(filesLog[i]).exists();
      if(fileExist == false){
        filesLog.removeAt(i);
      }
    }
    receviceFilesLog = _getBaseName(filesLog);
    await prefs!.setStringList("receviceFilesLog", filesLog);
    setState(() {});
  }

  List<String> _getBaseName(List<String> filesLog){
    List<String> baseNameFilesLog = [];
    for(int i = 0; i < filesLog.length; i++){
        //baseNameFilesLog.add(p.basename(filesLog[i]));
        baseNameFilesLog.add(filesLog[i]);
    }
    return baseNameFilesLog;
  }
}