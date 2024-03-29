import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import 'package:tuotu/main.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as ulaunch;

import 'package:tuotu/controllers/controllers.dart';
import 'package:tuotu/common/global_variable.dart';
import '../common/func.dart';

void privacyPolicyDialog(BuildContext context, String data) async {
  SharedPreferences prefInst = await SharedPreferences.getInstance();
  // ignore: use_build_context_synchronously
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: prefInst.getBool('isDarkTheme') == true
              ? const Color.fromARGB(255, 27, 32, 35)
              : Colors.white,
          title: const Text('Privacy policy'),
          content: SizedBox(
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.height / 1.2,
              child: Markdown(
                  listItemCrossAxisAlignment:
                      MarkdownListItemCrossAxisAlignment.start,
                  data: data)),
          actions: [
            ElevatedButton(
                onPressed: () async {
                  await ulaunch.launchUrl(Uri.parse(
                      'https://github.com/abhi16180/photon-file-transfer'));
                },
                child: const Text('Source-code')),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Okay'))
          ],
        );
      });
}

progressPageAlertDialog(BuildContext context) async {
  SharedPreferences prefInst = await SharedPreferences.getInstance();
  // ignore: use_build_context_synchronously
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: prefInst.getBool('isDarkTheme') == true
            ? const Color.fromARGB(255, 27, 32, 35)
            : Colors.white,
        title: const Text('Alert'),
        content: const Text('Make sure that transfer is completed !'),
        actions: [
          ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Stay')),
          ElevatedButton(
            onPressed: () async {
              // ignore: use_build_context_synchronously
              GetIt.I.get<PercentageController>().totalTimeElapsed.value = 0;
              GetIt.I.get<PercentageController>().isFinished.value = false;
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home', (Route<dynamic> route) => false);
            },
            child: const Text('Go back'),
          )
        ],
      );
    },
  );
}

progressPageWillPopDialog(context) async {
  SharedPreferences prefInst = await SharedPreferences.getInstance();
  bool willPop = false;
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: prefInst.getBool('isDarkTheme') == true
            ? const Color.fromARGB(255, 27, 32, 35)
            : Colors.white,
        title: const Text('Alert'),
        content: const Text('Make sure that download is completed !'),
        actions: [
          ElevatedButton(
              onPressed: () {
                willPop = false;
                Navigator.of(context).pop();
              },
              child: const Text('Stay')),
          ElevatedButton(
            onPressed: () async {
              willPop = true;

              // ignore: use_build_context_synchronously
              GetIt.I.get<PercentageController>().totalTimeElapsed.value = 0;
              GetIt.I.get<PercentageController>().isFinished.value = false;

              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home', (Route<dynamic> route) => false);
            },
            child: const Text('Go back'),
          )
        ],
      );
    },
  );
  return willPop;
}

sharePageAlertDialog(BuildContext context) async {
  SharedPreferences prefInst = await SharedPreferences.getInstance();
  // ignore: use_build_context_synchronously
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: prefInst.getBool('isDarkTheme') == true
            ? const Color.fromARGB(255, 27, 32, 35)
            : Colors.white,
        title: const Text('Server alert'),
        content: const Text('Would you like to terminate the current session'),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Stay')),
          ElevatedButton(
            onPressed: () async {
              //await Sender.closeServer(context);
              // ignore: use_build_context_synchronously
              GetIt.I.get<ReceiverDataController>().receiverMap.clear();
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MyApp()),
                  (route) => false);
            },
            child: const Text('Terminate'),
          )
        ],
      );
    },
  );
}

sharePageWillPopDialog(context) async {
  bool willPop = false;
  SharedPreferences prefInst = await SharedPreferences.getInstance();
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: prefInst.getBool('isDarkTheme') == true
            ? const Color.fromARGB(255, 27, 32, 35)
            : Colors.white,
        title: const Text('Server alert'),
        content:
            const Text('Would you like to terminate the current session ?'),
        actions: [
          ElevatedButton(
              onPressed: () {
                willPop = false;
                Navigator.of(context).pop();
              },
              child: const Text('Stay')),
          ElevatedButton(
            onPressed: () async {
              //await Sender.closeServer(context);
              willPop = true;
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
              // Navigator.of(context).pushAndRemoveUntil(
              //     MaterialPageRoute(builder: (context) => const App()),
              //     (route) => false);
            },
            child: const Text('Terminate'),
          )
        ],
      );
    },
  );
  return willPop;
}

