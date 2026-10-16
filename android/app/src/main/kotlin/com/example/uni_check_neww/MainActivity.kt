package com.example.uni_check_neww

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    //NOME CANALE DI COMUNICAZIONE
    private val CHANNEL = "share_channel"


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        //CREAZIONE DEL PONTE DI COMUNICAZIONE
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                //SE FLUTTER CHIAMA INOKEMETHOD ANDORID ENTRA QUI
                if (call.method == "shareFile") {

                    //RECUPERA PERCORSO DEL FILE EXCEL E IL TESTO DA ALLEGARE
                    val filePath = call.argument<String>("filePath")
                    val text = call.argument<String>("text")

                    if (filePath != null) {
                        //CREO OGGETTO FILE
                        val file = File(filePath)

                        //FILEPROVIDER CREA UN URI SICURO PER ESSERE CONDIVISO
                        val uri: Uri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            file
                        )

                        //ESEGUE LA CONDIVISIONE
                        val intent = Intent(Intent.ACTION_SEND)
                        //TIPO DEL FILE
                        intent.type =
                            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                        //ALLEGO FILE TRAMITE URI
                        intent.putExtra(Intent.EXTRA_STREAM, uri)
                        intent.putExtra(Intent.EXTRA_TEXT, text)
                        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

                        //APRE MENU DI CONDIVISIONE
                        startActivity(Intent.createChooser(intent, "Condividi file"))
                        result.success(null)
                    } else {
                        result.error("ERRORE", "filePath nullo", null)
                    }
                }
            }
    }
}
