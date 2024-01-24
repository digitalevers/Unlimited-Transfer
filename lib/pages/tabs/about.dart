import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/routes/default_transitions.dart';
import 'package:tuotu/common/func.dart';

class About extends StatefulWidget {
  About({super.key}){
    log("about页初始化完成");
  }

  @override
  State<About> createState() => _nameState();
}

class _nameState extends State<About> {
  @override
  Widget build(BuildContext context) {
    //log("about页渲染完成");
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Padding(
        padding:const EdgeInsets.fromLTRB(20, 50, 20, 20),
        child: Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children: const <Widget>[
            SizedBox(
              child: Text("脱兔闪传",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18)),
            ),
            SizedBox(height: 5),
            SizedBox(
              child: Text("是一款跨平台的文件传输工具\n可在任意平台之间无缝传输文件(和消息)\n操作方便快捷",style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            SizedBox(
              child: Text("支持",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18)),
            ),
            SizedBox(height: 5),
            SizedBox(
              child: Text("Android / iOS / Windows / Linux / MacOS",style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            SizedBox(
              child: Text("未来计划",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18)),
            ),
            SizedBox(height: 5),
            SizedBox(
              child: Text("目前暂只支持Android\n后续会更新至全平台支持\n后续会添加消息发送功能",style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 40),
            SizedBox(
              child: Text("社群",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.blue)),
            ),
            SizedBox(height: 5),
            SizedBox(
              child: Text("微信 digitalevers\n邮箱 sc@digitalevers.com\n官网 https://sc.digitalevers.com",style: TextStyle(fontSize: 16)),
            ),
          ],
        )
      )
      
      );
  }
}
