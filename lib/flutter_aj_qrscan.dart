import 'dart:async';

import 'package:flutter/services.dart';

class FlutterAjQrscan {
  static const CameraAccessDenied = 'PERMISSION_NOT_GRANTED';
  static const MethodChannel _channel =
      const MethodChannel('flutter_aj_qrscan');

  static Future<String> qrscan() async => await _channel.invokeMethod('scan');
}
