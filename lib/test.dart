import 'dart:convert';
import 'dart:io';

String _data = "0";

void main() {
  // _testMethod();
  // sleep(Duration(seconds: 2));
  // print("执行其他的操作");

}

_testMethod() {
  print("开始");
  // 模拟耗时操作
  Future((){
      for (int i = 0; i < 1000000000; i++) {
        _data = "获取到的网络数据";
      }
      print("结束,_data=${_data}");
  });
}
