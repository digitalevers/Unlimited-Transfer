// ignore: file_names
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:html_character_entities/html_character_entities.dart';
import 'package:crypto/crypto.dart';

class FileSystemFileStorage{
  //io.FileSystemEntityType.FILE
   bool isDir(String dirPath) {
    //File(dirPath).statSync().type == io.FileSystemEntityType.DIRECTORY
		return Directory(dirPath).existsSync();
	}

   bool fileExists(String filePath){
    return File(filePath).statSync().size != -1;
  }

   List<FileSystemEntity> scanDir(String dirPath){
    Directory dir = Directory(dirPath);
    if(dir.existsSync()){
      return dir.listSync();
    } else {
      throw Exception("$dirPath is not a directory");
    }
  }

   int fileSize(String filePath){
    File file = File(filePath);
    if(file.existsSync()){
      return file.lengthSync();
    } else {
      throw Exception("$filePath is not a file");
    }
  }

  //删除文件
   void deleteFile(String filePath){
    File file = File(filePath);
    if(file.existsSync()){
      file.deleteSync();
    } else {
      throw Exception("$filePath is not a file");
    }
  }

  //删除文件夹
   void deleteDir(String dirPath,[Directory? directory]){
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
   void makeDir(String dirPath){
    if(isDir(dirPath)){
      return;
    } else {
      Directory(dirPath).createSync(recursive:true);
    }
  }

  //创建文件
   File makeFile({String? filePath,File? file}){
    if(filePath == null && file == null){
      throw Exception("need one parameter at least");
    }
    if(file != null){
      if(!file.existsSync()){
        file.createSync(recursive:true);
      }
      return file;
    } else {
      File file = File(filePath!);
      if(!file.existsSync()){
        file.createSync(recursive:true);
      }
      return file;
    }
  }
  
  //获取文件修改时间
   DateTime filemtime(String filePath){
    File file = File(filePath);
    if(file.existsSync()){
      FileStat fs = file.statSync();
      return fs.modified;
    } else {
      Directory dir = Directory(filePath);
      FileStat ds = dir.statSync();
      return ds.modified;
    }
  }

  //复制文件
   File copyFile(String fromFilePath,String toFilePath){
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
   void copyDir(String srcDirPath,String dstDirPath){
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

  //重命名文件
   void renameItem(String fromFileName, String toFileName){
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

  //读取文件
   dynamic readFile(String filePath,[int type = 1]){
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

  //写文件
   void writefile(String filePath,dynamic content){
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

class FileManager{
  FileSystemFileStorage _fileStorage;
  Map<String,String> _options = {};
  //bool _setUtf8Header = true;
  final List<String> _functions = [];
  String _itemNameRegex = '[/\?\*;:{}\\\\]+';

  FileManager(this._fileStorage, this._options){
    _functions.add("");
		_functions.add("listDir");
    _functions.add("makeFile");
    _functions.add("makeDirectory");
		_functions.add("deleteItem");
		_functions.add("copyItem");
		_functions.add("renameItem");
		_functions.add("moveItems");
		_functions.add("downloadItem");
		_functions.add("readfile");
		_functions.add("writefile");
		_functions.add("uploadfile");
		_functions.add("jCropImage");
		_functions.add("imageResize");
		_functions.add("copyAsFile");
		_functions.add("serveImage");
		_functions.add("zipItem");
		_functions.add("unZipItem");
  }

  String getRequestFunction(int index){
		String result = "";
		if (_functions[index].isNotEmpty) {
			result = _functions[index];
		}
		return result;
	}

  String listDir(Map<String,String> args){
    String rootDir = _options["rootDir"]!;
		String dir = args['dir']!;
    //print(rootDir + dir);
		if(_fileStorage.isDir(rootDir + dir) ) {
			List<FileSystemEntity> files = _fileStorage.scanDir(rootDir + dir);
      //print(Directory("/storage/emulated/0/Pictures/").listSync().length);
			//natcasesort($files);
			String html = '';
			html += 'var gsdirs = new Array();';
			html += 'var gsfiles = new Array();';
      for(FileSystemEntity file in files ) {
        //print(file.path);
        if (p.basename(file.path) == '.' || p.basename(file.path) == '..' || p.basename(file.path) == '.htaccess') {
          continue;
        }
        try{
          if(_fileStorage.fileExists(file.path)){
            
            if(_fileStorage.isDir(file.path) ) {
              //print("dir"+file.path);
              String dirPath = file.path.replaceAll(rootDir, "");
              html += 'gsdirs.push(new gsItem("2", "${p.basename(file.path)}", "$dirPath", "0", "${md5.convert(const Utf8Encoder().convert(file.path))}", "dir", "${_fileStorage.filemtime(file.path)}"));';
            } else {
              
              String extension = p.extension(file.path);
              html += 'gsfiles.push(new gsItem("1", "${p.basename(file.path)}", "${p.basename(file.path)}", "${_fileStorage.fileSize(file.path)}", "${md5.convert(const Utf8Encoder().convert(file.path))}", "${Uri.encodeComponent(extension).toLowerCase()}", "${_fileStorage.filemtime(file.path)}"));';
            }
          }
        } catch(e){
          print(e);
        }
			}
      //print(html);
			return html;
		} else {
			throw Exception("ILlegalArgumentException: dir to list does NOT exists $dir");
		}
  }

  void makeFile(Map<String,dynamic> args){
    
  }

  void makeDirectory(Map<String,dynamic> args){
    
  }

  void deleteItem(Map<String,dynamic> args){
    //print(args);
    String rootDir = _options["rootDir"]!;
		String dir = args['dir'];
    String filename = args['files'];
    _fileStorage.deleteFile(rootDir + dir + filename);
  }

  void copyItem(Map<String,dynamic> args){

  }

  void renameItem(Map<String,dynamic> args){

  }

  void moveItems(Map<String,dynamic> args){

  }

  void downloadItem(Map<String,dynamic> args){
    //print(args);
    String rootDir = _options["rootDir"]!;
		String dir = args['dir'];
    String filename = args['filename'];
    File downloadFile  = File(rootDir + dir + filename);
    //TODO根据后缀获取MIME
    args["request"].response.headers.contentType = ContentType.parse("application/vnd.android.package-archive");
    args["request"].response.headers.set("content-disposition","attachment; filename=$filename");
    args["request"].response.addStream(downloadFile.openRead()).then((_) => args["request"].response.close());
  }

  void readfile(Map<String,dynamic> args){

  }

  void writefile(Map<String,dynamic> args){

  }

  void uploadfile(Map<String,dynamic> args){

  }

  void jCropImage(Map<String,dynamic> args){

  }

  void imageResize(Map<String,dynamic> args){

  }

  void copyAsFile(Map<String,dynamic> args){

  }

  void serveImage(Map<String,dynamic> args){

  }

  void zipItem(Map<String,dynamic> args){

  }

  void unZipItem(Map<String,dynamic> args){

  }

  //dynamic invoke the method
  //dart:mirros lib is not avaiable on all platforms
  Function getMethod(String name) {
    if (name == "listDir") return listDir;
    if (name == "makeFile") return makeFile;
    if (name == "makeDirectory") return makeDirectory;
    if (name == "deleteItem") return deleteItem;
    if (name == "copyItem") return copyItem;
    if (name == "renameItem") return renameItem;
    if (name == "moveItems") return moveItems;
    if (name == "downloadItem") return downloadItem;
    if (name == "readfile") return readfile;
    if (name == "writefile") return writefile;
    if (name == "uploadfile") return uploadfile;
    if (name == "jCropImage") return jCropImage;
    if (name == "imageResize") return imageResize;
    if (name == "copyAsFile") return copyAsFile;
    if (name == "serveImage") return serveImage;
    if (name == "zipItem") return zipItem;
    if (name == "unZipItem") return unZipItem;
    throw ArgumentError.value(name, "name");
  }

  String process(Map<String,dynamic> args){
    if (args['opt'] == null || args['opt']!.isEmpty) {
			args['opt']  = "1"; //listDir
		}
    
    String? rootDir = _options["rootDir"];
    if(rootDir == null){
      throw Exception("ConfigurationException: root can NOT be null");
    }

    if(args["dir"] == null || args["dir"]!.isEmpty){
      throw Exception("ILlegalArgumentException: dir can NOT be null");
    } else {
      args["dir"] = Uri.decodeFull(args["dir"]!);
      args["dir"] = HtmlCharacterEntities.decode(args["dir"]!);
    }
    
    String response = "";
		String functionName = getRequestFunction(int.parse(args["opt"]!));
    if (functionName.isNotEmpty) {
      response = getMethod(functionName)(args) ?? "";
    } else {
      throw Exception("ILlegalArgumentException: Unknown action${args['opt']}");
    }
		// if (_setUtf8Header) {
		// 	header("Content-Type: text/html; charset=utf-8");
		// }

    return response;
  }
}


void main(){
  Map<String,String> options = {};
  options["rootDir"] = 'E:';
  FileManager manager = FileManager(FileSystemFileStorage(), options);
  
  Map<String,String> requestArgs = {"dir":"/"};
  String result = "";
  try {
    result = manager.process(requestArgs);
    //File file = File("E:/System Volume Information");
    //print(file.existsSync());
  } catch (e) {
    //result = '{result: \'0\', gserror: \''.addslashes($e->getMessage()).'\', code: \''.$e->getCode().'\'}';
    print(e);
  }
  print(result);
}