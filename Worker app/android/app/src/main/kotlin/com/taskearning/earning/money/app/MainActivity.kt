package com.taskearning.earning.money.app

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.taskearning.earning.money.app/package_tracker"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAppInstalled" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "Package name cannot be empty", null)
                        return@setMethodCallHandler
                    }
                    val isInstalled = checkAppInstalled(packageName)
                    result.success(isInstalled)
                }
                "checkInstalledPackages" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    val statusMap = HashMap<String, Boolean>()
                    for (pkg in packages) {
                        if (pkg.isNotBlank()) {
                            statusMap[pkg] = checkAppInstalled(pkg)
                        }
                    }
                    result.success(statusMap)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkAppInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        } catch (e: Exception) {
            false
        }
    }
}
