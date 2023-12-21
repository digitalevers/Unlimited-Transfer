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
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: receviceFilesLog.length,
      itemBuilder: (BuildContext context, int index) {
        return 
          // ListTile(
          //   tileColor:Colors.grey,
          //   selectedColor:Colors.grey,
          //   textColor:Colors.white,
          //   //isThreeLine: true,    //子item的是否为三行
          //   dense: false,
          //   //leading: const CircleAvatar(),//左侧首字母图标显示，不显示则传null
          //   title: Text(receviceFilesLog[index]),//子item的标题
          //   //subtitle:  const Text('123'),//子item的内容
          //   // trailing:  SizedBox(
          //   //   //height: 100,
          //   //   width: 200,
          //   //   child: Row(
          //   //       children: [
          //   //         ElevatedButton(onPressed: (){}, child: const Text("打开")),
          //   //         TextButton(onPressed: (){}, child: const Text("删除"))
          //   //       ]
          //   //   )
          //   // ),//显示右侧的箭头，不显示则传null
          // );

          ListTile(
              title: Text('Your Title'),
              subtitle: Text('Your Sub Title'),
              trailing: Column(
                children: [
                    InkWell(
                    onTap: () {
                      //call your onpressed function here
                      print('Button Pressed');
                    },
                    child: Icon(Icons.edit),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  InkWell(
                    onTap: () {
                      //call your onpressed function here
                      print('Button Pressed');
                    },
                    child: Icon(Icons.delete),
                  ),
                ],
              ),
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
      } else {
        filesLog[i] = p.basename(filesLog[i]);
      }
    }
    receviceFilesLog = filesLog;
    log(receviceFilesLog.length);
    await prefs!.setStringList("receviceFilesLog", filesLog);
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
      } else {
        log[i] = p.basename(log[i]);
      }
    }
    receviceFilesLog = log;
    await prefs!.setStringList("receviceFilesLog", log);
    setState(() {});
  }
}