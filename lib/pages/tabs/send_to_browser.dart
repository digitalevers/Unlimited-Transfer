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
    log("send_to_browser页渲染完成");
    return Container(
      child: const Text("浏览器"),
    );
  }
}
