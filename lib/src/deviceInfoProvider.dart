import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import './sdk_version.dart';

class DeviceInfoProvider {
  final BuildContext? context;
  final String _deviceIdFile = 'device_id.txt';

  DeviceInfoProvider({this.context});

  Future<Map<String, dynamic>> createDeviceFingerprint() async {
    final Map<String, dynamic> root = {};
    final Map<String, dynamic> data = {};

    final packageInfo = await PackageInfo.fromPlatform();

    final deviceId = await getDeviceId();
    data['user_agent'] = getUserAgent();
    data['language'] = PlatformDispatcher.instance.locale.toString();

    final size = getScreenDimensions();
    data['resolution'] = [size.width.round(), size.height.round()];

    data['timezone_offset'] = -DateTime.now().timeZoneOffset.inMinutes;
    data['sdk'] = "flutter-sdk";
    data['sdk_version'] = FlittMobileSdk.version;
    data['platform_name'] = kIsWeb ? 'web' : defaultTargetPlatform.toString().split('.').last.toLowerCase();
    data['platform_version'] = packageInfo.version;
    data['platform_os'] = getPlatformOS();
    data['platform_product'] = packageInfo.buildNumber;
    data['platform_type'] = getDeviceType(size);

    root['id'] = deviceId;
    root['data'] = data;

    return root;
  }

  Future<String> getDeviceId() async {
    final file = File('${Directory.systemTemp.path}/$_deviceIdFile');
    if (await file.exists()) {
      return await file.readAsString();
    } else {
      final id = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      await file.writeAsString(id);
      return id;
    }
  }

  String getUserAgent() {
    if (kIsWeb) return "Mozilla/5.0 (Flutter Web)";
    if (Platform.isAndroid) return "Mozilla/5.0 (Linux; Android) FlutterApp";
    if (Platform.isIOS) return "Mozilla/5.0 (iPhone; CPU iOS) FlutterApp";
    return "FlutterApp";
  }

  Size getScreenDimensions() {
    if (context != null) {
      return MediaQuery.of(context!).size;
    } else {
      return window.physicalSize / window.devicePixelRatio;
    }
  }

  String getPlatformOS() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  String getDeviceType(Size screenSize) {
    final shortestSide = screenSize.shortestSide;
    if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return 'desktop';
    } else if (shortestSide < 600) {
      return 'mobile';
    } else {
      return 'tablet';
    }
  }

  Future<String> getEncodedDeviceFingerprint() async {
    final fingerprint = await createDeviceFingerprint();
    return base64Encode(utf8.encode(jsonEncode(fingerprint)));
  }
}
