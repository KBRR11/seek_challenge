package com.example.seek_challenge

import android.app.Activity
import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executor

class BiometricModule : FlutterPlugin, MethodCallHandler, ActivityAware {
    private val TAG = "BiometricModule"
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private lateinit var executor: Executor

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Adjuntando BiometricModule al motor Flutter")
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.seek_challenge/biometrics")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        Log.d(TAG, "BiometricModule adjuntado correctamente")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d(TAG, "Llamada de método recibida: ${call.method}")
        when (call.method) {
            "isBiometricAvailable" -> {
                checkBiometricAvailability(result)
            }
            "authenticateWithBiometrics" -> {
                authenticateWithBiometrics(result)
            }
            else -> {
                Log.w(TAG, "Método no implementado: ${call.method}")
                result.notImplemented()
            }
        }
    }

    private fun checkBiometricAvailability(result: Result) {
        Log.d(TAG, "Verificando disponibilidad de biometría")
        try {
            val biometricManager = BiometricManager.from(context)
            val canAuthenticate = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            
            Log.d(TAG, "Resultado de disponibilidad biométrica: $canAuthenticate")
            
            when (canAuthenticate) {
                BiometricManager.BIOMETRIC_SUCCESS -> {
                    Log.d(TAG, "Biometría disponible")
                    result.success(true)
                }
                else -> {
                    Log.d(TAG, "Biometría no disponible, código: $canAuthenticate")
                    result.success(false)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error verificando disponibilidad biométrica: ${e.message}", e)
            result.error("BIOMETRIC_ERROR", "Error al verificar disponibilidad: ${e.message}", null)
        }
    }

    private fun authenticateWithBiometrics(result: Result) {
        Log.d(TAG, "Iniciando autenticación biométrica")
        activity?.let {
            try {
                executor = ContextCompat.getMainExecutor(context)
                
                val promptInfo = BiometricPrompt.PromptInfo.Builder()
                    .setTitle("Autenticación Biométrica")
                    .setSubtitle("Autentícate para acceder a la aplicación")
                    .setNegativeButtonText("Usar PIN")
                    .build()
                
                val biometricPrompt = BiometricPrompt(it as FragmentActivity, executor,
                    object : BiometricPrompt.AuthenticationCallback() {
                        override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                            super.onAuthenticationError(errorCode, errString)
                            Log.e(TAG, "Error de autenticación biométrica: $errorCode - $errString")
                            result.error("BIOMETRIC_ERROR", errString.toString(), null)
                        }

                        override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                            super.onAuthenticationSucceeded(authResult)
                            Log.d(TAG, "Autenticación biométrica exitosa")
                            result.success(true)
                        }

                        override fun onAuthenticationFailed() {
                            super.onAuthenticationFailed()
                            Log.w(TAG, "Autenticación biométrica fallida")
                            // No hacer nada aquí, esperar más intentos
                        }
                    })
                
                biometricPrompt.authenticate(promptInfo)
            } catch (e: Exception) {
                Log.e(TAG, "Error durante autenticación biométrica: ${e.message}", e)
                result.error("BIOMETRIC_ERROR", "Error durante autenticación: ${e.message}", null)
            }
        } ?: run {
            Log.e(TAG, "Activity es null, no se puede autenticar")
            result.error("ACTIVITY_NULL", "Activity is null", null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Desacoplando BiometricModule del motor Flutter")
        channel.setMethodCallHandler(null)
        Log.d(TAG, "BiometricModule desacoplado correctamente")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "BiometricModule adjuntado a Activity")
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "BiometricModule desacoplado de Activity por cambios de configuración")
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "BiometricModule re-adjuntado a Activity después de cambios de configuración")
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        Log.d(TAG, "BiometricModule desacoplado de Activity")
        activity = null
    }
}