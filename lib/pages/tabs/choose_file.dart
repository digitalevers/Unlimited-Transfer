import 'package:flutter/material.dart';
import 'package:woniu/common/func.dart';

class ChooseFile extends StatefulWidget {
  ChooseFile({super.key}){
    log("choose_file页初始化完成");
  }

  @override
  State<ChooseFile> createState() => _nameState();
}

class _nameState extends State<ChooseFile> {
  @override
  Widget build(BuildContext context) {
    log("choose_file页渲染完成");
    return Container(
      child: const Text(""),
    );
  }
}
