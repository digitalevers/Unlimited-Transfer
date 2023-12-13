package com.example.woniu;

import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.res.AssetFileDescriptor;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.StrictMode;

import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.webkit.MimeTypeMap;
import android.provider.OpenableColumns;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
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
                        } else {
                            result.notImplemented();
                        }
                    }
                }
        );
    }



    public static String getOriginFilePathByUri(Uri uri,Context context) {
        //System.out.println(uri);
        String path = null;
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
                if (isExternalStorageDocument(uri)) {
                    ///System.out.println("isExternalStorageDocument-"+uri.toString());
                    // ExternalStorageProvider
                    final String docId = DocumentsContract.getDocumentId(uri);
                    final String[] docIdSplit = docId.split(":");
                    final String[] uriSplit = uri.toString().split(":");
                    if ("primary".equalsIgnoreCase(docIdSplit[0])) {
                        path = Environment.getExternalStorageDirectory() + "/" + uriSplit[2];
                        return path;
                    }
                    
                } else if (isDownloadsDocument(uri)) {
                    System.out.println("isDownloadsDocument-"+uri.toString());
                    // DownloadsProvider 
                    final String id = DocumentsContract.getDocumentId(uri);
                    //Android12 适配(只能返回文件名 无法获取文件路径 但是可以使用 openAssetFileDescriptor 直接读取文件文件 参见flutter插件 uri_to_file 的Android源代码)
                    //Android12及以上 都先复制到私域空间然后返回以/data/data开头的私域路径
                    if(Build.VERSION.SDK_INT >= 31){
                        //System.out.println(uri);
                        Uri contentUri = null;
                        if(id.contains(":")){
                            String[] split = id.split(":");
                            contentUri = Uri.parse("content://com.android.providers.downloads.documents/document/msf%3A"+split[1]);
                        } else {
                            contentUri = ContentUris.withAppendedId(Uri.parse("content://com.android.providers.downloads.documents/document"), Long.valueOf(id));
                        } 
                        //System.out.println(contentUri);
                        Cursor cursor = context.getContentResolver().query(contentUri, null, null, null, null);
                        if (cursor != null) {
                            if (cursor.moveToFirst()) {
                                int columnIndex = cursor.getColumnIndexOrThrow("_display_name");
                                String fileName = cursor.getString(columnIndex);
                                //System.out.println(fileName);
                                if(fileName != null && !fileName.isEmpty()) {
                                    String name = fileName.substring(0, fileName.lastIndexOf('.'));
                                    String ext = fileName.substring(fileName.lastIndexOf('.'));
                                    try {
                                        path = copyFileToPrivateSpace(context, contentUri, name, ext);
                                    } catch (Exception e){
                                        System.out.println(e.getMessage());
                                    }
                                } else {
                                    System.out.println("file name is empty");
                                }
                            }
                            cursor.close();
                        }
                    } else {
                        final Uri contentUri = ContentUris.withAppendedId(Uri.parse("content://downloads/public_downloads"),Long.valueOf(id));
                        path = getDataColumn(context, contentUri, null, null);
                    }
                    return path;
                } else if (isMediaDocument(uri)) {
                    System.out.println("isMediaDocument-"+uri.toString());
                    // MediaProvider
                    final String docId = DocumentsContract.getDocumentId(uri);
                    final String[] split = docId.split(":");
                    final String type = split[0];
                    Uri contentUri = null;
                    if ("image".equals(type)) {
                        contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
                    } else if ("video".equals(type)) {
                        contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
                    } else if ("audio".equals(type)) {
                        contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
                    }
                    final String selection = "_id=?";
                    final String[] selectionArgs = new String[]{split[1]};
                    path = getDataColumn(context, contentUri, selection, selectionArgs);
                    return path;
                }
//            } else {

//            }
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
}
