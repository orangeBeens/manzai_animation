import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:developer' as developer;

class LoggerConfig {
  static void configureLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        developer.log(
          record.message,
          time: record.time,
          name: record.loggerName,
          level: record.level.value,
          error: record.error,
          stackTrace: record.stackTrace,
        );
      }
    });
  }

  static Logger getLogger(String name) => Logger(name);
}
