package com.example.seek_challenge

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterFragmentActivity() {
    private val TAG = "MainActivity"
    private val CAMERA_REQUEST_CODE = 100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate")
        
        // Verificar y solicitar permisos de cámara al iniciar
        checkPermissions()
    }
    
    private fun checkPermissions() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) 
            != PackageManager.PERMISSION_GRANTED) {
            
            Log.d(TAG, "Solicitando permisos de cámara")
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CAMERA),
                CAMERA_REQUEST_CODE
            )
        } else {
            Log.d(TAG, "Permisos de cámara ya concedidos")
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == CAMERA_REQUEST_CODE) {
            if ((grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)) {
                Log.d(TAG, "Permiso de cámara concedido")
            } else {
                Log.e(TAG, "Permiso de cámara denegado")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.d(TAG, "Configurando Flutter Engine")
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
            Log.d(TAG, "Plugins generados registrados correctamente")
        } catch (e: Exception) {
            Log.e(TAG, "Error al registrar plugins generados: ${e.message}", e)
        }

        // Registrar módulos nativos
        try {
            flutterEngine.plugins.add(BiometricModule())
            Log.d(TAG, "BiometricModule registrado correctamente")
        } catch (e: Exception) {
            Log.e(TAG, "Error al registrar BiometricModule: ${e.message}", e)
        }

        try {
            flutterEngine.plugins.add(QRScannerModule())
            Log.d(TAG, "QRScannerModule registrado correctamente")
        } catch (e: Exception) {
            Log.e(TAG, "Error al registrar QRScannerModule: ${e.message}", e)
        }
        
        Log.d(TAG, "Configuración de Flutter Engine completada")
    }
}