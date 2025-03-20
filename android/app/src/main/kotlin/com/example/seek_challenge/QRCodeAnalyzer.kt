package com.example.seek_challenge

import android.annotation.SuppressLint
import android.graphics.ImageFormat
import android.util.Log
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.nio.ByteBuffer

class QRCodeAnalyzer(private val onQRCodeDetected: (String) -> Unit) : ImageAnalysis.Analyzer {
    private val TAG = "QRCodeAnalyzer"
    private var isScanning = true
    private val barcodeScanner = BarcodeScanning.getClient()

    @SuppressLint("UnsafeOptInUsageError")
    override fun analyze(imageProxy: ImageProxy) {
        if (!isScanning) {
            imageProxy.close()
            return
        }

        Log.d(TAG, "Analizando imagen de la cámara: ${imageProxy.width}x${imageProxy.height}, formato: ${imageProxy.format}")
        
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            try {
                val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
                
                Log.d(TAG, "Procesando imagen con ML Kit para detectar QR")
                
                barcodeScanner.process(image)
                    .addOnSuccessListener { barcodes ->
                        Log.d(TAG, "Barcodes detectados: ${barcodes.size}")
                        
                        for (barcode in barcodes) {
                            Log.d(TAG, "Tipo de barcode: ${barcode.valueType}")
                            
                            // Procesar cualquier tipo de código de barras, no solo QR
                            val rawValue = barcode.rawValue
                            if (rawValue != null) {
                                Log.d(TAG, "¡QR/Barcode detectado! Valor: $rawValue")
                                isScanning = false
                                onQRCodeDetected(rawValue)
                            }
                        }
                    }
                    .addOnFailureListener { e ->
                        Log.e(TAG, "Error en ML Kit: ${e.message}", e)
                    }
                    .addOnCompleteListener {
                        imageProxy.close()
                    }
            } catch (e: Exception) {
                Log.e(TAG, "Error al procesar imagen: ${e.message}", e)
                imageProxy.close()
            }
        } else {
            Log.e(TAG, "Imagen de la cámara es null")
            imageProxy.close()
        }
    }

    fun resumeScanning() {
        isScanning = true
        Log.d(TAG, "Escaneo reanudado")
    }
}