package com.checkoutsheetshopify.shopify_sheet

import android.app.Activity
import android.util.Log
import androidx.activity.ComponentActivity
import com.shopify.checkoutkit.checkout.Checkout
import com.shopify.checkoutkit.checkout.CheckoutAppearance
import com.shopify.checkoutkit.checkout.CheckoutCompleteEvent
import com.shopify.checkoutkit.checkout.CheckoutFailureEvent
import com.shopify.checkoutkit.checkout.CheckoutHandle
import com.shopify.checkoutkit.checkout.Color
import com.shopify.checkoutkit.checkout.ColorScheme
import com.shopify.checkoutkit.checkout.DefaultCheckoutListener
import com.shopify.checkoutkit.checkout.Preloading
import com.shopify.checkoutkit.checkout.ShopifyCheckout
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.serialization.json.Json

/** ShopifySheetPlugin */
class ShopifySheetPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: Activity? = null
    private var eventSink: EventChannel.EventSink? = null
    private var checkoutHandle: CheckoutHandle? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "shopify_sheet")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "shopify_sheet_events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "launchCheckout" -> {
                val checkoutUrl = call.argument<String>("checkoutUrl")
                val configMap = call.argument<Map<String, Any>>("config")

                if (checkoutUrl != null) {
                    launchCheckout(checkoutUrl, configMap, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Checkout URL is null", null)
                }
            }

            "closeCheckout" -> closeCheckout(result)

            else -> result.notImplemented()
        }
    }

    private fun launchCheckout(checkoutUrl: String, configMap: Map<String, Any>?, result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity !is ComponentActivity) {
            result.error(
                "INVALID_CONTEXT",
                "Activity is not a ComponentActivity. Actual: ${currentActivity?.javaClass?.name}",
                null
            )
            return
        }
        try {
            applyConfiguration(configMap.orEmpty())
            checkoutHandle = ShopifyCheckout.present(checkoutUrl, currentActivity, checkoutListener)
            result.success("Checkout Launched")
        } catch (e: Exception) {
            Log.e(TAG, "Error launching checkout", e)
            result.error("CHECKOUT_ERROR", "Error launching checkout", e.message)
        }
    }

    private val checkoutListener = object : DefaultCheckoutListener() {
        override fun onCheckoutCompleted(event: CheckoutCompleteEvent) {
            sendEvent("completed", checkout = event.checkout)
        }

        override fun onCheckoutFailed(event: CheckoutFailureEvent) {
            sendEvent("failed", error = event.error.message, errorCode = event.error.code.name.lowercase())
        }

        //the buyer closed the sheet (back, close button, or the sdk closing it after a terminal failure, which reports
        //onCheckoutFailed first) — reported as `canceled`, the event name this plugin has always used for it
        override fun onCheckoutDismissed() {
            checkoutHandle = null
            sendEvent("canceled")
        }
    }

    private fun sendEvent(event: String, error: String? = null, errorCode: String? = null, checkout: Checkout? = null) {
        val payload = mutableMapOf<String, Any?>("event" to event, "error" to error)
        if (errorCode != null) payload["errorCode"] = errorCode
        if (checkout != null) {
            try {
                payload["checkout"] = Json.encodeToString(Checkout.serializer(), checkout)
            } catch (e: Exception) {
                Log.e(TAG, "Error serializing checkout", e)
            }
        }
        eventSink?.success(payload)
    }

    private fun applyConfiguration(configMap: Map<String, Any>) {
        ShopifyCheckout.configure { config ->
            val colorScheme = when (configMap["colorScheme"] as? String) {
                "light" -> ColorScheme.Light()
                "dark" -> ColorScheme.Dark()
                "web" -> null
                else -> ColorScheme.Automatic()
            }
            val headerBackground = parseColor(configMap["titleBarBackgroundColor"])
            val webViewBackground = parseColor(configMap["backgroundColor"])
            val progressIndicator = parseColor(configMap["tintColor"])
            val closeIconTint = parseColor(configMap["closeButtonTintColor"])
            config.appearance = if (colorScheme == null) {
                CheckoutAppearance.Storefront().customize {
                    headerBackground?.let { withHeaderBackgroundColor(it) }
                    webViewBackground?.let { withWebViewBackgroundColor(it) }
                    progressIndicator?.let { withProgressIndicatorColor(it) }
                closeIconTint?.let { withCloseIconTintColor(it) }
                }
            } else {
                CheckoutAppearance.App(
                    colorScheme.customize {
                        headerBackground?.let { withHeaderBackgroundColor(it) }
                        webViewBackground?.let { withWebViewBackgroundColor(it) }
                        progressIndicator?.let { withProgressIndicatorColor(it) }
                closeIconTint?.let { withCloseIconTintColor(it) }
                    }
                )
            }
            (configMap["title"] as? String)?.let { config.title = it }
            (configMap["preload"] as? Boolean)?.let { enabled -> config.preloading = Preloading { this.enabled = enabled } }
        }
    }

    private fun parseColor(value: Any?): Color? {
        val colorString = value as? String ?: return null
        return try {
            Color.SRGB(android.graphics.Color.parseColor(colorString))
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, "Invalid color format: $colorString", e)
            null
        }
    }

    private fun closeCheckout(result: MethodChannel.Result) {
        checkoutHandle?.dismiss()
        checkoutHandle = null
        result.success("Checkout Closed")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private companion object {
        const val TAG = "ShopifySheetPlugin"
    }
}
