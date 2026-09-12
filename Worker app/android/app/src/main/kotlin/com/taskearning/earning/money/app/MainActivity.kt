package com.taskearning.earning.money.app

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.taskearning.earning.money.app/package_tracker"
    private val KEYBOARD_CHANNEL = "com.taskearning.earning.money.app/review_keyboard"

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYBOARD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setActiveReview" -> {
                    val taskId = call.argument<String>("taskId") ?: ""
                    val reviewText = call.argument<String>("reviewText") ?: ""
                    val platform = call.argument<String>("platform") ?: ""

                    val prefs = getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("flutter.active_task_id", taskId)
                        .putString("flutter.active_review_text", reviewText)
                        .putString("flutter.active_platform", platform)
                        .putString("active_task_id", taskId)
                        .putString("active_review_text", reviewText)
                        .putString("active_platform", platform)
                        .apply()

                    result.success(true)
                }
                "clearActiveReview" -> {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
                    prefs.edit()
                        .remove("flutter.active_task_id")
                        .remove("flutter.active_review_text")
                        .remove("flutter.active_platform")
                        .remove("active_task_id")
                        .remove("active_review_text")
                        .remove("active_platform")
                        .apply()

                    result.success(true)
                }
                "isKeyboardEnabled" -> {
                    val imm = getSystemService(android.content.Context.INPUT_METHOD_SERVICE) as? android.view.inputmethod.InputMethodManager
                    val enabledList = imm?.enabledInputMethodList ?: emptyList()
                    val isEnabled = enabledList.any {
                        it.packageName == packageName ||
                        it.serviceName.contains("TaskReviewInputMethodService") ||
                        it.id.contains("TaskReviewInputMethodService")
                    }
                    result.success(isEnabled)
                }
                "isKeyboardSelected" -> {
                    val defaultIme = android.provider.Settings.Secure.getString(contentResolver, android.provider.Settings.Secure.DEFAULT_INPUT_METHOD) ?: ""
                    val isSelected = defaultIme.contains(packageName) || defaultIme.contains("TaskReviewInputMethodService")
                    result.success(isSelected)
                }
                "openKeyboardSettings" -> {
                    val intent = android.content.Intent(android.provider.Settings.ACTION_INPUT_METHOD_SETTINGS).apply {
                        addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "openInputMethodPicker" -> {
                    val imm = getSystemService(android.content.Context.INPUT_METHOD_SERVICE) as? android.view.inputmethod.InputMethodManager
                    imm?.showInputMethodPicker()
                    result.success(true)
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
