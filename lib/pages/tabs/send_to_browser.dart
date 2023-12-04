import 'package:flutter/material.dart';

class SendToBrowser extends StatefulWidget {
  const SendToBrowser({super.key});

  @override
  State<SendToBrowser> createState() => _nameState();
}

class _nameState extends State<SendToBrowser> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Text("浏览器"),
    );
  }
}
