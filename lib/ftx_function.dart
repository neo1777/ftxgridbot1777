import 'dart:convert';

import 'package:pausable_timer/pausable_timer.dart';

import 'class_ftx.dart';
import 'ftx_function_base.dart';
import 'ftx_request_class.dart';
import 'package:dotenv/dotenv.dart';

Future run() async {
  load();
  var ftxApi = ApiProvide();
  var data = PrimitiveWrapper();
  await funzione_market_init(ftxApi, data);
}
