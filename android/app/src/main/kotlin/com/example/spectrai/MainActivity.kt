package com.example.spectrai

import android.content.Context
import android.os.Build
import android.telephony.CellInfo
import android.telephony.CellInfoLte
import android.telephony.TelephonyManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.signal/info"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSignalInfo") {
                try {
                    val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                    val response = HashMap<String, Any?>()

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                        tm.allCellInfo?.forEach { cellInfo ->
                            if (cellInfo is CellInfoLte) {
                                val cellSignal = cellInfo.cellSignalStrength
                                val cellIdentity = cellInfo.cellIdentity

                                response["dbm"] = cellSignal.dbm
                                response["rsrp"] = cellSignal.rsrp
                                response["rsrq"] = cellSignal.rsrq
                                response["pci"] = cellIdentity.pci

                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    response["earfcn"] = cellIdentity.earfcn
                                    response["bandwidth"] = cellIdentity.bandwidth
                                }
                            }
                        }
                    }

                    result.success(response)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Signal info not available", e)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}