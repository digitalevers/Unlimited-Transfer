// ignore: file_names
import 'dart:io';
import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

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
    Directory dir = Directory(dirPath);
    if(dir.existsSync()){
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
        for (FileSystemEntity file in files) {        
          if(isDir(file.path)){
            deleteDir(file.path, file as Directory?);
          } else {
            file.deleteSync();
          }
        }    
      }
      directory.deleteSync();
    } else {
      throw Exception("$dirPath is not a dir");
    }
  }

  //创建文件夹
  static void makeDir(String dirPath){
    if(isDir(dirPath)){
      throw Exception("dir does exists");
    } else {
      Directory(dirPath).createSync();
    }
  }

  //创建文件
  static File makeFile(String filePath){
    if(fileExists(filePath)){
      throw Exception("file does exists");
    } else {
      File file = File(filePath);
      file.createSync();
      return file;
    }

  }
  
  //获取文件修改时间
  static DateTime filemtime(String filePath){
    File file = File(filePath);
    if(file.existsSync()){
      FileStat fs = file.statSync();
      return fs.modified;
    } else {
      throw Exception("file does not exists");
    }
  }

  //复制文件
  static File copyFile(String fromFilePath,String toFilePath){
    File fromFile = File(fromFilePath);
    if(fromFile.existsSync()){
      File toFile = File(toFilePath);
      if(toFile.existsSync()){
        throw Exception("destination file does exists");
      } else {
        return fromFile.copySync(toFilePath);
      }
    } else {
      throw Exception("resource file does not exists");
    }
  }

  //复制文件夹
  static void copyDir(String srcDirPath,String dstDirPath){
    Directory srcDir = Directory(srcDirPath);
    if(srcDir.existsSync()){
      Directory dstDir = Directory(dstDirPath);
      if(!dstDir.existsSync()){
        dstDir.createSync();
      }
      for(FileSystemEntity file in srcDir.listSync()){
        if(file.statSync().type == FileSystemEntityType.directory){
          copyDir(file.path, dstDirPath + p.basename(file.path));
        } else {
          (file as File).copySync(dstDirPath + p.basename(file.path));
        }
      }
    } else {
      throw Exception("resource dir does not exists");
    }
  }

  static void renameItem(String fromFileName, String toFileName){
    File fromFile = File(fromFileName);
    if(fromFile.existsSync()){
      try{
        fromFile.renameSync(toFileName);
      } catch (e){
        print("rename fail");
      }
    } else {
      throw Exception("resource file does not exists");
    }
  }

  static dynamic readFile(String filePath,[int type = 1]){
    File file = File(filePath);
    if(file.existsSync()){
      if(type == 1){
        return file.readAsStringSync();
      } else if(type == 2){
        return file.readAsBytesSync();
      } else {
        return file.readAsLinesSync();
      }
    } else {
      throw Exception("file does not exists");
    }
  }

  static void writefile(String filePath,dynamic content){
    File file = File(filePath);
    if(!file.existsSync()){
      file.createSync();
      if(content.runtimeType == String){
        file.writeAsStringSync(content);
      } else if(content.runtimeType == Uint8List){
        file.writeAsBytesSync(content);
      } else {
        throw Exception("Unsupported content type");
      }
    }
  }
}

// void main(){
//   //GSFileSystemFileStorage gs = GSFileSystemFileStorage();
//   var dir = GSFileSystemFileStorage.scanDir("/");
//   for(var file in dir){
//     print(file.path);
//   }
// }