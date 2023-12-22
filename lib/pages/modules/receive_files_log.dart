import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../common/global_variable.dart';
import 'package:path/path.dart' as p;
import 'package:woniu/common/func.dart';


//组件单独放在一个文件里则无法访问到 _ReceiveFilesLogState 该类为文件私有
class ReceiveFilesLog extends StatefulWidget {
  const ReceiveFilesLog(Key key):super(key:key);

  @override
  State<ReceiveFilesLog> createState() => _ReceiveFilesLogState();

}

// ignore: camel_case_types
class _ReceiveFilesLogState extends State<ReceiveFilesLog> {
  List<String> receviceFilesLog = [];

  @override
  void initState() {
    super.initState();
    _initState();
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
    return ListView.builder(
      itemCount: receviceFilesLog.length,
      itemBuilder: (BuildContext context, int index) {
        return
          Container(
            color: const Color(0xffFF9E3D),
            child: ListTile(
              //tileColor: const Color(0xffFF9E3D),
              //selectedTileColor:const Color(0xff1122dd),
              iconColor:const Color(0xffFFFFFF),
              textColor:const Color(0xffFFFFFF),
              //selectedColor:const Color(0xff1122dd),
              //focusColor:Color.fromARGB(255, 197, 30, 30),
              //hoverColor:Color.fromARGB(255, 185, 28, 216),
              //splashColor: Color.fromARGB(255, 62, 204, 44),
              title: Text(receviceFilesLog[index]),
              subtitle: Text("From"),
              trailing: SizedBox(
                width: 100,
                child: Row(
                  children: [
                      InkWell(
                      onTap: () {
                        //call your onpressed function here
                        print('Button Pressed');
                      },
                      child: const Icon(Icons.file_open),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () {
                        //call your onpressed function here
                        print('Delete Pressed');
                      },
                      child: Icon(Icons.delete),
                    ),
                  ],
              )
              )
            )
            );
      },
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