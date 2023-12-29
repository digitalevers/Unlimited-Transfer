import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import for Android features.
//import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
//import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:woniu/pages/modules/privacy_view.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  
  final String _data = "亲爱的用户，感谢您信任并使用无界闪传APP！\n" +
      " \n" +
      "无界闪传十分重视用户权利及隐私政策并严格按照相关法律法规的要求，对《用户协议》和《隐私政策》进行了更新,特向您说明如下：\n" +
      "1.为向您提供更优质的服务，我们会收集、使用必要的信息，并会采取业界先进的安全措施保护您的信息安全；\n" +
      "2.基于您的明示授权，我们后续可能会获取设备号信息、包括：设备型号、操作系统版本、设备设置、设备标识符、MAC（媒体访问控制）地址、IMEI（移动设备国际身份码）、广告标识符（\"IDFA\"与\"IDFV\"）。我们将使用量U SDK统计使用我们产品的设备数量并进行设备机型数据分析与设备适配性分析。您有权拒绝或取消授权；\n" +
      "3.您可灵活设置伴伴账号的功能内容和互动权限，您可在《隐私政策》中了解到权限的详细应用说明；\n" +
      "4.未经您同意，我们不会从第三方获取、共享或向其提供您的信息；\n"
      " \n" +
      "请您仔细阅读并充分理解相关条款，其中重点条款已为您黑体加粗标识，方便您了解自己的权利。如您点击“同意”，即表示您已仔细阅读并同意本《用户协议》及《隐私政策》，将尽全力保障您的合法权益并继续为您提供优质的产品和服务。如您点击“不同意”，将可能导致您无法继续使用我们的产品和服务。";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //界面build完成后弹出隐私政策弹窗
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
          return Center(
            child: Material(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * .6,
                width: MediaQuery.of(context).size.width * .8,
                child: Column(
                  children: [
                    Container(
                      height: 45,
                      alignment: Alignment.center,
                      child: const Text(
                        '用户隐私政策概要',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(
                      height: 1,
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: PrivacyView(
                          data: _data,
                          keys:const ['《用户协议》', '《隐私政策》'],
                          keyStyle: const TextStyle(color: Colors.red),
                          onTapCallback: (String key) {
                            if (key == '《用户协议》') {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                                WebViewController webViewController = WebViewController.fromPlatformCreationParams(PlatformWebViewControllerCreationParams());
                                webViewController.loadRequest(Uri.parse("https://pub-web.flutter-io.cn/"));
                                return WebViewWidget(controller: webViewController);
                              }));
                            } else if (key == '《隐私政策》') {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) {
                                WebViewController webViewController = WebViewController.fromPlatformCreationParams(PlatformWebViewControllerCreationParams());
                                webViewController.loadRequest(Uri.parse("https://pub-web.flutter-io.cn/"));
                                return WebViewWidget(controller: webViewController);
                              }));
                            }
                          },
                        ),
                      ),
                    )),
                    const Divider(
                      height: 1,
                    ),
                    SizedBox(
                      height: 45,
                      child: Row(
                        children: [
                          Expanded(
                              child: GestureDetector(
                            child: Container(
                                alignment: Alignment.center,
                                child: const Text('不同意')),
                            onTap: () {
                              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                            },
                          )),
                          const VerticalDivider(
                            width: 1,
                          ),
                          Expanded(
                              child: GestureDetector(
                            child: Container(
                                alignment: Alignment.center,
                                color: Theme.of(context).primaryColor,
                                child: const Text('同意',style:TextStyle(color: Colors.white))),
                            onTap: () {},
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}