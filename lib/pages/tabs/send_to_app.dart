import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
//import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:woniu/api/device_info_api.dart';
import 'package:woniu/common/func.dart';
import 'package:woniu/pages/modules/water_ripple.dart';
import 'package:woniu/services/server.dart';

import 'package:woniu/common/config.dart';
import 'package:woniu/common/global_variable.dart';

import 'package:woniu/pages/modules/receive_files_log.dart';
import 'package:woniu/pages/modules/step_progress.dart';

class SendToApp extends StatefulWidget {
  final GlobalKey _key;
  SendToApp(this._key):super(key:_key);

  @override
  State<SendToApp> createState() => _SendToAppState(_key);
}

class _SendToAppState extends State<SendToApp> with SingleTickerProviderStateMixin {
  final GlobalKey _key;
  _SendToAppState(this._key);
  //UDP socket
  RawDatagramSocket? socket;
  Timer? timer;
  //UDP 启动锁确保只启动一次
  bool startUDPLock = false;
  //当前页面的 globalKey
  final GlobalKey sendToAppBodyKey = GlobalKey();
  //远程设备显示区的globalkey
  final GlobalKey remoteDeviceShowFlexible = GlobalKey();
  //接收文件记录显示区的globalkey
  final GlobalKey receiveFilesLogKey = GlobalKey();
  //远程设备显示区的size
  Size? remoteDeviceShowFlexibleSize;

  //水波纹动画Widget
  static const SizedBox _waterRipple = SizedBox(height:double.infinity, width:double.infinity, child:WaterRipple(count: 5));
  // static DragTarget dt = DragTarget(onAccept: (data) {
  //               ;
  //             }, builder: (context,candidateData,rejectData){
  //               return Text(
  //                 'abc',
  //                 style: Theme.of(context).textTheme.headlineMedium,
  //               );
  //             });

  //远程设备的显示widget
  List<Widget> remoteDevicesWidget = <Widget>[];
  //远程设备的显示widget + 水波纹动画(初始化的时候仅有水波纹动画)
  List<Widget> remoteDevicesWidgetPlus = <Widget>[_waterRipple];
  //List<Widget> remoteDevicesWidgetPlus = <Widget>[dt];
  //远程设备的显示widget 的最大尺寸
  Size remoteDevicesWidgetMaxSize = Size(remoteDevicesWidgetMaxSizeWidth, remoteDevicesWidgetMaxSizeHeight);
  //如果显示widget重叠了 尝试重新生成widget的次数
  int createWidgetCount = 2;
  //本地设备和网络信息
  //deviceInfo = {'model': '', 'lanIP': '', 'networkText': '', 'deviceType': ''};

  //动画控制器
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    ////////////////创建动画
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    //添加到事件队列中
    Future.delayed(Duration.zero, () {
      //动画重复执行
      _animationController.repeat();
    });

    initEnv();
    
