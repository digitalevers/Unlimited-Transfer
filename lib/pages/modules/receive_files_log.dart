import 'dart:io';

import 'package:flutter/material.dart';
import '../../common/global_variable.dart';


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
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: receviceFilesLog.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
            title: Text(receviceFilesLog[index]),
        );
      },
    );
  }


  void insertFilesLog(String filePath) async {
    List<String>? log = prefs!.getStringList("receviceFilesLog") ?? [];
    log.add(filePath);
    //遍历文件是否存在
    for(int i = 0; i < log.length; i++){
      bool fileExist = await File(log[i]).exists();
      if(fileExist == false){
        log.removeAt(i);
      }
    }
    receviceFilesLog = log;
    await prefs!.setStringList("receviceFilesLog", log);
    setState(() {});
  }

  void delFilesLog(String filePath) async{
    List<String>? log = prefs!.getStringList("receviceFilesLog") ?? [];
    log.remove(filePath);
    //遍历文件是否存在
    for(int i = 0; i < log.length; i++){
      bool fileExist = await File(log[i]).exists();
      if(fileExist == false){
        log.removeAt(i);
      }
    }
    receviceFilesLog = log;
    await prefs!.setStringList("receviceFilesLog", log);
    setState(() {});
  }

  void selectFilesLog() async{
    List<String>? log = prefs!.getStringList("receviceFilesLog") ?? [];
    //遍历文件是否存在
    for(int i = 0; i < log.length; i++){
      bool fileExist = await File(log[i]).exists();
      if(fileExist == false){
        log.removeAt(i);
      }
    }
    receviceFilesLog = log;
    await prefs!.setStringList("receviceFilesLog", log);
    setState(() {});
  }
}