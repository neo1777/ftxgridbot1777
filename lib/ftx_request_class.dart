import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dotenv/dotenv.dart';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/io.dart';

class ApiProvide {
  var account = env['subaccount'];
  IOWebSocketChannel channelMaster_Ftx;
  Stream streamBroadcast_Ftx;
  Dio dio = Dio();

  Future<Stream> ftx_WebSocket(String uri, String symbol,
      {List channel}) async {
    var time = DateTime.now().toUtc().millisecondsSinceEpoch;
    var messageNotencode = '${time}websocket_login';
    var data_auth = {
      'key': env['API_ftx'],
      'sign': await function_sha(messageNotencode),
      'time': time
    };
    if (account != 'NO') {
      data_auth['subaccount'] = account;
    }
    var data_ftx = {'op': 'login', 'args': data_auth};
    channelMaster_Ftx = await IOWebSocketChannel.connect(uri);
    streamBroadcast_Ftx = await channelMaster_Ftx.stream
        .asBroadcastStream()
        .handleError((e, s) => handleError(e, s, 'streamBroadcast_Ftx',
            'funzione ftx_WebSocket - sezione channelMaster_Ftx.stream'));
    channelMaster_Ftx.sink.add(json.encode(data_ftx));
    if (channel != null) {
      channel.forEach((v) {
        channelMaster_Ftx.sink.add(json.encode(
            {'op': 'subscribe', 'channel': '${v}', 'market': '${symbol}'}));
      });
    }
    return streamBroadcast_Ftx;
  }

  Future<Response> ftx_Get(String url, String endpoint) async {
    final response = await dio.get('${url}/${endpoint}').catchError((e, s) =>
        handleError(
            e, s, '${url}/${endpoint}', 'funzione ftx_Get - sezione dio.get'));
    return response;
  }

  Future ftx_Get_Auth(String url, String endpoint, {Map data}) async {
    final time = DateTime.now().toUtc().millisecondsSinceEpoch;
    var messageNotencode = '${time}GET/api/${endpoint}';
    if (data != null) {
      messageNotencode += '?';
      var n = 0;
      data.forEach((k, v) {
        n = n + 1;
        messageNotencode += '${k}=${v}';
      });
    }
    final messageEncode = await function_sha(messageNotencode);
    final opt_headers = {
      'Content-Type': 'application/json',
      'FTX-KEY': env['API_ftx'],
      'FTX-SIGN': messageEncode,
      'FTX-TS': time.toString(),
    };
    if (account != 'NO') {
      opt_headers['FTX-SUBACCOUNT'] = account;
    }
    final response = await dio
        .get('${url}/${endpoint}',
            queryParameters: data,
            options: Options(
              headers: opt_headers,
            ))
        .catchError((e, s) => handleError(
            e,
            s,
            ' ftx_Get_Auth ${url}/${endpoint}',
            'funzione ftx_Get_Auth - sezione dio.get'));

    return response;
  }

  Future ftx_Get_Auth_spot(String url, String endpoint) async {
    final time = DateTime.now().toUtc().millisecondsSinceEpoch;
    var messageNotencode = '${time}GET/api/${endpoint}';
    final messageEncode = await function_sha(messageNotencode);
    final opt_headers = {
      'Content-Type': 'application/json',
      'FTX-KEY': env['API_ftx'],
      'FTX-SIGN': messageEncode,
      'FTX-TS': time.toString(),
    };
    if (account != 'NO') {
      opt_headers['FTX-SUBACCOUNT'] = account;
    }
    var response;
    response = await dio
        .get('${url}/${endpoint}',
            options: Options(
              headers: opt_headers,
            ))
        .catchError((e, s) => handleError(e, s, ' ftx_Get_Auth_spot',
            'funzione ftx_Get_Auth_spot - sezione dio.get'));

    return response;
  }

  Future ftx_Post_Auth(String url, String endpoint,
      {Map data, String txt}) async {
    var time = DateTime.now().toUtc().millisecondsSinceEpoch;
    var messageNotencode = '${time}POST/api/${endpoint}';
    messageNotencode += jsonEncode(data);
    var messageEncode = await function_sha(messageNotencode);

    var opt_headers = {
      'FTX-KEY': env['API_ftx'],
      'FTX-SIGN': messageEncode,
      'FTX-TS': time.toString(),
    };
    if (account != 'NO') {
      opt_headers['FTX-SUBACCOUNT'] = account;
    }
    await Future.delayed(const Duration(milliseconds: 50));
    await dio
        .post('${url}/${endpoint}',
            data: data,
            options: Options(
              headers: opt_headers,
            ))
        .catchError((e, s) => handleError(e, s, data.toString(),
            'funzione ftx_Post_Auth - sezione dio.post'));
  }

  Future ftx_Del_Auth(String url, String endpoint, {Map data}) async {
    var time = DateTime.now().toUtc().millisecondsSinceEpoch;
    var messageNotencode = '${time}DELETE/api/${endpoint}';
    if (data != null) {
      messageNotencode += '?';
      var n = 0;
      data.forEach((k, v) {
        n++;
        messageNotencode += '${k}=${v}';
        if (n < data.length) {
          messageNotencode += '&';
        }
      });
    }
    var messageEncode = await function_sha(messageNotencode);
    var opt_headers = {
      'FTX-KEY': env['API_ftx'],
      'FTX-SIGN': messageEncode,
      'FTX-TS': time.toString(),
      //'FTX-SUBACCOUNT': account,
    };
    if (account != 'NO') {
      opt_headers['FTX-SUBACCOUNT'] = account;
    }
    await dio.delete('${url}/${endpoint}',
        queryParameters: data,
        options: Options(
          headers: opt_headers,
        ));
  }

  Future<String> function_sha(String messageNotencode) async {
    final signeutf1 = utf8.encode(messageNotencode);
    final hmacSha256 = Hmac(sha256, utf8.encode(env['API_SECRET_ftx']));
    final digest = hmacSha256.convert(signeutf1);
    return digest.toString();
  }

  Future<void> handleError(e, s, String txt, other, {txt2}) async {
    print('ERROR: ${e.toString()}');
    print('REQUEST: ${txt}');
    print('Start point: ${other}\n');
  }
}