    //界面build完成后执行回调函数
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RenderBox renderBox = remoteDevicesKey.currentContext?.findRenderObject() as RenderBox;
      remoteDevicesOffset = renderBox.localToGlobal(Offset.zero);
      //print(positionRed);
      
    });
  }

  Future<void> initEnv() async {
    deviceInfo = await initGetInfo(listenConnectivityChanged);
    if (deviceInfo['network']['type'] == 'nowifi') {
      deviceInfo['networkText'] = '未接入WiFi';
    } else {
      deviceInfo['networkText'] = deviceInfo['network']['wifiName'];
    }
    if (deviceInfo['lanIP'].isEmpty) {
      deviceInfo['lanIP'] = "无法获取ip";
    }
    if (deviceInfo['network']['type'] == 'wifi' && deviceInfo['lanIP'].isNotEmpty) {
      startUDP();
    }
    //启动HTTP SERVER并传入key 便于在server类中获取context
    await Server.startServer(sendToAppBodyKey,receiveFilesLogKey);

    // setState(() {
    //     deviceInfo = deviceInfo_;
    // });
  }

  @override
  //页面隐藏触发
  void dispose() {
    _animationController.dispose();
    super.dispose();
    log('sendtoapp==dispose');
  }

  @override
  void deactivate() {
    super.deactivate();
    log('sendtoapp==deactivate');
  }

  // ignore: slash_for_doc_comments
  /**
   * 监听网络类型的改变
   * 改变ip和wifi接入情况
   */
  Future<void> listenConnectivityChanged(ConnectivityResult result) async {
    Map result_ = await DeviceInfoApi.parseNetworkInfoResult(result);
    String networkText, lanIP;
    if (result_['type'] == 'nowifi') {
      networkText = '未接入WiFi';
    } else {
      networkText = result_['wifiName'];
    }

    //由移动网络切换到WiFi下继续启动UDP广播
    lanIP = await DeviceInfoApi.getDeviceLocalIP();
    if (result_['type'] == 'wifi' && lanIP.isNotEmpty) {
      startUDP();
    } else {
      //由WiFi切换到移动网络下关闭UDP广播
      stopUDP();
    }
    //print(lanIP);
    setState(() {
      deviceInfo['networkText'] = networkText;
      deviceInfo['lanIP'] = lanIP;
    });
  }

  //从SharedPreferences中读取接收文件记录
  List<String>? getReceiveFilesLog(){
    return prefs!.getStringList("key");
  }

  //根据remote deviceType显示不同的系统icon(android ios windows)
  IconData getRemoteDeviceTypeIcon(String? deviceType){
    switch(deviceType){
      case 'linux':
        return Icons.computer;
      case 'macos':
        return Icons.laptop_mac;
      case 'windows':
        return Icons.window_sharp;
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'fuchsia':
        return Icons.computer;
      default:
        return Icons.question_mark_sharp;
    }
  }

  //将远程设备的item添加到显示区内
  void addRemoteDeviceToWidget(Map<String, dynamic> map) {
    remoteDeviceShowFlexibleSize ??= remoteDeviceShowFlexible.currentContext?.size;
    map['remoteDeviceWidgetKey'] = GlobalKey<State<StepProgress>>();
    //约束在 district范围内随机生成top和left值 并尽可能不与之前的矩阵重叠
    double top_ = 0.0;
    double left_ = 0.0;
    for (int i = 0; i < createWidgetCount; i++) {
      //top > 10 以免紧贴窗口边缘渲染widget
      top_ = randomInt(10,(remoteDeviceShowFlexibleSize!.height - 2 * remoteDevicesWidgetMaxSize.height).toInt()).toDouble();
      left_ = randomInt(10,(remoteDeviceShowFlexibleSize!.width - remoteDevicesWidgetMaxSize.width).toInt()).toDouble();
      bool inside = false;
      remoteDevicesData.forEach((key, value) {
        if (rectInRect(Rectangle(left_, top_, remoteDevicesWidgetMaxSize.width, remoteDevicesWidgetMaxSize.height) as Rect,
            Rectangle(value['left'].toInt() as int, value['top'].toInt() as int, remoteDevicesWidgetMaxSize.width, remoteDevicesWidgetMaxSize.height) as Rect)) {
          inside = true;
        }
      });
      if (inside == false) {
        break;
      }
    }
    //print(top_);
    //print(left_);
    map['top'] = top_;
    map['left'] = left_;
    map['transferProgess'] = 0;
    //交由全局变量把控
    remoteDevicesData[map['lanIP']] = map;
    //log(remoteDevicesData,StackTrace.current);
    //使用Dragtarget包裹 Positioned 报错. 但将 Positioned 改为 Container.则不再报错 but why?
    // Widget remoteDeviceWidget = Container(
    //   child: const Text("avbc",style: TextStyle(fontSize: 80),),
    // );
    Widget remoteDeviceWidget = Positioned(
        top: top_,
        left: left_,
        //key: map['remoteDeviceWidgetKey'],
        child: Container(
            constraints: BoxConstraints( maxWidth: remoteDevicesWidgetMaxSize.width, maxHeight: remoteDevicesWidgetMaxSize.height),
            //padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 126, 90),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(children: [
               Positioned(
                left: 0,
                top: 0,
                child: 
                  // StepProgressIndicator(
                  //   fallbackLength: 120,
                  //   totalSteps: 100,
                  //   currentStep: 20,
                  //   size: 32,        //进度指示条的高度
                  //   padding: 0,
                  //   selectedColor: Colors.transparent,
                  //   unselectedColor: Colors.grey,
                  //   roundedEdges: const Radius.circular(16),
                  // ),
                  StepProgress(map['lanIP'],key:map['remoteDeviceWidgetKey'])
                ),
              Positioned(
                left: 0,
                top: 0, 
                child: Row(
                  children: [
                    Container(
                      height: 32,
                      width: 32,
                      //margin: const EdgeInsets.fromLTRB(0, 0, 3, 0),
                      decoration: const BoxDecoration(
                          //color: Colors.blue,
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              topLeft: Radius.circular(16))
                          // borderRadius:
                          //     BorderRadius.all(Radius.circular(16))
                          ),
                      child: Icon(
                        getRemoteDeviceTypeIcon(map['deviceType']),
                        color: Colors.white,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          map['deviceName'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          map['lanIP'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ],
                )),
            ])));

    // DragTarget remoteDeviceWidget_ = DragTarget(onAccept: (data) {

    // }, builder: (context,candidateData,rejectData){
    //   return remoteDeviceWidget;
    // });
    remoteDevicesWidget.add(remoteDeviceWidget);
  }

  //初始化获取设备和wifi信息
  Future<Map> initGetInfo(Function func) async {
    Map deviceInfo_ = await DeviceInfoApi.getDeviceInfo();
    //print(deviceInfo_);
    deviceInfo_['lanIP'] = await DeviceInfoApi.getDeviceLocalIP();
    deviceInfo_['network'] = await DeviceInfoApi.getNetworkInfo(func);
    deviceInfo_['deviceType'] = Platform.operatingSystem;
    return deviceInfo_;
  }

  /// 启动UDP广播
  /// 需要加一个启动锁 多次重复启动 会出现bug
  void startUDP() async {
    if (startUDPLock == true) {
      return;
    }
    startUDPLock = true;

    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
    socket?.broadcastEnabled = true;
    log('UDP Echo ready to receive', StackTrace.current);
    const timeout = Duration(seconds: 3);
    //构造广播json数据
    Map broadMap = {
      'lanIP': deviceInfo['lanIP'],
      'deviceName': deviceInfo['model'],
      'deviceType': deviceInfo['deviceType']
    };
    String broadJson = json.encode(broadMap);

    timer = Timer.periodic(timeout, (timer) {
      //[0x44, 0x48, 0x01, 0x01]
      socket?.send(broadJson.codeUnits, InternetAddress("255.255.255.255"), udpPort);
    });
    //print('${socket.address.address}:${socket.port}');
    socket?.listen((RawSocketEvent e) {
      switch (e) {
        case RawSocketEvent.read:
          {
            Datagram? udpData = socket?.receive();
            if (udpData == null) return;
            var decoder = const Utf8Decoder();
            String msg = decoder.convert(udpData.data); // 将UTF8数据解码
            //String msg = String.fromCharCodes(udpData.data);
            //print('收到来自${udpData.address.toString()}:${udpData.port}的数据：${udpData.data.length}字节数据 内容:$msg');
            //print('Datagram from ${udpData.address.address}:${udpData.port}: ${msg.trim()}');
            //socket.send(msg.codeUnits, d.address, d.port);

            //解析UDP json数据
            // ignore: no_leading_underscores_for_local_identifiers
            Map<String, dynamic> _json = json.decode(msg);

            //print(deviceInfo['lanIP']);
            if (_json['lanIP'] != deviceInfo['lanIP']) {
              //print(_json['deviceName']);
              //remoteDevices.add(_json);
              //print('${remoteDeviceShowFlexible.currentContext?.size?.height}');
              //判断设备是否已经添加进显示区
              if (!remoteDevicesData.containsKey(_json['lanIP'])) {
                //print(_json['lanIP']);

                setState(() {
                  addRemoteDeviceToWidget(_json);
                  remoteDevicesWidgetPlus = remoteDevicesWidget;
                  remoteDevicesWidgetPlus.add(_waterRipple);
                });
              }
            }
          }
          break;
        case RawSocketEvent.write:
          {
            log('RawSocketEvent.write');
          }
          break;
        case RawSocketEvent.readClosed:
          {
            log('RawSocketEvent.readClosed');
          }
          break;
        case RawSocketEvent.closed:
          {
            log('RawSocketEvent.closed');
          }
          break;
      }
    }, onError: (error) {
      log(error);
    }, onDone: () {
      socket?.close();
      //socket = Null as RawDatagramSocket;
    });
  }

  /// 停止UDP广播
  void stopUDP() {
    //Log("stopUDP", StackTrace.current);
    socket?.close();
    //关闭定时器
    timer?.cancel();
  }

  //初始化"接收文件记录"数据
  //读取 SharedPreferences 中保存的接收文件数据 然后遍历目录查看文件是否存在 若不存在 则从记录中剔除
  List getRceiveFilesLog(){
    prefs!.getStringList("receviceFilesLog");
    return [];
  }

  @override
  Widget build(BuildContext context) {
    log("send_to_app页渲染完成");
    return Container(
        key: sendToAppBodyKey,
        color: Colors.blue,
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(0, 35, 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Icon(
                          getRemoteDeviceTypeIcon(deviceInfo['deviceType']),
                          size: 16,
                          color: Colors.white,
                        ),
                        Text(
                          deviceInfo['model'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_pin,
                          size: 16,
                          color: Colors.white,
                        ),
                        Text(
                          deviceInfo['lanIP'],
                          style: const TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.wifi,
                          size: 16,
                          color: Colors.white,
                        ),
                        Text(
                          deviceInfo['networkText'],
                          style: const TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ],
                )),
             Flexible(
              flex: 10,
              child: 
                // ListView.builder(
                //     key: receiveFilesLogKey,
                //     itemCount: 1,
                //     itemBuilder: (BuildContext context, int index) {
                //       return const ListTile(
                //         title: Text("接收文件记录"),
                //       );
                //     },
                //   ),
                ReceiveFilesLog(receiveFilesLogKey)
            ),
            Flexible(
              flex: 1,
              child: Container(
                height: 30,
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    Text(
                      "温馨提示:请确保设备连接同一WiFi或路由器子网",
                      style: TextStyle(color: Colors.grey),
                    )
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 20,
              key: remoteDeviceShowFlexible,
              child: Scaffold(
                backgroundColor: Colors.white,
                body: Stack(
                  key: remoteDevicesKey,
                  children: remoteDevicesWidgetPlus,
                ),
              ),
            )
          ],
        ));
  }
}


