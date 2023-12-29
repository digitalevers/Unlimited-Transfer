// ignore_for_file: prefer_interpolation_to_compose_strings
import 'package:flutter/material.dart';
import 'package:woniu/common/func.dart';
import 'package:woniu/common/global_variable.dart';

class SendToBrowser extends StatefulWidget {
  SendToBrowser({super.key}){
    log("send_to_browser页初始化完成");
  }

  @override
  State<SendToBrowser> createState() => _nameState();
}

// ignore: camel_case_types
class _nameState extends State<SendToBrowser> {
  @override
  Widget build(BuildContext context) {
    //log("send_to_browser页渲染完成");
    return Center(
        child: 
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(
                height: 25,
                child: Text("方式一",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18)),
              ),
              SizedBox(
                height: 50,
                child: Text("请在PC浏览器上打开\nhttp://"+deviceInfo['lanIP']+":8888",style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                height: 25,
                child: Text("方式二",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18)),
              ),
              SizedBox(
                height: 100,
                child: Text("请到官网下载\nWindows / MacOS / Linux专属客户端\n" + website,style: const TextStyle(fontSize: 16)),
              )
            ]
          )
    );
  }
}
