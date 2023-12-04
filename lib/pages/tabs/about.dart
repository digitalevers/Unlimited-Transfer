import 'package:flutter/material.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _nameState();
}

class _nameState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Text("关于"),
    );
  }
}
