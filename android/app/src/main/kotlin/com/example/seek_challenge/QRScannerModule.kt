package com.example.seek_challenge


import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.SurfaceTexture
import android.util.Log
import android.util.Size
import android.view.Surface
import androidx.annotation.NonNull
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class QRScannerModule : FlutterPlugin, MethodCallHandler, ActivityAware {
    private val TAG = "QRScannerModule"
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private lateinit var cameraExecutor: ExecutorService
    private var cameraProvider: ProcessCameraProvider? = null
    
    // Variables para manejo de textura
    private var flutterTextureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var surfaceTexture: SurfaceTexture? = null
    private var preview: Preview? = null
    
    // Referencia al FlutterPluginBinding para acceder al TextureRegistry
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Adjuntando QRScannerModule al motor Flutter")
        channel = MethodChannel(binding.binaryMessenger, "com.example.seek_challenge/qr_scanner")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
        cameraExecutor = Executors.newSingleThreadExecutor()
        flutterPluginBinding = binding
        Log.d(TAG, "QRScannerModule adjuntado correctamente")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d(TAG, "Llamada de método recibida: ${call.method}")
        when (call.method) {
            "startScan" -> {
                startQRScanner(result)
            }
            "stopScan" -> {
                stopQRScanner(result)
            }
            else -> {
                Log.w(TAG, "Método no implementado: ${call.method}")
                result.notImplemented()
            }
        }
    }

    private fun startQRScanner(result: Result) {
        Log.d(TAG, "Iniciando escáner QR")
        activity?.let {
            // Verificar permisos antes de continuar
            if (ContextCompat.checkSelfPermission(it, Manifest.permission.CAMERA) 
                != PackageManager.PERMISSION_GRANTED) {
                
                Log.e(TAG, "No se tienen permisos de cámara")
                result.error("PERMISSION_ERROR", "No se han concedido permisos de cámara", null)
                return
            }
            
            try {
                // Liberar recursos previos si existen
                stopQRScannerInternal()
                
                // Crear una textura para mostrar el preview de la cámara en Flutter
                flutterTextureEntry = flutterPluginBinding.textureRegistry.createSurfaceTexture()
                surfaceTexture = flutterTextureEntry?.surfaceTexture()
                
                if (surfaceTexture == null) {
                    Log.e(TAG, "No se pudo crear la textura")
                    result.error("TEXTURE_ERROR", "No se pudo crear la textura", null)
                    return
                }
                
                // Configurar el tamaño de la textura
                surfaceTexture?.setDefaultBufferSize(1280, 720)
                
                val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
                
                cameraProviderFuture.addListener({
                    try {
                        cameraProvider = cameraProviderFuture.get()
                        
                        // Configurar el preview con una implementación más simple
                        preview = Preview.Builder()
                            .setTargetResolution(Size(1280, 720))
                            .build()
                        
                        val surface = Surface(surfaceTexture)
                        preview?.setSurfaceProvider { request ->
                            request.provideSurface(surface, cameraExecutor) { }
                        }
                        
                        val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
                        
                        val imageAnalysis = ImageAnalysis.Builder()
                            .setTargetResolution(Size(1280, 720))
                            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                            .build()
                            .also { analysis ->
                                analysis.setAnalyzer(cameraExecutor, QRCodeAnalyzer { qrCode ->
                                    Log.d(TAG, "QR Code detectado: $qrCode")
                                    activity?.runOnUiThread {
                                        channel.invokeMethod("onQRCodeDetected", qrCode)
                                    }
                                })
                            }
                        
                        cameraProvider?.unbindAll()
                        cameraProvider?.bindToLifecycle(
                            it as LifecycleOwner,
                            cameraSelector,
                            preview,
                            imageAnalysis
                        )
                        
                        Log.d(TAG, "Escáner QR iniciado correctamente")
                        
                        // Devolver el ID de textura a Flutter para mostrar el preview
                        val texId = flutterTextureEntry?.id() ?: -1L
                        Log.d(TAG, "ID de textura generado: $texId")
                        
                        // Esta es la línea clave: usar un HashMap<String, Any> que sea compatible con Dart
                        val map = HashMap<String, Any>()
                        map["textureId"] = texId
                        
                        result.success(map)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error al iniciar cámara: ${e.message}", e)
                        result.error("CAMERA_ERROR", e.message, null)
                    }
                }, ContextCompat.getMainExecutor(context))
            } catch (e: Exception) {
                Log.e(TAG, "Error general al iniciar escáner QR: ${e.message}", e)
                result.error("CAMERA_ERROR", e.message, null)
            }
        } ?: run {
            Log.e(TAG, "Activity es null, no se puede iniciar escáner")
            result.error("ACTIVITY_NULL", "Activity is null", null)
        }
    }

    private fun stopQRScannerInternal() {
        try {
            cameraProvider?.unbindAll()
            preview = null
            
            if (flutterTextureEntry != null) {
                flutterTextureEntry?.release()
                flutterTextureEntry = null
            }
            
            surfaceTexture = null
        } catch (e: Exception) {
            Log.e(TAG, "Error al detener cámara internamente: ${e.message}", e)
        }
    }

    private fun stopQRScanner(result: Result) {
        Log.d(TAG, "Deteniendo escáner QR")
        try {
            stopQRScannerInternal()
            Log.d(TAG, "Escáner QR detenido correctamente")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error al detener cámara: ${e.message}", e)
            result.error("CAMERA_ERROR", e.message, null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Desacoplando QRScannerModule del motor Flutter")
        channel.setMethodCallHandler(null)
        cameraExecutor.shutdown()
        
        // Liberar la textura si existe
        stopQRScannerInternal()
        
        Log.d(TAG, "QRScannerModule desacoplado correctamente")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "QRScannerModule adjuntado a Activity")
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "QRScannerModule desacoplado de Activity por cambios de configuración")
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "QRScannerModule re-adjuntado a Activity después de cambios de configuración")
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        Log.d(TAG, "QRScannerModule desacoplado de Activity")
        activity = null
    }
}