// ignore_for_file: prefer_interpolation_to_compose_strings
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:woniu/common/func.dart';
import 'package:woniu/common/global_variable.dart';

class SendToBrowser extends StatefulWidget {
  SendToBrowser({super.key}){
    log("send_to_browser页初始化完成");
  }

  @override
  State<SendToBrowser> createState() => _nameState();
}

// ignore: camel_case_types
class _nameState extends State<SendToBrowser> {
  @override
  Widget build(BuildContext context) {
    //log("send_to_browser页渲染完成");
    return 
      Container(
        color: Colors.blue,
        width: double.infinity,
        height: double.infinity,
        child: Center(
                child: 
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment:CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(
                        height: 30,
                        child: Text("方式一",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.white)),
                      ),
                      SizedBox(
                        height: 80,
                        width: 280,
                        child: 
                          OutlinedButton(
                            style: ButtonStyle(backgroundColor:MaterialStateProperty.all(const Color(0xFFffffff))),
                            onPressed:(){
                              Clipboard.setData(ClipboardData(text: "http://" + deviceInfo['lanIP'] + ":8888")).then((_) => BotToast.showText(text:"已复制"));
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "请在PC浏览器上打开\nhttp://" + deviceInfo['lanIP'] + ":8888",
                                  style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
                                  textAlign: TextAlign.left,
                                )
                              ]
                            )
                          )
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(
                        height: 30,
                        child: Text("方式二",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.white)),
                      ),
                      SizedBox(
                        height: 80,
                        width: 280,
                        child: 
                          OutlinedButton(
                            style: ButtonStyle(backgroundColor:MaterialStateProperty.all(const Color(0xFFffffff))),
                            onPressed:(){
                              Clipboard.setData(ClipboardData(text: website)).then((_) => BotToast.showText(text:"已复制"));
                            },
                            child: 
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "请到官网下载PC专属客户端\n" + website,
                                    style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
                                  )
                                ]
                              )
                          )
                      )
                    ]
                  )
              )
      );
  }
}
