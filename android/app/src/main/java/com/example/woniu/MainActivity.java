package com.digitalevers.transfer;

import static android.provider.MediaStore.VOLUME_EXTERNAL_PRIMARY;

import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Intent;
import android.content.res.AssetFileDescriptor;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.StrictMode;

import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.DocumentsContract;
import android.provider.DocumentsProvider;
import android.provider.MediaStore;
import android.provider.Settings;
import android.webkit.MimeTypeMap;
import android.provider.OpenableColumns;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import io.flutter.embedding.android.FlutterActivity;    //新版SDK
//import io.flutter.app.FlutterActivity;    //旧版SDK
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
 
public class MainActivity extends FlutterActivity {
 
    private static final String channel = "AndroidApi";
 
    @Override
    protected void onCreate(Bundle savedInstanceState){
        super.onCreate(savedInstanceState);
        if (android.os.Build.VERSION.SDK_INT > 9) {
            StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
            StrictMode.setThreadPolicy(policy);
        }
 
        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(),channel).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                        if (call.method.equals("getOriginFilePathByUri")) {
                            String uri = (String) (((ArrayList) call.arguments).get(0));
                            result.success(getOriginFilePathByUri(Uri.parse(uri), getApplicationContext()));
                        } else if(call.method.equals("copyFileToPrivateSpace")){
                            String uri = (String) (((ArrayList) call.arguments).get(0));
                            String name = (String) (((ArrayList) call.arguments).get(1));
                            String ext = (String) (((ArrayList) call.arguments).get(2));
                            try {
                                result.success(copyFileToPrivateSpace(getApplicationContext(), Uri.parse(uri), name, ext));
                            } catch (IOException e) {
                                throw new RuntimeException(e);
                            }
                        } else if(call.method.equals("openDir")){
                            String dir = (String) (((ArrayList) call.arguments).get(0));
                            result.success(openDir(dir));
                        } else {
                            result.notImplemented();
                        }
                    }
                }
        );
    }



    public String getOriginFilePathByUri(Uri uri, Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            //System.out.println("-----------------------"+Environment.isExternalStorageManager());
        }
        //2023-12-23 22:00
        //请求所有文件权限 才能调用intent打开文件
        // final int REQUEST_MANAGE_FILES_ACCESS = 2;
        // if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        //     if(!Environment.isExternalStorageManager()){
        //         Intent intent = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
        //         intent.setData(Uri.parse("package:" + getPackageName()));
        //         startActivityForResult(intent, REQUEST_MANAGE_FILES_ACCESS);
        //     }
        // }

        String path = "";
        // 以 file:// 开头的
        if (ContentResolver.SCHEME_FILE.equals(uri.getScheme())) {
            path = uri.getPath();
            return path;
        }
        // 以 content:// 开头的，比如 content://media/extenral/images/media/17766
        if (ContentResolver.SCHEME_CONTENT.equals(uri.getScheme()) && Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) {
            Cursor cursor = context.getContentResolver().query(uri, new String[]{MediaStore.Images.Media.DATA}, null, null, null);
            if (cursor != null) {
                if (cursor.moveToFirst()) {
                    int columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
                    if (columnIndex > -1) {
                        path = cursor.getString(columnIndex);
                    }
                }
                cursor.close();
            }
            return path;
        }
        // 4.4及之后的 是以 content:// 开头的，比如 content://com.android.providers.media.documents/document/image%3A235700
        if (ContentResolver.SCHEME_CONTENT.equals(uri.getScheme()) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            //if (DocumentsContract.isDocumentUri(context, uri)) {
                final String docId = DocumentsContract.getDocumentId(uri);
                if (isExternalStorageDocument(uri)) {
                    ///System.out.println("isExternalStorageDocument-"+uri.toString());
                    // ExternalStorageProvider
                    final String[] docIdSplit = docId.split(":");
                    final String[] uriSplit = uri.toString().split(":");
                    String basename = "";
                    for(int i = 2;i < uriSplit.length; i++){
                        basename += uriSplit[i];
                    }
                    if ("primary".equalsIgnoreCase(docIdSplit[0])) {
                        path = Environment.getExternalStorageDirectory() + "/" + basename;
                        return path;
                    } else if("home".equalsIgnoreCase(docIdSplit[0])){
                        path = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS) + "/" + basename;
                        return path;
                    }
                } else if (isDownloadsDocument(uri)) {
                    System.out.println("isDownloadsDocument-"+uri.toString());
                    // DownloadsProvider
                    if(uri.toString().contains("raw:/storage/emulated")){
                        //content://com.android.providers.downloads.documents/document/raw:/storage/emulated/0/Download/34d4724ef96b1088.jpg
                        String[] idSplit = docId.split(":");
                        String[] uriSplit = uri.toString().split(":");
                        if("raw".equalsIgnoreCase(idSplit[0])) {
                            for (int i = 2; i < uriSplit.length; i++) {
                                path += uriSplit[i];
                            }
                        }
                    } else {
                        //content://com.android.providers.downloads.documents/document/1412
                        path = getDocumentPrivateData(context, uri, docId);
                    }
                    System.out.println(path);
                    return path;

                } else if (isMediaDocument(uri)) {
                    System.out.println("isMediaDocument-"+uri.toString());
                    // MediaProvider
                    //System.out.println(docId);
                    final String[] split = docId.split(":");
                    final String type = split[0];
                    Uri contentUri = null;
                    if ("image".equals(type)) {
                        contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
                    } else if ("video".equals(type)) {
                        contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
                    } else if ("audio".equals(type)) {
                        contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
                    } else if("document".equals(type)){
                        //Android12 文档Uri content://com.android.providers.media.documents/document/document%3A129396 的处理
                        path = getDocumentPrivateData(context, uri, docId);
                        return path;
                    }
                    final String selection = "_id=?";
                    final String[] selectionArgs = new String[]{split[1]};
                    path = getDataColumn(context, contentUri, selection, selectionArgs);
                    return path;
                }
