import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dotenv/dotenv.dart' show env;
import 'package:dio/dio.dart';
import 'package:web_socket_channel/io.dart';
import 'package:crypto/crypto.dart';

class ApiProvide {
  var account = env['subaccount'];
  IOWebSocketChannel channelMaster_Ftx;
  Stream streamBroadcast_Ftx;
  Dio dio = Dio();

  Future<Stream> ftx_WebSocket(String uri, String symbol,
      {List channel}) async {
    //var ping_int = Duration(seconds: 15);
    var time = DateTime.now().toUtc().millisecondsSinceEpoch;
    var messageNotencode = '${time}websocket_login';
    var data_auth = {
      'key': env['API_ftx'],
      'sign': await function_sha(messageNotencode),
      //'subaccount': account,
      'time': time
    };
    if (account != 'NO') {
      data_auth['subaccount'] = account;
    }
    var data_ftx = {'op': 'login', 'args': data_auth};
    channelMaster_Ftx = await IOWebSocketChannel.connect(uri);
    streamBroadcast_Ftx =
        await channelMaster_Ftx.stream.asBroadcastStream().handleError(onError);
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
    final response = await dio.get('${url}/${endpoint}').catchError((e) {
      print('errore ftx_Get: $e');
    });
    return response;
  }

  Future ftx_Get_Auth(String url, String endpoint, {Map data}) async {
    final time = DateTime.now().toUtc().millisecondsSinceEpoch;
    var messageNotencode = '${time}GET/api/${endpoint}';
    //var messageNotencode = '1611620261000GET/api/${endpoint}';
    if (data != null) {
      messageNotencode += '?';
      var n = 0;
      data.forEach((k, v) {
        n = n + 1;
        messageNotencode += '${k}=${v}';
        /*if (n < data.length) {
          messageNotencode += '&';
          print('messageNotencode <&>: ${messageNotencode}');
        }*/
      });
      //messageNotencode += '%!';
    }
    //print('message: ${messageNotencode}');
    final messageEncode = await function_sha(messageNotencode);
    //print('messageEncode: ${messageEncode}');
    final opt_headers = {
      'Content-Type': 'application/json',
      'FTX-KEY': env['API_ftx'],
      'FTX-SIGN': messageEncode,
      'FTX-TS': time.toString(),
    };
    if (account != 'NO') {
      opt_headers['FTX-SUBACCOUNT'] = account;
    }
    //print('headers: ${opt_headers}');
    var response = await dio
        .get('${url}/${endpoint}',
            queryParameters: data,
            options: Options(
              headers: opt_headers,
            ))
        .catchError((e) {
      print('errore ftx_Get_Auth: $e');
    });

    return response;
  }

  Future ftx_Get_Auth_spot(String url, String endpoint) async {
    final time = DateTime.now().toUtc().millisecondsSinceEpoch;
    var messageNotencode = '${time}GET/api/${endpoint}';
    //var messageNotencode = '1611620261000GET/api/${endpoint}';
    //print('message: ${messageNotencode}');
    final messageEncode = await function_sha(messageNotencode);
    //print('messageEncode: ${messageEncode}');
    final opt_headers = {
      'Content-Type': 'application/json',
      'FTX-KEY': env['API_ftx'],
      'FTX-SIGN': messageEncode,
      'FTX-TS': time.toString(),
    };
    if (account != 'NO') {
      opt_headers['FTX-SUBACCOUNT'] = account;
    }
    //print('headers: ${opt_headers}');
    //var data_open_orders = {'market': '${env['Cross_ftx']}'};
    var response;
    response = await dio
        .get('${url}/${endpoint}',
            //queryParameters: data_open_orders,
            options: Options(
              headers: opt_headers,
            ))
        .catchError((e) {
      print('errore ftx_Get_Auth_spot: $e');
    });

    //print('response: ${response}');
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
      //'FTX-SUBACCOUNT': account,
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
        .catchError((e) {
      print('errore ftx_Post_Auth: $e');
      print('errore data: $data');
      print('errore opt_headers: $opt_headers');
    });
    //print('data: ${data}');
    //print('opt_headers: $opt_headers');

    //print(DateTime.now().toUtc());
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
      //messageNotencode += '?market=${data['market']}';
    }
    var messageEncode = await function_sha(messageNotencode);
    //print(messageEncode);
    var opt_headers = {
      'FTX-KEY': env['API_ftx'],
      'FTX-SIGN': messageEncode,
      'FTX-TS': time.toString(),
      //'FTX-SUBACCOUNT': account,
    };
    if (account != 'NO') {
      opt_headers['FTX-SUBACCOUNT'] = account;
    }

    //var options = Options(contentType: 'application/json');
    await dio.delete('${url}/${endpoint}',
        queryParameters: data,
        options: Options(
          headers: opt_headers,
        ));
    //.catchError((e, s) =>
    //handleError(e, s, 'DELETE', data, txt2: '${url}/${endpoint}'));
  }

  Future<String> function_sha(String messageNotencode) async {
    final signeutf1 = utf8.encode(messageNotencode);
    final hmacSha256 = Hmac(sha256, utf8.encode(env['API_SECRET_ftx']));
    final digest = hmacSha256.convert(signeutf1);
    return digest.toString();
  }

  void onError(e, String txt_error) {
    print('error: $e');
  }
}
