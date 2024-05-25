package jp.picpie.book_scan_camera;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

import android.util.Log;
import android.os.Handler;
import android.os.Looper;
import android.view.KeyEvent;

import android.content.Intent;
import android.app.Activity;
import android.content.Context;
import android.net.Uri;
import androidx.documentfile.provider.DocumentFile;
import android.provider.DocumentsContract;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

import org.json.JSONObject;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.nio.channels.FileChannel;


public class MainActivity extends FlutterActivity {
	private static final String CHANNEL = "jp.picpie.book_scan_camera/saf";
    static MethodChannel mChannel;

    private static final int DIRECTORY_PICKER_REQUEST = 1;
    private Result pendingResult;

    static int lastkeycode = 0;

    @Override
    public void configureFlutterEngine( FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        mChannel = 
            new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);

        mChannel.setMethodCallHandler(
              (call, result) -> {
                  if(call.method.equals("selectDirectory")){
                    selectDirectory(result);
                  }else
                  if(call.method.equals("makeDirectoryList")){
                    String uri = call.argument("uri");
                    makeDirectoryList(this,uri);
                  }else
                  if(call.method.equals("getFileTextUri")){
                    String uri = call.argument("uri");
                    getFileTextUri(this,uri,result);
                  }else
                  if(call.method.equals("getFileText")){
                    String uri = call.argument("uri");
                    String filename = call.argument("filename");
                    getFileText(this,uri,filename,result);
                  }else
                  if(call.method.equals("putFileText")){
                    String uri = call.argument("uri");
                    String filename = call.argument("filename");
                    String outtext = call.argument("outtext");
                    Log.d("putFileText outtext", outtext);
                    putFileText(this,uri,filename,outtext,result);
                  }else
                  if(call.method.equals("putFileTextUri")){
                    String diruri = call.argument("diruri");
                    String uri = call.argument("uri");
                    String filename = call.argument("filename");
                    String outtext = call.argument("outtext");
                    Log.d("putFileText outtext", outtext);
                    putFileTextUri(this,diruri,uri,filename,outtext,result);
                  }else
                  if(call.method.equals("putFileUri")){
                    String diruri = call.argument("diruri");
                    String uri = call.argument("uri");
                    String filename = call.argument("filename");
                    String mimetype = call.argument("mimetype");
                    String outtext = call.argument("outtext");
                    Log.d("putFileUri outtext", outtext);
                    putFileUri(this,diruri,uri,mimetype,filename,outtext,result);
                  }else
                  if(call.method.equals("copyToPrivate")){
                    String uri = call.argument("uri");
                    String filename = call.argument("filename");
                    String targetpath = call.argument("targetpath");
                    copyToPrivate(this,uri,filename,targetpath,result);
                  }else
                  if(call.method.equals("copyToPublic")){
                    String diruri = call.argument("diruri");
                    String mimetype = call.argument("mimetype");
                    String filename = call.argument("filename");
                    String srcpath = call.argument("srcpath");
                    copyToPublic(this,diruri,mimetype,filename,srcpath,result);
                  }else
                  if(call.method.equals("getKeyCode")){
                    result.success(String.valueOf(lastkeycode));
                    lastkeycode = 0;
                  }
              }
            );
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getAction() == KeyEvent.ACTION_DOWN) {
            lastkeycode = event.getKeyCode();

            switch (event.getKeyCode()) {
                case KeyEvent.KEYCODE_VOLUME_UP:
                    mChannel.invokeMethod("onVUP", String.valueOf( event.getKeyCode() ));
                    return true;
                case KeyEvent.KEYCODE_VOLUME_DOWN:
                    mChannel.invokeMethod("onVDOWN", String.valueOf( event.getKeyCode() ));
                    return true;
            }
            
            return true;
        }
        return super.dispatchKeyEvent(event);
    }

    private void selectDirectory(Result result) {
        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "Directory picker is already active", null);
            return;
        }

        pendingResult = result;
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        startActivityForResult(intent, DIRECTORY_PICKER_REQUEST);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        Log.d("onActivityResult", "data.getData(): " + data.getData().toString());
        if (requestCode == DIRECTORY_PICKER_REQUEST) {
            if (pendingResult != null) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    String uri="";
                    if(data.getData()!=null){
                        uri = data.getData().toString();
                    }
                    pendingResult.success(uri);
                } else {
                    pendingResult.success("");
                }
                pendingResult = null;
            }
        }
    }

    private void makeDirectoryList(Context context, String uri) {
        new Thread(() -> {
            DocumentFile pickedDir = DocumentFile.fromTreeUri(context, Uri.parse(uri));
            StringBuilder flist = new StringBuilder();
            if (pickedDir != null && pickedDir.isDirectory()) {
                for (DocumentFile file : pickedDir.listFiles()) {
                    if (file.isFile()) {
                        JSONObject jsonObject = new JSONObject();
                        try{
                        jsonObject.put("name", file.getName());
                        jsonObject.put("size", file.length());
                        jsonObject.put("lastModified", file.lastModified());
                        jsonObject.put("type", file.getType());
                        jsonObject.put("uri", file.getUri());
                        
                        String jsonString = jsonObject.toString();

                        flist.append(jsonString).append("\n");
                        }catch(Exception e){
                           flist.append(e.toString()).append("\n"); 
                        }
                    }
                }
            }

            // メインスレッドで結果を送信
            new Handler(Looper.getMainLooper()).post(() -> mChannel.invokeMethod("dirlistOK", flist.toString() ));
        }).start();
    }

    Uri findFileUri(Context context, String directoryUriStr, String filename){
        Uri treeUri = Uri.parse(directoryUriStr);
        DocumentFile pickedDir = DocumentFile.fromTreeUri(context, treeUri);

        if (pickedDir != null && pickedDir.isDirectory()) {
            for (DocumentFile file : pickedDir.listFiles()) {
                if (file.isFile()) {
                    if(file.getName().equals(filename)){
                        return file.getUri();
                    }
                }
            }
        }
        return null;
    }

    private void getFileTextUri(Context context, String uri, Result result) {

        StringBuilder stringBuilder = new StringBuilder();
        Uri treeUri = Uri.parse(uri);
        try (InputStream inputStream = context.getContentResolver().openInputStream(treeUri);
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream))) {

            String line;
            while ((line = reader.readLine()) != null) {
                stringBuilder.append(line).append("\n");
            }
            result.success(stringBuilder.toString());
        }catch(IOException e){
            result.error("ERROR", "File read failed: " + e.getMessage(), null);
        }
    }

    private void getFileText(Context context, String dirUriStr, String filename, Result result) {
        Uri treeUri = findFileUri(context, dirUriStr, filename);
        if(treeUri==null){
            result.error("ERROR", "File not found" , null);
            return;
        }

        StringBuilder stringBuilder = new StringBuilder();
        try (InputStream inputStream = context.getContentResolver().openInputStream(treeUri);
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream))) {

            String line;
            while ((line = reader.readLine()) != null) {
                stringBuilder.append(line).append("\n");
            }
            result.success(stringBuilder.toString());
        }catch(IOException e){
            result.error("ERROR", "File read failed: " + e.getMessage(), null);
        }
    }

    private void putFileText(Context context, String dirUriStr, String filename, String outtext, Result result) {
        Uri uri = findFileUri( context, dirUriStr, filename);
        putFileTextUri(context, dirUriStr, uri.toString(), filename, outtext, result);
    }


    private void putFileTextUri(Context context, String dirUriStr, String uristr, String filename, String outtext, Result result) {
        putFileUri( context,  dirUriStr,  uristr,  "text/plain",  filename,  outtext,  result);
    }

    private void putFileUri(Context context, String dirUriStr, String uristr, String mimeType, String filename, String outtext, Result result) {
        removeFile( context, uristr);
        /*
        Uri uri = null;
        if(uristr!=null){
            uri = Uri.parse(uristr);
        }
        if(uri != null){
            try {
                DocumentsContract.deleteDocument(context.getContentResolver(), uri);
                Log.d("putFileText deleteDocument",uri.toString());
            } catch (IOException e) {
                // ファイルが見つからない場合のエラーハンドリング
                result.error("ERROR", "File not found for deletion: " + e.getMessage(), null);
                return;
            }
        }
*/
        Uri treeUri = Uri.parse(dirUriStr);
        DocumentFile pickedDir = DocumentFile.fromTreeUri(context, treeUri);
        DocumentFile newFile = pickedDir.createFile(mimeType, filename);
        Uri newuri = newFile.getUri();
        Log.d("putFileText newFile ",newuri.toString());

        try (OutputStream outputStream = context.getContentResolver().openOutputStream(newuri);
                OutputStreamWriter writer = new OutputStreamWriter(outputStream)) {

            writer.write(outtext);
            writer.flush();
            Log.d("putFileText writer",outtext);

            result.success(newuri.toString());
        }catch(IOException e){
            result.error("ERROR", "File write failed: " + e.getMessage(), null);
        }
    }

    private void copyToPrivate(Context context, String dirUriStr, String filename, String targetpath, Result result){
        Uri sourceUri = findFileUri( context, dirUriStr, filename);
        DocumentFile sourceFile = DocumentFile.fromSingleUri(context, sourceUri);

        if (sourceFile != null && sourceFile.canRead()) {
            try (InputStream inputStream = context.getContentResolver().openInputStream(sourceUri); ) {
                File file = new java.io.File(targetpath);
                OutputStream outputStream = new FileOutputStream(file);

                byte[] buffer = new byte[1024*1024];
                int length;
                while ((length = inputStream.read(buffer)) > 0) {
                    outputStream.write(buffer, 0, length);
                }
                result.success(file.getAbsolutePath());
            } catch (IOException e) {
                e.printStackTrace();
                result.error("ERROR", "File write failed: " + e.getMessage(), null);
            }
            //result.success("OK");
        } else {
            // ファイルにアクセスできない場合の処理
            result.error("ERROR", "File read failed: " + filename, null);
        }

        mChannel.invokeMethod("copyOK", targetpath );
    }

