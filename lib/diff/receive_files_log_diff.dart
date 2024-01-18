//各平台界面差异化
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';
import 'package:open_dir/open_dir.dart';

import 'package:woniu/common/func.dart';

List<Widget> diffGetButtons(List<Map<String,dynamic>> receviceFilesLog, int index, Function delAction){
  //仅PC可以打开文件夹
  if(Platform.isWindows || Platform.isLinux || Platform.isMacOS){
    return [
          InkWell(
            onTap: () async {
              final rs = await OpenDir().openNativeDir(path: p.dirname(receviceFilesLog[index]["fileFullPath"]!));
              //log(rs,StackTrace.current);
            },
            child: const Icon(Icons.drive_file_move_rounded),
          ),
          const SizedBox(width: 20),
          InkWell(
            onTap: () {
              OpenFile.open(receviceFilesLog[index]["fileFullPath"]!).then(
                (value){
                  //log(value.message,StackTrace.current);
                } 
              ); 
            },
            child: const Icon(Icons.file_open),
          ),
          const SizedBox(width: 20),
          InkWell(
            onTap: () {
              // ignore: unnecessary_this
              delAction(receviceFilesLog[index]["fileFullPath"]);
            },
            child: const Icon(Icons.delete),
          ),
        ];
  } else {
    return [
      // InkWell(
      //   onTap: () async {
      //     //call your onpressed function here
      //     if(Platform.isAndroid){
      //       const platform = MethodChannel("AndroidApi");
      //       bool openResult = await platform.invokeMethod("openDir",["/Download"]);
      //     } else {
      //       //TODO 预留iOS打开指定文件夹
      //     }
      //   },
      //   child: const Icon(Icons.drive_file_move_rounded),
      // ),
      const SizedBox(width: 20),
      InkWell(
        onTap: () {
          Permission.manageExternalStorage.request().then((value){
            if(value == PermissionStatus.granted){
              //检测是否为apk文件
              if(p.extension(receviceFilesLog[index]["fileFullPath"]) == '.apk'){
                log("这是apk",StackTrace.current);
                Permission.requestInstallPackages.request().then((value){
                  if(value == PermissionStatus.granted){
                    OpenFile.open(receviceFilesLog[index]["fileFullPath"]!).then(
                      (value){
                        //log(value.message,StackTrace.current);
                      } 
                    ); 
                  }
                });
              } else {
                OpenFile.open(receviceFilesLog[index]["fileFullPath"]!).then(
                  (value){
                    //log(value.message,StackTrace.current);
                  } 
                ); 
              }
            }
          });
        },
        child: const Icon(Icons.file_open),
      ),
      const SizedBox(width: 20),
      InkWell(
        onTap: () {
          // ignore: unnecessary_this
          delAction(receviceFilesLog[index]["fileFullPath"]);
        },
        child: const Icon(Icons.delete),
      ),
    ];
  }
  
}


