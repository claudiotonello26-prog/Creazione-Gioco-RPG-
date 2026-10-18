import 'dart:async';

import 'package:iron_oath/core/i18n.dart';

/// I test leggono i testi in italiano: il "telefono" dei test parla italiano.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  systemLang = () => Lang.it;
  await testMain();
}