/* 
    public static boolean copyFileToSharedStorage(Context context, String srcFilePath, Uri destDirUri, String destFileName) {
        File srcFile = new File(srcFilePath);
        if (!srcFile.exists()) {
            return false;
        }

        // Determine the MIME type from the file extension
        String mimeType = getMimeType(srcFilePath);
        if (mimeType == null) {
            mimeType = "application/octet-stream";
        }

        ContentResolver contentResolver = context.getContentResolver();
        Uri destFileUri = createFileInDirectory(contentResolver, destDirUri, destFileName, mimeType);

        if (destFileUri == null) {
            return false;
        }

        try (InputStream inputStream = new FileInputStream(srcFile);
             OutputStream outputStream = contentResolver.openOutputStream(destFileUri)) {

            if (outputStream == null) {
                return false;
            }

            byte[] buffer = new byte[1024];
            int length;
            while ((length = inputStream.read(buffer)) > 0) {
                outputStream.write(buffer, 0, length);
            }

            return true;
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }

    private static String getMimeType(String filePath) {
        String extension = MimeTypeMap.getFileExtensionFromUrl(filePath);
        if (extension != null) {
            return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.toLowerCase());
        }
        return null;
    }

    private static Uri createFileInDirectory(ContentResolver contentResolver, Uri dirUri, String fileName, String mimeType) {
        ContentValues contentValues = new ContentValues();
        contentValues.put(DocumentsContract.Document.COLUMN_DISPLAY_NAME, fileName);
        contentValues.put(DocumentsContract.Document.COLUMN_MIME_TYPE, mimeType);

        try {
            return contentResolver.insert(dirUri, contentValues);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
*/
    private void copyToPublic(Context context, String dirUriStr, String mimeType, String filename, String srcpath, Result result){

        Uri treeUri = Uri.parse(dirUriStr);
        DocumentFile pickedDir = DocumentFile.fromTreeUri(context, treeUri);
        DocumentFile newFile = pickedDir.createFile(mimeType, filename);

        if (newFile == null) {
            // Handle the case where the DocumentFile could not be created.
            result.error("ERROR", "File create failed: ", null);
            return;
        }
        Uri newDocUri = newFile.getUri();

        try (FileChannel srcChannel = new FileInputStream(srcpath).getChannel();
             FileOutputStream outputStream = (FileOutputStream) context.getContentResolver().openOutputStream(newDocUri);
             FileChannel destChannel = outputStream.getChannel()) {
            destChannel.transferFrom(srcChannel, 0, srcChannel.size());
        } catch (FileNotFoundException e) {
            // Handle the case where the file could not be found.
            e.printStackTrace();
            result.error("ERROR", "File create failed: FileNotFound", null);
            return;
        } catch (IOException e) {
            // Handle other I/O errors.
            e.printStackTrace();
            result.error("ERROR", "File create failed:  I/O errors", null);
            return;
        }
        result.success("OK");
    }

    void removeFile(Context context, String uristr){
        Uri uri = null;
        if(uristr!=null){
            uri = Uri.parse(uristr);
        }else{
            return;
        }
        if(uri != null){
            try {
                DocumentsContract.deleteDocument(context.getContentResolver(), uri);
                Log.d("putFileText deleteDocument",uri.toString());
            } catch (IOException e) {
                // ファイルが見つからない場合のエラーハンドリング
                //result.error("ERROR", "File not found for deletion: " + e.getMessage(), null);
                return;
            }
        }
    }

}
