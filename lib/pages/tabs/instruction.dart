import 'package:flutter/material.dart';
import 'package:woniu/common/func.dart';

class Instruction extends StatefulWidget {
  Instruction({super.key}){
    log("instructions页初始化完成");
  }

  @override
  State<Instruction> createState() => _nameState();
}

class _nameState extends State<Instruction> {
  @override
  Widget build(BuildContext context) {
    log("instruction页渲染完成");
    return Container(
      child: const Text("使用说明"),
    );
  }
}
