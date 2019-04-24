import 'dart:async';

import 'package:flutter/services.dart';

class FlutterAjQrscan {
  static const MethodChannel _channel =
      const MethodChannel('flutter_aj_qrscan');
  static const CameraAccessDenied = 'PERMISSION_NOT_GRANTED';

  static Future<String> qrScan() async => await _channel.invokeMethod('aj_qr_scan');

}