//            } else {

//            }
        } else {
            //4.4之前

        }
        return null;
    }

    private static String getDataColumn(Context context, Uri uri, String selection, String[] selectionArgs) {
        Cursor cursor = null;
        final String column = "_data";
        final String[] projection = {column};
        try {
            cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs, null);
            if (cursor != null && cursor.moveToFirst()) {
                final int column_index = cursor.getColumnIndexOrThrow(column);
                return cursor.getString(column_index);
            }
        } finally {
            if (cursor != null)
                cursor.close();
        }
        return null;
    }


    /**
     * Android12 适配(只能返回文件名 无法获取文件路径 但是可以使用 openAssetFileDescriptor 直接读取文件文件 参见flutter插件 uri_to_file 的Android源代码)
     *
     * 针对Android12 和 Android7 访问“下载内容”
     * 返回的Uri形式为 content://com.android.providers.downloads.documents/document/1412
     *             或content://com.android.providers.downloads.documents/document/msf:163919
     * 以及Android12 访问"文档"
     * 返回的Uri形式为 content://com.android.providers.media.documents/document/document:129396
     * 这几种Uri形式都无法通过 provider 查询获得真正的file path，仅能获取到文件名
     * 所以这个函数的目的就是使用Uri打开文件流，将文件复制到/data/data私域目录，然后返回私域目的的path file
     *
     * return 文件在私域中的路径
     */
    private static String getDocumentPrivateData(Context context,Uri uri,String docId){
        String documentPrivateData = "";
        uri = Uri.parse(uri.toString().replaceAll(docId,"") + Uri.encode(docId));
        Cursor cursor = context.getContentResolver().query(uri, null, null, null, null);
        if (cursor != null) {
            if (cursor.moveToFirst()) {
                int columnIndex = cursor.getColumnIndexOrThrow("_display_name");
                String fileName = cursor.getString(columnIndex);
                if(fileName != null && !fileName.isEmpty()) {
                    String name = fileName.substring(0, fileName.lastIndexOf('.'));
                    String ext = fileName.substring(fileName.lastIndexOf('.'));
                    try {
                        documentPrivateData = copyFileToPrivateSpace(context, uri, name, ext);
                    } catch (Exception e){
                        System.out.println(e.getMessage());
                    }
                } else {
                    System.out.println("file name is empty");
                }
            }
            cursor.close();
        }

        return documentPrivateData;
    }

    /**
     * 针对Android12 和 Android7 访问“下载内容”
     * 返回的Uri形式为 content://com.android.providers.downloads.documents/document/1412
     *             或content://com.android.providers.downloads.documents/document/msf:163919
     * 以及Android12 访问"文档"
     * 返回的Uri形式为 content://com.android.providers.media.documents/document/document:129396
     * 这几种Uri形式都无法通过 provider 查询获得真正的file path，仅能获取到文件名
     * 所以这个函数的目的就是使用Uri打开文件流，将文件复制到/data/data私域目录，然后返回私域目的的path file
     * copy file from /downloads to /data/data
     */
    private static String copyFileToPrivateSpace(Context context,Uri uri,String name,String ext) throws IOException {
        AssetFileDescriptor assetFileDescriptor = context.getContentResolver().openAssetFileDescriptor(uri, "r");
        //System.out.println(assetFileDescriptor.getFileDescriptor().toString());
        FileChannel inputChannel = new FileInputStream(assetFileDescriptor.getFileDescriptor()).getChannel();

        File parent = new File(context.getFilesDir() + File.separator + "uri_to_file");
        parent.mkdirs();

        File file = new File(context.getFilesDir() + File.separator + "uri_to_file" + File.separator + name + ext);
        file.deleteOnExit();

        FileChannel outputChannel = new FileOutputStream(file).getChannel();

        long bytesTransferred = 0;
        while (bytesTransferred < inputChannel.size()) {
            bytesTransferred += outputChannel.transferFrom(inputChannel, bytesTransferred, inputChannel.size());
        }

        final String filepath = file.getCanonicalPath();
        if(filepath != null && !filepath.isEmpty()) {
            return filepath;
        } else {
            throw new IOException("Unable to fetch filepath");
        }
    }

    private static boolean isExternalStorageDocument(Uri uri) {
        return "com.android.externalstorage.documents".equals(uri.getAuthority());
    }

    private static boolean isDownloadsDocument(Uri uri) {
        return "com.android.providers.downloads.documents".equals(uri.getAuthority());
    }

    private static boolean isMediaDocument(Uri uri) {
        return "com.android.providers.media.documents".equals(uri.getAuthority());
    }


    public boolean openDir(String dirPath){
        Uri uri = Uri.parse("content://com.android.externalstorage.documents/document/primary:"+Uri.encode(dirPath));
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("*/*");
        intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, uri);
        startActivityForResult(intent, 1);
        return true;
    }



    
}
