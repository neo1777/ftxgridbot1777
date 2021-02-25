import 'dart:convert';
import 'class_ftx.dart';
import 'ftx_request_class.dart';
import 'package:dotenv/dotenv.dart';
import 'package:decimal/decimal.dart';

var versione = 'v8.02';

Future funzione_market_init(ApiProvide ftxApi, PrimitiveWrapper data) async {
  var market_single =
      await ftxApi.ftx_Get(env['URL_ftx'], 'markets/${env['Cross_ftx']}');
  final market = marketFromMap(json.encode(market_single.data));
  data.increment_base =
      Decimal.parse(market.result_m.priceIncrement.toString());
  data.increment = data.increment_base * Decimal.parse(env['distance_ord']);
  data.ask_start = market.result_m.ask;
  data.bid_start = market.result_m.bid;
  data.type = market.result_m.type;
  data.sizeIncrement = market.result_m.sizeIncrement.toString();
  data.size_base =
      Decimal.parse(env['size']) * Decimal.parse(data.sizeIncrement);
  data.size_buy =
      Decimal.parse(env['size']) * Decimal.parse(data.sizeIncrement);
  data.size_sell =
      Decimal.parse(env['size']) * Decimal.parse(data.sizeIncrement);
  data.size_add =
      Decimal.parse(env['size_add']) * Decimal.parse(data.sizeIncrement);
  data.limit_order = data.increment * Decimal.parse(env['limit_order']);

  var wallet_balances =
      await ftxApi.ftx_Get_Auth(env['URL_ftx'], 'wallet/balances');
  data.map_limit = await prep_list_orderLimit(data.increment);
  var txt = '   🔥🔥 FTX_GridBot_1777${versione} 🔥🔥\n';
  txt += '\n';
  txt += '   📉 Cross start: ${market.result_m.name} 📈\n';
  txt += '\n';
  txt += '⌛️ time: ${DateTime.now().toUtc()}\n';
  var i = 0;
  while (i < wallet_balances.data['result'].length) {
    txt +=
        '💰 bilancio: ${wallet_balances.data['result'][i]['total']} ${wallet_balances.data['result'][i]['coin']}\n';

    i++;
  }
  txt += '\n';
  var currency;
  if (data.type == 'spot') {
    currency = market.result_m.baseCurrency.toString();
  } else {
    currency = 'USD';
  }

  txt +=
      'hai impostato una size di ${env['size']} che corrisponde a ${data.size_base} ${currency} per un totale di ${int.parse(env['n_order']) * 2} ordini (max ${int.parse(env['limit_order']) * 2})\n';
  txt +=
      'la distanza minima tra gli ordini è ${Decimal.parse(market.result_m.priceIncrement.toString())} e lo spread attuale è ${(market.result_m.ask - market.result_m.bid).toStringAsFixed(10)}\n';
  txt +=
      'la distanza impostata è ${data.increment} che corrisponde a ${env['distance_ord']} volte il minimo e ${data.increment.toDouble() / (market.result_m.ask - market.result_m.bid)} volte lo spread\n';
  if (data.increment.toDouble() / (market.result_m.ask - market.result_m.bid) <
      2) {
    txt +=
        '\n ⚠️⚠️ si consiglia di mantenere una distanza tra gli ordini superiore al doppio dello spread ⚠️⚠️\n';
  }
  if (env['trading'] == 'false') {
    txt +=
        'se le impostazioni ti soddisfano, attiva il trading sul file .env e riavviami 🤖\n';
  }
  if (env['trading'] == 'true') {
    txt += '\n';
    txt += 'il trading 🤖 è ATTIVATO\n';

    txt += 'TO THE M🌘🌘N !!\n';
    txt += '🚀🚀🚀 \n';
  }
  print(txt);
}

Future<Map> prep_list_orderLimit(Decimal increment) async {
  var map = {};
  while (map.length + 1 <= int.parse(env['n_order'])) {
    map.addAll({
      '${map.length + 1}': '${Decimal.fromInt(map.length + 1) * increment}'
    });
  }
  return map;
}

Future<void> handleError_1(e, s, String txt, other, {txt2}) async {
  //print('HANDLE ERROR ftx_function ${txt.toUpperCase()}');
  print('ERROR: ${e.toString()}');
  print('REQUEST: ${other}');
  //print('ENDPOINT: ${txt2}');
  //print('STACK TRACE: ${s.toString()}');
  //await Future<void>.delayed(Duration(milliseconds: 1000));
  //run();
}
