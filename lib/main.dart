import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:woniu/pages/modules/privacy_page.dart';
import 'package:woniu/services/fileManager.dart';
import 'pages/tabs.dart';

import 'common/config.dart';
import 'common/func.dart';
import 'common/global_variable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bot_toast/bot_toast.dart';



// 重写HttpOverrides
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    var http = super.createHttpClient(context);
    http.findProxy = (uri) {
      return 'PROXY $PROXY';    //设置代理必须使用局域网地址 localhost或127.0.0.1不行
    };
    http.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return http;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  //这一行很重要且必须放在第一行 放在 SharedPreferences 前面 否则运行会报错 暂不知原因
  prefs = await SharedPreferences.getInstance();
  Hive.init((await getApplicationDocumentsDirectory()).path);
  if(useProxy){
    HttpOverrides.global = MyHttpOverrides(); // 使用自己的HttpOverrides
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    log("启动MyApp");
    return MaterialApp(
      navigatorKey: nav,
      title: '无界闪传',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'A Crossplatform File Transfer Tool'),
      builder: BotToastInit(),  //bot_toast
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    log("启动Main页面");
    return const Tabs();
  }
}
