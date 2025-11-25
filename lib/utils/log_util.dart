// lib/utils/log_util.dart
import 'package:flutter/foundation.dart';

void appLog(String message) {
  if (kDebugMode) {
    debugPrint('APP LOG: $message');
  }
}