senderRequestDialog(
  String username,
  String os,
) async {
  bool allowRequest = false;
  SharedPreferences prefInst = await SharedPreferences.getInstance();

  await showDialog(
      context: nav.currentContext!,
      builder: (context) {
        return AlertDialog(
          backgroundColor: prefInst.getBool('isDarkTheme') == true
              ? const Color.fromARGB(255, 27, 32, 35)
              : Colors.white,
          title: const Text('Request from receiver'),
          content: Text(
              "$username ($os) is requesting for files. Would you like to share with them ?"),
          actions: [
            ElevatedButton(
              onPressed: () {
                allowRequest = false;
                Navigator.of(context).pop();
              },
              child: const Text('Deny'),
            ),
            ElevatedButton(
              onPressed: () {
                allowRequest = true;
                Navigator.of(context).pop();
              },
              child: const Text('Accept'),
            )
          ],
        );
      });

  return allowRequest;
}

credits(context) async {
  SharedPreferences prefInst = await SharedPreferences.getInstance();
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: prefInst.getBool('isDarkTheme') == true
              ? const Color.fromARGB(255, 27, 32, 35)
              : Colors.white,
          title: const Text('Credits'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Icons'),
                GestureDetector(
                  onTap: () {
                    ulaunch.launchUrl(Uri.parse('https://www.svgrepo.com'));
                  },
                  child: const Text(
                    'https://www.svgrepo.com/',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue, //#2196f3
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text('Animations'),
                GestureDetector(
                  onTap: () {
                    ulaunch.launchUrl(Uri.parse('https://lottiefiles.com/'));
                  },
                  child: const Text(
                    'https://lottiefiles.com/',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text('Fonts\nYftoowhy', textAlign: TextAlign.center),
                GestureDetector(
                  onTap: () {
                    ulaunch.launchUrl(Uri.parse(
                        'https://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=OFL'));
                  },
                  child: const Text(
                    """ Font license""",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Text('\nQuestrial', textAlign: TextAlign.center),
                GestureDetector(
                  onTap: () {
                    ulaunch.launchUrl(
                        Uri.parse('https://github.com/googlefonts/questrial'));
                  },
                  child: const Text(
                    """ Font license""",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close),
            )
          ],
        );
      });
}

//弹出对话框（服务端是否接收新文件）
// Future<ServerIfReceiveFile> ifReceiveFile(context,fileCount,fileSize) async {
//   ServerIfReceiveFile res = await showDialog(
//     barrierDismissible:false, //false 模态对话框
//     context: context,
//     builder: (context){
//     return AlertDialog(
//       //title: const Text("新文件"),
//       content: Text("您有$fileCount个新的文件等待接收,大小${fileSize}M"),
//       actions: [
//         TextButton(
//           child: const Text("拒收"),
//           onPressed: (){
//             //print("点击取消");
//             Navigator.of(context).pop(ServerIfReceiveFile.reject);
//           }
//         ),
//         TextButton(
//           child: Text("接收"),
//           onPressed: (){
//             //print("点击确定");
//             Navigator.of(context).pop(ServerIfReceiveFile.accept);
//           }
//         )
//       ],
//     );
//   });
//   return res;
// }

Future<ServerIfReceiveFile> ifReceiveFile(context, fileCount, fileSize) async {
  String formatedFileSize = fommatFileSize(fileSize);
  ServerIfReceiveFile res = await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          //title: Text('这是标题'),
          content: Text("您有$fileCount个新的文件等待接收,大小$formatedFileSize"),
          actions: <Widget>[
            CupertinoButton(
              child: const Text("拒收"),
              onPressed: () {
                Navigator.of(context).pop(ServerIfReceiveFile.reject);
              },
            ),
            CupertinoButton(
              child: const Text("接收"),
              onPressed: () {
                Navigator.of(context).pop(ServerIfReceiveFile.accept);
              },
            ),
          ],
        );
      });
  return res;
}
