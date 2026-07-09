package com.flitt.mobile.GooglePayButton;

import android.app.Activity;
import android.content.Context;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.LinearLayout.LayoutParams;
import androidx.annotation.NonNull;
import com.google.android.gms.wallet.button.ButtonConstants;
import com.google.android.gms.wallet.button.ButtonOptions;
import com.google.android.gms.wallet.button.PayButton;
import org.json.JSONArray;
import java.util.ArrayList;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.plugin.common.StandardMessageCodec;

public class GooglePayButtonPlugin implements FlutterPlugin, ActivityAware {
    private MethodChannel channel;
    private Context context;
    private Activity activity;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "google_pay_button");
        context = flutterPluginBinding.getApplicationContext();
        flutterPluginBinding.getPlatformViewRegistry().registerViewFactory("google_pay_button_view", new GooglePayButtonFactory(flutterPluginBinding.getBinaryMessenger()));
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        this.activity = null;
    }

    public static class GooglePayButtonFactory extends PlatformViewFactory {
        private final MethodChannel channel;

        GooglePayButtonFactory(BinaryMessenger messenger) {
            super(StandardMessageCodec.INSTANCE);
            channel = new MethodChannel(messenger, "google_pay_button");
        }

        @NonNull
        @SuppressWarnings("unchecked")
        @Override
        public PlatformView create(@NonNull Context context, int id, @NonNull Object args) {
            Map<String, Object> params = (Map<String, Object>) args;
            return new GooglePayButtonView(context, params, channel);
        }
    }

    private static class GooglePayButtonView implements PlatformView {
        private final LinearLayout layout;
        private final PayButton googlePayButton;
        private final MethodChannel channel;

        GooglePayButtonView(Context context, Map<String, Object> params, MethodChannel channel) {
            layout = new LinearLayout(context);
            googlePayButton = new PayButton(context);
            this.channel = channel;

            ButtonOptions.Builder optionsBuilder = ButtonOptions.newBuilder();

            String type = (String) params.get("type");
            String theme = (String) params.get("theme");
            Integer borderRadius = params.get("borderRadius") != null ? ((Double) params.get("borderRadius")).intValue() : null;

            optionsBuilder.setButtonType(getButtonType(type));
            optionsBuilder.setButtonTheme(getButtonTheme(theme));

            if (borderRadius != null) {
                optionsBuilder.setCornerRadius(borderRadius);
            }

            if (params.get("allowedPaymentMethods") != null) {
                JSONArray allowedPaymentMethods = new JSONArray((ArrayList) params.get("allowedPaymentMethods"));
                optionsBuilder.setAllowedPaymentMethods(allowedPaymentMethods.toString());
            }

            ButtonOptions options = optionsBuilder.build();
            googlePayButton.initialize(options);

            // Traditional anonymous inner class implementation instead of lambda
            googlePayButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    channel.invokeMethod("onPress", null);
                }
            });

            int width = params.get("width") != null ? ((Double) params.get("width")).intValue() : LayoutParams.WRAP_CONTENT;
            int height = params.get("height") != null ? ((Double) params.get("height")).intValue() : LayoutParams.WRAP_CONTENT;
            LinearLayout.LayoutParams buttonLayoutParams = new LinearLayout.LayoutParams(width, height);
            googlePayButton.setLayoutParams(buttonLayoutParams);

            layout.addView(googlePayButton);
            layout.setLayoutParams(new LinearLayout.LayoutParams(width, height));
        }

        private int getButtonType(String type) {
            if (type != null) {
                switch (type) {
                    case "book":
                        return ButtonConstants.ButtonType.BOOK;
                    case "buy":
                        return ButtonConstants.ButtonType.BUY;
                    case "checkout":
                        return ButtonConstants.ButtonType.CHECKOUT;
                    case "donate":
                        return ButtonConstants.ButtonType.DONATE;
                    case "order":
                        return ButtonConstants.ButtonType.ORDER;
                    case "pay":
                        return ButtonConstants.ButtonType.PAY;
                    case "plain":
                        return ButtonConstants.ButtonType.PLAIN;
                    case "subscribe":
                        return ButtonConstants.ButtonType.SUBSCRIBE;
                    default:
                        return ButtonConstants.ButtonType.BUY;
                }
            }
            return ButtonConstants.ButtonType.BUY;
        }

        private int getButtonTheme(String theme) {
            if (theme != null) {
                switch (theme) {
                    case "light":
                        return ButtonConstants.ButtonTheme.LIGHT;
                    case "dark":
                        return ButtonConstants.ButtonTheme.DARK;
                    default:
                        return ButtonConstants.ButtonTheme.LIGHT;
                }
            }
            return ButtonConstants.ButtonTheme.LIGHT;
        }

        @NonNull
        @Override
        public android.view.View getView() {
            return layout;
        }

        @Override
        public void dispose() {
        }
    }
}
