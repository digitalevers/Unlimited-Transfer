import 'dart:io';
class GSFileSystemFileStorage{
  //io.FileSystemEntityType.FILE
  static bool isDir(String dirPath) {
    //File(dirPath).statSync().type == io.FileSystemEntityType.DIRECTORY
		return Directory(dirPath).existsSync();
	}

  static bool fileExists(String filePath){
    return File(filePath).existsSync();
  }

  static List<FileSystemEntity> scanDir(String dirPath){
    if(GSFileSystemFileStorage.isDir(dirPath)){
      Directory dir = Directory(dirPath);
      return dir.listSync();
    } else {
      throw Exception("$dirPath is not a directory");
    }
  }

  static int fileSize(String filePath){
    File file = File(filePath);
    if(file.existsSync()){
      return file.lengthSync();
    } else {
      throw Exception("$filePath is not a file");
    }
  }

  //删除文件
  static void deleteFile(String filePath){
    File file = File(filePath);
    if(file.existsSync()){
      file.deleteSync();
    } else {
      throw Exception("$filePath is not a file");
    }
  }

  //删除文件夹
  static void deleteDir(String dirPath,[Directory? directory]){
    directory ??= Directory(dirPath);
    
    if (directory.existsSync()) {    
      List<FileSystemEntity> files = directory.listSync();    
      if (files.isNotEmpty) {      
        for (var file in files) {        
          //file.deleteSync();   
          if(isDir(file.path)){
            deleteDir(file.path, file);
          } else {

          }
        }    
      }
      directory.deleteSync();
    } else {
      throw Exception("$dirPath is not a dir");
    }
  }
}