import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuotu/pages/modules/privacy_page.dart';
import 'tabs/send_to_app.dart';
import 'tabs/send_to_browser.dart';
import 'tabs/choose_file.dart';
import './tabs/instruction.dart';
import './tabs/about.dart';
import 'package:tuotu/services/client.dart';

import 'package:tuotu/common/config.dart';
import 'package:tuotu/common/func.dart';
import 'package:tuotu/common/global_variable.dart';
import 'package:showcaseview/showcaseview.dart';


class Tabs extends StatefulWidget {
  //final GlobalKey tabsKey;
  const Tabs({super.key});

  @override
  State<Tabs> createState()  { 
    return  _nameState(); 
  }
}

// ignore: camel_case_types
class _nameState extends State<Tabs> with SingleTickerProviderStateMixin {
  //默认显示的tab index
  int _currentIndex = 0;
  // ignore: non_constant_identifier_names
  Icon _FloatingActionButtonIcon = const Icon(Icons.add, color: Colors.white);
  List<Map<String,String>> chooseFiles = [];
  String showShortFileName = '';
  final List<Widget> _pages = [
    SendToApp(GlobalKey()),
    SendToBrowser(),
    ChooseFile(),
    Instruction(),
    About()
  ];
  //首页雷达扫描动画
  // ignore: prefer_typing_uninitialized_variables
  SweepGradient? _indexSweepGradient;
  ///////////////

  /////动画控制器
  AnimationController? _animationController;

  //新手引导蒙层
  final GlobalKey _one = GlobalKey();

  late BuildContext myContext;


  @override
  void initState() {
    super.initState();
    //创建
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    //添加到事件队列中
    Future.delayed(Duration.zero, () {_animationController?.repeat();});
    //TODO 报 myContext not initial
    // if(myContext != null){
    //   log(1111,StackTrace.current);
    //   WidgetsBinding.instance.addPostFrameCallback((_) =>
    //     ShowCaseWidget.of(myContext).startShowCase([_one])
    //   );
    // }
  }

  @override
  void deactivate() {
    super.deactivate();
    print('tabs-deactivate');
  }

  @override
  void dispose() {
    //销毁
    _animationController?.dispose();
    super.dispose();
    print('tabs-dispose');
  }

  @override
  Widget build(BuildContext context){
    bool allowPrivacy = prefs?.getBool("allowPrivacy") ?? false;
    if(allowPrivacy){
      //置于initState中只会执行一次
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            ShowCaseWidget.of(myContext).startShowCase([_one]);
          });
        }
      );

      return ShowCaseWidget(
        builder: Builder(
          builder: (context) {
            myContext = context;
            return Scaffold(
              body: _pages[_currentIndex],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                onTap: (index) {
                  setState(() {
                    if (index == 2) {
                      if (chooseFiles.isNotEmpty) {
                        chooseFiles.clear();
                        _FloatingActionButtonIcon = const Icon(Icons.add, color: Colors.white);
                      }
                    } else {
                      _currentIndex = index;
                    }
                    //选中其他tab页 停止雷达扫描
                    // if (index != 0) {
                    //   _indexSweepGradient = null;
                    // } else {
                    //   _indexSweepGradient = SweepGradient(colors: [
                    //     Colors.white.withOpacity(0.2),
                    //     Colors.white.withOpacity(0.6),
                    //   ]);
                    // }
                    //2023-12-23关闭扫描动画
                    _indexSweepGradient = null;
                  });
                },
                items: <BottomNavigationBarItem>[
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.phone_iphone), label: "传APP"),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.open_in_browser), label: "传电脑"),
                  BottomNavigationBarItem(
                      icon: const Icon(Icons.add),
                      label: chooseFiles.isNotEmpty ? "点我清空" : "选择文件"),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.library_books), label: "使用说明"),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.info_outline), label: "关于")
                ],
              ),
              //新手引导蒙层只在app安装时提示一次
              floatingActionButton: newerShowOneTime(),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            );
          })
      );
    } else {
      return const PrivacyPage();
    } 
  }


  /// 新手引导蒙层只显示一次
  Widget newerShowOneTime(){
      bool newer = prefs?.getBool("newer") ?? true;
      if(newer){
        prefs?.setBool("newer", false);
        return Showcase(
                  key: _one,
                  title:'点击选择文件(长按文件可多选)',
                  description: '然后将文件拖拽至目标设备上',
                  targetShapeBorder: const CircleBorder(),
                  child:getFloatingActionButton()
              );
      } else {
        return getFloatingActionButton();
      }
  }


  //获取 floatingActionButton 位置的控件
  Widget getFloatingActionButton(){
    return chooseFiles.isNotEmpty ? 
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
                  //log(remoteDevicesData[key]!['top'],StackTrace.current);
                  //log(remoteDevicesOffset.dy,StackTrace.current);
                  if(pointInsideRect(offset, top_, left_, remoteDevicesWidgetMaxSizeWidth, remoteDevicesWidgetMaxSizeHeight)){
                    BotToast.showText(text:"等待对方接收");
                    sendFileInfo(client, key, httpServerPort, fileList, myContext);
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
                padding: const EdgeInsets.all(0),
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    buildRotationTransition(),
                    Container(margin: const EdgeInsets.only(bottom: 5), 
                              child: 
                                IconButton(
                                  alignment: Alignment.topCenter,
                                  onPressed: () async {
                                    //选择文件
                                    chooseFiles = [];
                                    List<Map<String,String>> path = await Sender.share(context);
                                    chooseFiles.addAll(path);
                                    if(chooseFiles.isNotEmpty){
                                      showShortFileName = getShortFileName(chooseFiles[0]["originUri"]!);
                                      setState(() {
                                        //isLoading = false;
                                        // ignore: prefer_is_empty
                                        if ((chooseFiles.length) > 0) {
                                          _FloatingActionButtonIcon = const Icon(Icons.file_copy, color: Colors.white);
                                        } else {
                                          _FloatingActionButtonIcon = const Icon(Icons.add, color: Colors.white);
                                        }
                                      });
                                    }
                                  },
                                  icon: _FloatingActionButtonIcon
                              ),
                    ),
                    Container(margin: const EdgeInsets.only(bottom: 5), 
                              child: 
                                Text(showShortFileName,textAlign:TextAlign.center,style:const TextStyle(fontSize:10,color:Colors.white))
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
                  alignment: Alignment.center,
                  children: [
                    buildRotationTransition(),
                    IconButton(
                        onPressed: () async {
                          try{
                            //选择文件
                            List<Map<String,String>> path = await Sender.share(context);
                            //log(path,StackTrace.current);
                            chooseFiles.addAll(path);
                            setState(() {
                              //isLoading = false;
                              // ignore: prefer_is_empty
                              if ((chooseFiles.length) > 0) {
                                _FloatingActionButtonIcon = const Icon(Icons.file_copy, color: Colors.white);
                              } else {
                                _FloatingActionButtonIcon = const Icon(Icons.add, color: Colors.white);
                              }
                            });
                          } catch(e){
                            if(e.runtimeType.toString() == "PlatformException"){
                              BotToast.showText(text:"请到设置的授权管理手动授权，否则无法使用哦~");
                            }
                          }
                        },
                        icon: _FloatingActionButtonIcon
                    ),
                    
                  ],
                ));
  }

  RotationTransition buildRotationTransition() {
    //旋转动画
    return RotationTransition(
      //动画控制器
      turns: _animationController!,
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
