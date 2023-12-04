import 'package:flutter/material.dart';
import 'tabs/send_to_app.dart';
import 'tabs/send_to_browser.dart';
import 'tabs/choose_file.dart';
import './tabs/instruction.dart';
import './tabs/about.dart';
import 'package:woniu/services/client.dart';

import 'package:woniu/common/config.dart';
import 'package:woniu/common/func.dart';
import 'package:woniu/common/global_variable.dart';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _nameState();
}

// ignore: camel_case_types
class _nameState extends State<Tabs> with SingleTickerProviderStateMixin {
  //默认显示的tab index
  int _currentIndex = 0;
  // ignore: non_constant_identifier_names
  Icon _FloatingActionButtonIcon = const Icon(Icons.add, color: Colors.white);
  List<String?>? chooseFiles = [];
  final List<Widget> _pages = [
    SendToApp(),
    SendToBrowser(),
    ChooseFile(),
    Instruction(),
    About()
  ];
  //首页雷达扫描动画
  // ignore: prefer_typing_uninitialized_variables
  var _indexSweepGradient;
  ///////////////

  /////动画控制器
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    //创建
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    //添加到事件队列中
    Future.delayed(Duration.zero, () {
      //动画重复执行
      _animationController.repeat();
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    print('tabs-deactivate');
  }

  @override
  void dispose() {
    //销毁
    _animationController.dispose();
    super.dispose();
    print('tabs-dispose');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            if (index == 2) {
              if (chooseFiles!.isNotEmpty) {
                chooseFiles!.clear();
                _FloatingActionButtonIcon = const Icon(Icons.add, color: Colors.white);
              }
            } else {
              _currentIndex = index;
            }
            //选中其他tab页 停止雷达扫描
            if (index != 0) {
              _indexSweepGradient = null;
            } else {
              _indexSweepGradient = SweepGradient(colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.6),
              ]);
            }

            // ignore: avoid_print
            //print(this);
          });
        },
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
              icon: Icon(Icons.phone_iphone), label: "传客户端"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.open_in_browser), label: "传浏览器"),
          BottomNavigationBarItem(
              icon: const Icon(Icons.file_copy),
              label: chooseFiles!.isNotEmpty ? "清空" : "选择文件"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.open_in_browser), label: "使用说明"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.info_outline), label: "关于")
        ],
      ),
      floatingActionButton: chooseFiles!.isNotEmpty ? 
            Draggable(data: '',
              feedback: const Icon(Icons.file_copy, color: Colors.blue, size: 30),
              onDraggableCanceled: (Velocity velocity, Offset offset) {
                //print(offset);
                //print(remoteDevicesData);
                //判断 offset是否在拖动在设备item上 key为远程设备ipv4地址
                for (String key in remoteDevicesData.keys) {
                  //print(key);
                  //print(remoteDevicesData[key]);
                  //print(remoteDevicesOffset);
                  double top_ = remoteDevicesData[key]!['top'] + remoteDevicesOffset.dy;
                  double left_ = remoteDevicesData[key]!['left'] + remoteDevicesOffset.dx;
                  if(pointInsideRect(offset, top_, left_, remoteDevicesWidgetMaxSizeWidth, remoteDevicesWidgetMaxSizeHeight)){
                    //print(key);
                    sendFileInfo(client, key, httpServerPort, fileList, nav.currentContext);
                    break;
                  }
                }
              },
              onDragCompleted: () {
                print('finished');
              },
              child: Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(5),
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                child: Stack(
                  children: [
                    buildRotationTransition(),
                    IconButton(
                        onPressed: () async {
                          //选择文件
                          // FlutterDocumentPickerParams? params = FlutterDocumentPickerParams();
                          // String? path = await FlutterDocumentPicker.openDocument(
                          //   params: params,
                          // );

                          // setState(() {
                          //   isLoading = true;
                          // });

                          List<String?>? path = await Sender.handleSharing(context);
                          chooseFiles?.addAll(path!);
                          setState(() {
                            //isLoading = false;
                            if (chooseFiles?.length == 1) {
                              _FloatingActionButtonIcon = const Icon(Icons.image, color: Colors.white);
                            } else if ((chooseFiles?.length)! > 1) {
                              _FloatingActionButtonIcon = const Icon(Icons.file_copy, color: Colors.white);
                            } else {
                              _FloatingActionButtonIcon = const Icon(Icons.add, color: Colors.white);
                            }
                          });
                        },
                        icon: _FloatingActionButtonIcon
                    )
                  ],
                )) 
            ) : 
            Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(5),
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                child: Stack(
                  children: [
                    buildRotationTransition(),
                    IconButton(
                        onPressed: () async {
                          //选择文件
                          // FlutterDocumentPickerParams? params = FlutterDocumentPickerParams();
                          // String? path = await FlutterDocumentPicker.openDocument(
                          //   params: params,
                          // );

                          // setState(() {
                          //   isLoading = true;
                          // });

                          List<String?>? path = await Sender.handleSharing(context);
                          chooseFiles?.addAll(path!);
                          setState(() {
                            //isLoading = false;
                            if (chooseFiles?.length == 1) {
                              _FloatingActionButtonIcon = const Icon(Icons.image, color: Colors.white);
                            } else if ((chooseFiles?.length)! > 1) {
                              _FloatingActionButtonIcon = const Icon(Icons.file_copy, color: Colors.white);
                            } else {
                              _FloatingActionButtonIcon = const Icon(Icons.add, color: Colors.white);
                            }
                          });
                        },
                        icon: _FloatingActionButtonIcon
                    )
                  ],
                )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  RotationTransition buildRotationTransition() {
    //旋转动画
    return RotationTransition(
      //动画控制器
      turns: _animationController,
      //圆形裁剪
      child: ClipOval(
        child: FloatingActionButton(
          onPressed: () async {},
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              //扫描渐变
              gradient: _indexSweepGradient,
            ),
          ),
        ),
        //扫描渐变
      ),
    );
  }
}
