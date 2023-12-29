import 'package:flutter/material.dart';
import 'package:woniu/common/func.dart';

class SendToBrowser extends StatefulWidget {
  SendToBrowser({super.key}){
    log("send_to_browser页初始化完成");
  }

  @override
  State<SendToBrowser> createState() => _nameState();
}

class _nameState extends State<SendToBrowser> {
  @override
  Widget build(BuildContext context) {
    //log("send_to_browser页渲染完成");
    return SizedBox(
      child: Center(
        child: Text("请在PC浏览器上打开：\nhttp://172.16.28.133:8888/"),
      ),
    );
  }
}
