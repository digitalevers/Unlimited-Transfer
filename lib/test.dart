import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

// String _data = "0";

// void main() {
//   // _testMethod();
//   // sleep(Duration(seconds: 2));
//   // print("执行其他的操作");

// }

// _testMethod() {
//   print("开始");
//   // 模拟耗时操作
//   Future((){
//       for (int i = 0; i < 1000000000; i++) {
//         _data = "获取到的网络数据";
//       }
//       print("结束,_data=${_data}");
//   });
// }



// void main() {
//   _loadUserFromSQL().then((userInfo) {
//     return _fetchSessionToken(userInfo);
//   }).then((token) {
//     return _fetchData(token);
//   }).then((data){
//     print('$data');
//   });
//   print('main is executed!');
// }

// class UserInfo {
//   final String userName;
//   final String pwd;
//   bool isValid = true;

//   UserInfo(this.userName, this.pwd);
// }

// //从本地SQL读取用户信息
// Future<UserInfo> _loadUserFromSQL() {
//   return Future.delayed(
//       Duration(seconds: 2), () => UserInfo('gitchat', '123456'));
// }

// //获取用户token
// Future<String> _fetchSessionToken(UserInfo userInfo) {
//   return Future.delayed(Duration(seconds: 2), ()=>'3424324sfdsfsdf24324234');
// }

// //请求数据
// Future<String> _fetchData(String token) {
//   return Future.delayed(
//       Duration(seconds: 2),
//       () => token.isNotEmpty
//           ? Future.value('this is data')
//           : Future.error('this is error'));
// }

void main() async {//注意：需要添加async，因为await必须在async方法内才有效
  //  print('0');

  //  await testasync().then((param)=>{print(param)});
  //  print('end');
  print(fommatFileSize(1055053899));
}

String fommatFileSize(int fileSizeBytes){
  int power = 0;
  List<String> units = ['Bytes','KB','MB','GB','TB'];
  int numLength = fileSizeBytes.toString().length;
  power = (numLength - 1) ~/ 3;
  num divisor = pow(1000,power);
  String formatedFileSize = (fileSizeBytes / divisor).toStringAsFixed(1);
  return "$formatedFileSize${units[power]}";
}

Future<int> testasync() async{
  var userInfo = await _loadUserFromSQL();
  print("1");
  var token = await _fetchSessionToken(userInfo);
  print("2");
  var data = await _fetchData(token);
  print('$data');
  print('main is executed!');
  return 123;
}

class UserInfo {
  final String userName;
  final String pwd;
  bool? isValid;

  UserInfo(this.userName, this.pwd);
}

//从本地SQL读取用户信息
Future<UserInfo> _loadUserFromSQL() {
  return Future.delayed(
      Duration(seconds: 2), () => UserInfo('gitchat', '123456'));
}

//获取用户token
Future<String> _fetchSessionToken(UserInfo userInfo) {
  return Future.delayed(Duration(seconds: 2), () => '3424324sfdsfsdf24324234');
}

//请求数据
Future<String> _fetchData(String token) {
  return Future.delayed(
      Duration(seconds: 2),
      () => token.isNotEmpty
          ? Future.value('this is data')
          : Future.error('this is error'));
}
