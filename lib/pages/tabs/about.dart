import 'package:flutter/material.dart';
import 'package:woniu/common/func.dart';

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
    log("about页渲染完成");
    return Container(
      child: const Text("关于"),
    );
  }
}
