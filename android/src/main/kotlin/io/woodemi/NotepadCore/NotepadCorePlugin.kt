package io.woodemi.NotepadCore

import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

private const val TAG = "NotepadCorePlugin"

class NotepadCorePlugin(context: Context) : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val methodChannel = MethodChannel(registrar.messenger(), "notepad_core/method")
            methodChannel.setMethodCallHandler(NotepadCorePlugin(registrar.context()))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "onMethodCall " + call.method)
        when (call.method) {
            "startScan" -> {
                scanner.startScan(scanCallback)
                result.success(null)
            }
            "stopScan" -> {
                scanner.stopScan(scanCallback)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    val scanner by lazy {
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothManager.adapter.bluetoothLeScanner
    }

    val scanCallback = object : ScanCallback() {
        override fun onScanFailed(errorCode: Int) {
            Log.v(TAG, "onScanFailed: $errorCode")
        }

        override fun onScanResult(callbackType: Int, result: ScanResult) {
            Log.v(TAG, "onScanResult: $callbackType + $result")
        }

        override fun onBatchScanResults(results: MutableList<ScanResult>?) {
            Log.v(TAG, "onBatchScanResults: $results")
        }
    }
}
