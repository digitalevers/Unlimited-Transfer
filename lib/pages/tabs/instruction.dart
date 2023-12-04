import 'package:flutter/material.dart';

class Instruction extends StatefulWidget {
  const Instruction({super.key});

  @override
  State<Instruction> createState() => _nameState();
}

class _nameState extends State<Instruction> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Text("使用说明"),
    );
  }
}
