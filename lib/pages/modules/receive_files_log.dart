import 'package:flutter/material.dart';
import 'package:woniu/common/func.dart';

class ReceiveFilesLog extends StatefulWidget {
  final GlobalKey _key;
  const ReceiveFilesLog(this._key):super(key:_key);

  @override
  State<ReceiveFilesLog> createState() => ReceiveFilesLogState();

}

// ignore: camel_case_types
class ReceiveFilesLogState extends State<ReceiveFilesLog> {
  List<ListTile> ls = const [
        ListTile(
            title: Text("HI"),
        ),
        ListTile(
            title: Text("HI"),
        ),
        ListTile(
            title: Text("HI"),
        )
      ];

  

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: ls
    );
  }

  void test111() {
    
  }

  
}
