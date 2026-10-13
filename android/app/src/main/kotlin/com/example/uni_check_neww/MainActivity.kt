package com.example.uni_check_neww

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "share_channel"


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "shareFile") {
                    println("🔥 shareFile CHIAMATO!")


                    val filePath = call.argument<String>("filePath")
                    val text = call.argument<String>("text")

                    if (filePath != null) {
                        val file = File(filePath)

                        val uri: Uri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            file
                        )

                        val intent = Intent(Intent.ACTION_SEND)
                        intent.type =
                            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                        intent.putExtra(Intent.EXTRA_STREAM, uri)
                        intent.putExtra(Intent.EXTRA_TEXT, text)
                        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

                        startActivity(Intent.createChooser(intent, "Condividi file"))
                        result.success(null)
                    } else {
                        result.error("ERRORE", "filePath nullo", null)
                    }
                }
            }
    }
}
