/////
/////定义一些通用类
/////

// ignore: slash_for_doc_comments
/**
 *  日志打印类
 */
class CustomPrint{
  late final StackTrace _st;
  late String fileName;
  late int lineNumber;

  CustomPrint(this._st){
      _parseTrace();
  }

  void _parseTrace(){
    var traceString = _st.toString().split("\n")[0];
    var index0fFileName = traceString.indexOf(RegExp(r'[A-Za-z_]+.dart'));
    var fileInfo = traceString.substring(index0fFileName);
    var listOfInfos = fileInfo.split(":");
    fileName = listOfInfos[0];
    lineNumber = int.parse(listOfInfos[1].replaceAll(RegExp(r'[^0-9]'),''));  //release模式下若是非纯数字（字符串中包含字母）会报错
    var columnStr = "";
    if(listOfInfos.length > 2){
      columnStr = listOfInfos[2];
      columnStr = columnStr.replaceFirst(")","");
    }
  }
}
