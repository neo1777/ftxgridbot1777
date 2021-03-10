import 'package:decimal/decimal.dart';
import 'package:dotenv/dotenv.dart';
import 'package:ftxgridbot/ftx_request_class.dart';
import 'dart:convert';
import 'package:ftxgridbot/class_ftx.dart';
import 'package:pausable_timer/pausable_timer.dart';

var versione = 'v8.04';
var open_sell = true;
var open_buy = true;
void main(List<String> args) async {
  //load('.env');

  //await run();
  load();
  var ftxApi = ApiProvide();
  var data = PrimitiveWrapper();
  await funzione_market_init(ftxApi, data);
  if (data.type == 'future') {
    data.posizione_start = await get_data_account(ftxApi, init: 'start');
  }
  await get_historical_index(ftxApi, data);
  if (env['trading'] == 'true') {
    //data.posizione_start = await get_data_account(ftxApi, init: 'start');
    await Future<void>.delayed(Duration(milliseconds: 2000));
    await sync_exec(ftxApi, data);
    data.list_orders_sell = {};
    data.list_orders_buy = {};
    data.list_orders_exec = {};

    var channel = ['orders', 'fills', 'ticker'];
    var websocket = await ftxApi
        .ftx_WebSocket(env['URL_ftx_ws'], env['Cross_ftx'], channel: channel)
        .catchError(onError);
    websocket.listen((event) async {
      var event_json = jsonDecode(event);
      if (env['PRINT_ALL_WS'] == 'true') {
        print('Channel ws ALL: ${event}\n');
      }
      if (event_json['channel'] == 'ticker') {
        if (env['PRINT_CH_TICKER'] == 'true') {
          print('Channel ws TICKER: ${event}\n');
        }
      }
      if (event_json['channel'] == 'orders') {
        if (env['PRINT_CH_ORDERS'] == 'true') {
          print('Channel ws ORDERS: ${event}\n');
        }
        if (event_json['type'] == 'update' &&
            event_json['data']['market'] == env['Cross_ftx'] &&
            event_json['data']['status'] == 'closed') {
          //data.list_orders_exec.remove(event_json['data']['price']);
          //data.last_start = 0.0;
        }
      }
      if (event_json['channel'] == 'fills') {
        if (env['PRINT_CH_FILLS'] == 'true') {
          print('Channel ws FILLS: ${event}\n');
        }
      }
    });

    data.time_market = PausableTimer(
        Duration(milliseconds: int.parse(env['time_market'])), () async {
      //print('time_ord Fired!${DateTime.now().toUtc()}');
      await funzione_market(ftxApi, data);
      //print('${data.type}');
      if (data.type == 'future') {
        await get_data_account(ftxApi, data: data);
      }
      //await Future<void>.delayed(Duration(milliseconds: 5000));
      data.last_start = 0.0;
      data.time_market.reset();
      data.time_market.start();
    });
    data.time_market.start();
  }
}

Future funzione_market_init(ApiProvide ftxApi, PrimitiveWrapper data) async {
  var market_single =
      await ftxApi.ftx_Get(env['URL_ftx'], 'markets/${env['Cross_ftx']}');
  //print(market_single);
  final market = welcomeFromMap(json.encode(market_single.data));
  data.increment_base = Decimal.parse(market.result.priceIncrement.toString());
  data.increment = data.increment_base * Decimal.parse(env['distance_ord']);
  data.ask_start = market.result.ask;
  data.bid_start = market.result.bid;
  data.type = market.result.type;
  data.sizeIncrement = market.result.sizeIncrement.toString();
  data.size_base =
      Decimal.parse(env['size']) * Decimal.parse(data.sizeIncrement);
  data.size_buy =
      Decimal.parse(env['size']) * Decimal.parse(data.sizeIncrement);
  data.size_sell =
      Decimal.parse(env['size']) * Decimal.parse(data.sizeIncrement);
  data.size_add =
      Decimal.parse(env['size_add']) * Decimal.parse(data.sizeIncrement);
  data.limit_order = data.increment * Decimal.parse(env['limit_order']);

  //await Future<void>.delayed(Duration(milliseconds: 5000));
  var wallet_balances =
      await ftxApi.ftx_Get_Auth(env['URL_ftx'], 'wallet/balances');
  //
  data.map_limit = await prep_list_orderLimit(data.increment);
  var txt = '   🔥🔥 FTX_GridBot_1777${versione} 🔥🔥\n';
  txt += '\n';
  txt += '   📉 Cross start: ${market.result.name} 📈\n';
  txt += '\n';
  //txt += '⌛️ account: ${data.}\n';
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
    currency = market.result.baseCurrency.toString();
  } else {
    currency = 'USD';
  }

  txt +=
      'hai impostato una size di ${env['size']} che corrisponde a ${data.size_base} ${currency} per un totale di ${int.parse(env['n_order']) * 2} ordini (max ${int.parse(env['limit_order']) * 2})\n';
  txt +=
      'la distanza minima tra gli ordini è ${Decimal.parse(market.result.priceIncrement.toString())} e lo spread attuale è ${(market.result.ask - market.result.bid).toStringAsFixed(10)}\n';
  txt +=
      'la distanza impostata è ${data.increment} che corrisponde a ${env['distance_ord']} volte il minimo e ${data.increment.toDouble() / (market.result.ask - market.result.bid)} volte lo spread\n';
  if (data.increment.toDouble() / (market.result.ask - market.result.bid) < 2) {
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
  /*
  print('market name: ${market.result.name}');
  print('market ask: ${market.result.ask}');
  print('market bid: ${market.result.bid}');
  print('market last: ${market.result.last}');
  print('market price: ${market.result.price}');
  print('market baseCurrency: ${market.result.baseCurrency}');
  print('market type: ${market.result.type}');
  print('market success: ${market.success}');
  print('\ndata.increment_base: ${data.increment_base}');
  print('data.increment: ${data.increment}');
  print('data.sizeIncrement: ${data.sizeIncrement}');
  print('data.size_base: ${data.size_base}');
  print('data.size_buy: ${data.size_buy}');
  print('data.size_sell: ${data.size_sell}');
  print('data.size_add: ${data.size_add}');
  print('map_limit: ${data.map_limit}');
  print('limit_order: ${data.limit_order}');
  */
}

Future funzione_market(ApiProvide ftxApi, PrimitiveWrapper data) async {
  var i = 0;
  var wallet_balances =
      await ftxApi.ftx_Get_Auth(env['URL_ftx'], 'wallet/balances');
  while (i < wallet_balances.data['result'].length) {
    //print(
    //'💰 bilancio: ${wallet_balances.data['result'][i]['total']} ${wallet_balances.data['result'][i]['coin']}\n');

    if (env['Cross_ftx'].split('/')[0] ==
        wallet_balances.data['result'][i]['coin']) {
      //print('Coin 0: ${wallet_balances.data['result'][i]['coin']}');
      if (wallet_balances.data['result'][i]['free'] <
          data.size_sell.toDouble()) {
        if (open_sell) {
          print('Collaterale insufficiente (sell)');
          print(
              'Balance ${wallet_balances.data['result'][i]['coin']}: ${wallet_balances.data['result'][i]['total']}');
          print(
              'colaterale libero: ${wallet_balances.data['result'][i]['free']}');
          print('size: ${data.size_sell}');
          print('index 0');
        }
        open_sell = false;
      } else {
        if (!open_sell) {
          print('Collaterale ripristinato (sell)');
        }
        open_sell = true;
      }
    }
    if (env['Cross_ftx'].split('/')[1] ==
        wallet_balances.data['result'][i]['coin']) {
      //print('Coin 1: ${wallet_balances.data['result'][i]['coin']}');
      if (wallet_balances.data['result'][i]['free'] <
          data.size_buy.toDouble()) {
        if (open_buy) {
          print('Collaterale insufficiente (buy)');
          print(
              'Balance ${wallet_balances.data['result'][i]['coin']}: ${wallet_balances.data['result'][i]['total']}');
          print(
              'colaterale libero: ${wallet_balances.data['result'][i]['free']}');
          print('size: ${data.size_buy}');
          print('index 1');
        }
        open_buy = false;
      } else {
        if (!open_buy) {
          print('Collaterale ripristinato (buy)');
        }
        open_buy = true;
      }
    }

    i++;
  }

  var market_single =
      await ftxApi.ftx_Get(env['URL_ftx'], 'markets/${env['Cross_ftx']}');
  final market = welcomeFromMap(json.encode(market_single.data));
  data.ask_start = market.result.ask;
  data.bid_start = market.result.bid;
  //print('last price: ${market.result.price} ${data.last_start}');
  if (data.last_start != market.result.price) {
    //print('\nCHANGE!! last price: ${market.result.price} ${data.last_start}');
    await add_list_orders_limit(ftxApi, market.result.price, data);
  }
  //await sync_exec(ftxApi, data);
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

Future add_list_orders_limit(
    ApiProvide ftxApi, double price_start, PrimitiveWrapper data) async {
  await sync_exec(ftxApi, data);
  var price_start_B = price_start;
  var price_start_S = price_start;
  var n = Decimal.parse(price_start.toString());
  while (n % data.increment != Decimal.fromInt(0)) {
    n += data.increment_base;
    price_start_S = n.toDouble();
    //print('price_start_S: $price_start_S');
  }
  n = Decimal.parse(price_start.toString());
  while (n % data.increment != Decimal.fromInt(0)) {
    n -= data.increment_base;
    price_start_B = n.toDouble();
    //print('price_start_B: $price_start_B');
  }

  /*
  print('Start of loop');
  await Future.forEach(data.map_limit.values, (value) async {
    print('Value = $value');
    await Future.delayed(Duration(seconds: 1), () => print('$value'));
  });
  print('End of loop');*/
  await Future.forEach(data.map_limit.values, (value) async {
    //print('$k $v');
    //print('price_start_B: $price_start_B --  price_start_S: $price_start_S');
    var n_s = (Decimal.parse(price_start_S.toString()) + Decimal.parse(value));
    if (open_sell) {
      if ((Decimal.parse(n_s.toString()) % data.increment ==
          Decimal.fromInt(0))) {
        var data_open_order = {
          'market': env['Cross_ftx'],
          'side': 'sell',
          'price': n_s.toDouble(),
          'type': 'limit',
          'size': data.size_sell.toDouble(),
          'reduceOnly': false,
          'ioc': false,
          'postOnly': true,
          'externalReferralProgram': ''
        };

        data.list_orders_sell.add(n_s);
        //data.list_orders_exec.add(data_open_order['price']);
        if (!data.list_orders_exec.contains(data_open_order['price'])) {
          data.list_orders_exec.add(data_open_order['price']);
          await open_order_limit(ftxApi, data, data_open_order);
        }
      }
    }
    var n_b = (Decimal.parse(price_start_B.toString()) - Decimal.parse(value));
    if (open_buy) {
      if ((Decimal.parse(n_b.toString()) % data.increment ==
          Decimal.fromInt(0))) {
        var data_open_order = {
          'market': env['Cross_ftx'],
          'side': 'buy',
          'price': n_b.toDouble(),
          'type': 'limit',
          'size': data.size_buy.toDouble(),
          'reduceOnly': false,
          'ioc': false,
          'postOnly': true,
          'externalReferralProgram': ''
        };
        data.list_orders_buy.add(n_b);
        //data.list_orders_exec.add(data_open_order['price']);
        if (!data.list_orders_exec.contains(data_open_order['price'])) {
          data.list_orders_exec.add(data_open_order['price']);
          await open_order_limit(ftxApi, data, data_open_order);
        }
      }
    }
  });
  if (env['PRINT_CHANGE_PRICE'] == 'true') {
    print('List orders BUY: ${data.list_orders_buy}');
    print('List orders SELL: ${data.list_orders_sell}');
  }
  //await sync_exec(ftxApi, data);

  if (data.open_orders == null) {
    print('data.open_orders is NULL');
  }

  if (data.open_orders.data['result'].length == data.list_orders_exec.length) {
    data.last_start = price_start;
  }
}

Future open_order_limit(ApiProvide ftxApi, PrimitiveWrapper data, item) async {
  //data.list_orders_exec.add(item['price']);
  //print('data balance: ${data.balance}');
  //print('data free collateral: ${data.freeCollateral}');
  await Future<void>.delayed(Duration(milliseconds: 250));
  await ftxApi
      .ftx_Post_Auth(env['URL_ftx'], 'orders', data: item)
      .catchError(onError);
  data.list_orders_exec.add(item['price']);
}

Future sync_exec(ApiProvide ftxApi, PrimitiveWrapper data) async {
  //print('sync_exec limit_order ${data.limit_order}');
  //print('sync_exec ask_start ${data.ask_start}');
  var data_open_orders = {'market': '${env['Cross_ftx']}'};
  if (data.type == 'spot') {
    data.open_orders = await ftxApi
        .ftx_Get_Auth_spot(env['URL_ftx'], 'orders')
        .catchError(onError);
    //print('${data.type}: ${data.open_orders.data['result']}');
  } else {
    data.open_orders = await ftxApi
        .ftx_Get_Auth(env['URL_ftx'], 'orders', data: data_open_orders)
        .catchError(onError);
    //print('${data.type}: ${data.open_orders.data['result']}');
  }
  data.list_orders_exec = {};
  //print('open_orders length: ${data.open_orders.data['result'].length}');
  try {
    var i = 0;
    if (data.open_orders != null) {
      while (i < data.open_orders.data['result'].length) {
        //print('item order ${data.open_orders.data['result'][i]}');
        if (data.open_orders.data['result'][i]['market'] ==
            '${env['Cross_ftx']}') {
          if (data.open_orders.data['result'][i]['side'] == 'sell') {
            if (data.open_orders.data['result'][i]['price'] >
                (data.ask_start + data.limit_order.toDouble())) {
              await ftxApi
                  .ftx_Del_Auth(env['URL_ftx'],
                      'orders/${data.open_orders.data['result'][i]['id']}')
                  .catchError(onError);
            } else if (data.open_orders.data['result'][i]['size'] !=
                data.size_sell.toDouble()) {
              var option_mod_order = {
                'size': data.size_sell.toDouble(),
                'price': data.open_orders.data['result'][i]['price']
              };
              await ftxApi
                  .ftx_Post_Auth(env['URL_ftx'],
                      'orders/${data.open_orders.data['result'][i]['id']}/modify',
                      data: option_mod_order, txt: 'MODIFY')
                  .catchError(onError);
            }
          }
          if (data.open_orders.data['result'][i]['side'] == 'buy') {
            if (data.open_orders.data['result'][i]['price'] <
                (data.bid_start - data.limit_order.toDouble())) {
              await ftxApi
                  .ftx_Del_Auth(env['URL_ftx'],
                      'orders/${data.open_orders.data['result'][i]['id']}')
                  .catchError(onError);
            } else if (data.open_orders.data['result'][i]['size'] !=
                data.size_buy.toDouble()) {
              var option_mod_order = {
                'size': data.size_buy.toDouble(),
                'price': data.open_orders.data['result'][i]['price']
              };
              await ftxApi
                  .ftx_Post_Auth(env['URL_ftx'],
                      'orders/${data.open_orders.data['result'][i]['id']}/modify',
                      data: option_mod_order, txt: 'MODIFY')
                  .catchError(onError);
            }
          }

          data.list_orders_exec
              .add(data.open_orders.data['result'][i]['price']);
          /*await ftxApi
          .ftx_Del_Auth(env['URL_ftx'],
              'orders/${data.open_orders.data['result'][i]['id']}')
          .catchError((e, s) =>
              handleError_1(e, s, 'ftx_Del_Auth', 'cancel_limit_start'));*/
        }
        i++;
      }
    }
  } catch (e) {
    print('if (data.open_orders != null) {');
    print('error: $e');
  }

  //print('list_orders_exec length: ${data.list_orders_exec.length}');
}

Future<String> get_data_account(ApiProvide ftxApi,
    {PrimitiveWrapper data, String init}) async {
  var account_info =
      await ftxApi.ftx_Get_Auth(env['URL_ftx'], 'account').catchError(onError);
  print('account_info: ${account_info}');
  var pos = 'flat';
  //print('item: ${account_info.data['result']}');
  try {
    for (var item in account_info.data['result']['positions']) {
      //if (item['future'] != env['Cross_ftx']) {
      //print('item: ${item}');
      //}
      if (item['future'] == env['Cross_ftx']) {
        //print('item: ${item}');
        //if (item['netSize'] == null) {
        if (init != 'start') {
          data.position_open = item['netSize'];
        }
        if (item['netSize'] > 0) {
          pos = 'long';
          if (init == 'start') {
            var txt = '⛔️⛔️ Rilevata posizione LONG ⛔️⛔️\n';
            txt += '\n- ⌛️ time: ${DateTime.now().toUtc()}\n';
            txt += '- 💰size: ${item['size']}\n';
            txt += '- 💵 collaterale utilizzato: ${item['collateralUsed']}\n';
            print(txt);
          } else {
            data.size_buy = data.size_base;
            data.size_sell = data.size_base + data.size_add;
          }
        }
        if (item['netSize'] < 0) {
          pos = 'short';
          if (init == 'start') {
            var txt = '⛔️⛔️ Rilevata posizione SHORT ⛔️⛔️\n';
            txt += '\n- ⌛️ time: ${DateTime.now().toUtc()}\n';
            txt += '- 💰size: ${item['size']}\n';
            txt += '- 💵 collaterale utilizzato: ${item['collateralUsed']}\n';
            print(txt);
          } else {
            data.size_buy = data.size_base + data.size_add;
            data.size_sell = data.size_base;
          }
        }
        if (item['netSize'] == 0.0) {
          pos = 'flat';
          if (init == 'start') {
            print('No position start\n');
          } else {
            data.size_buy = data.size_base;
            data.size_sell = data.size_base;
          }
        }
        //}
      }
    }
  } catch (e) {
    print('var item in account_info.data');
    print('error: $e');
  }

  if (init != 'start') {
    data.posizione_now = pos;
    if (account_info != null) {
      data.balance = account_info.data['result']['collateral'];
      data.freeCollateral = account_info.data['result']['freeCollateral'];
    }
  }
  return pos;
}

Future get_historical_index(ApiProvide ftxApi, PrimitiveWrapper data) async {
  var bar = int.parse(env['n_candele']);
  var historical_index = await ftxApi.ftx_Get(env['URL_ftx'],
      'markets/${env['Cross_ftx']}/candles?resolution=${env['time_frame']}&limit=${bar}');
  final historical = historicalFromMap(json.encode(historical_index.data));
  var i = 0;
  var corpo_list = 0.0;
  while (i < (bar - 1)) {
    corpo_list +=
        (historical.result[i].open - historical.result[i].close).abs();
/*
    print('Indice barra: ${i}');
    print(' startTime: ${historical.result[i].startTime}');
    print(' open: ${historical.result[i].open}');
    print(' close: ${historical.result[i].close}');
    print(' high: ${historical.result[i].high}');
    print(' low: ${historical.result[i].low}');
    print(' time: ${historical.result[i].time}');
    print(' volume: ${historical.result[i].volume}\n');
*/
    i++;
  }

  var timeframe = {
    '15': 'da 15 secondi',
    '60': 'da 60 secondi',
    '300': 'da 5 minuti',
    '900': 'da 5 minuti',
    '3600': 'oraria',
    '14400': 'da 4 ore',
    '86400': 'giornaliera'
  };
  var corpo =
      (historical.result[bar - 2].open - historical.result[bar - 2].close)
          .abs();
  var media_corpo = corpo_list / (bar - 1);
  var rapporto_grid =
      (corpo / data.increment.toDouble()).toStringAsPrecision(1);
  var rapporto_grid_all =
      (media_corpo / data.increment.toDouble()).toStringAsPrecision(1);
  var txt = '  ⚠️ Alcune informazioni per te ⚠️\n\n';
  txt +=
      ' ✅ l ultima candela ${timeframe[env['time_frame']]} del ${historical.result[1].startTime} ha un corpo di ${corpo} pari a circa ${Decimal.parse(rapporto_grid)} griglie\n';
  txt +=
      ' ✅ la media delle ultime ${bar - 1} candele è ${media_corpo} pari a ${rapporto_grid_all} griglie\n';

  print(txt);
}

// To parse this JSON data, do
//
//     final welcome = welcomeFromMap(jsonString);

GetMarketCross welcomeFromMap(String str) =>
    GetMarketCross.fromMap(json.decode(str));

String welcomeToMap(GetMarketCross data) => json.encode(data.toMap());

class GetMarketCross {
  GetMarketCross({
    this.result,
    this.success,
  });

  Result result;
  bool success;

  factory GetMarketCross.fromMap(Map<String, dynamic> json) => GetMarketCross(
        result: Result.fromMap(json['result']),
        success: json['success'],
      );

  Map<String, dynamic> toMap() => {
        'result': result.toMap(),
        'success': success,
      };
}

class Result {
  Result({
    this.ask,
    this.baseCurrency,
    this.bid,
    this.change1H,
    this.change24H,
    this.changeBod,
    this.enabled,
    this.highLeverageFeeExempt,
    this.last,
    this.minProvideSize,
    this.name,
    this.postOnly,
    this.price,
    this.priceIncrement,
    this.quoteCurrency,
    this.quoteVolume24H,
    this.restricted,
    this.sizeIncrement,
    this.type,
    this.underlying,
    this.volumeUsd24H,
  });

  double ask;
  dynamic baseCurrency;
  double bid;
  double change1H;
  double change24H;
  double changeBod;
  bool enabled;
  bool highLeverageFeeExempt;
  double last;
  double minProvideSize;
  String name;
  bool postOnly;
  double price;
  double priceIncrement;
  dynamic quoteCurrency;
  double quoteVolume24H;
  bool restricted;
  double sizeIncrement;
  String type;
  String underlying;
  double volumeUsd24H;

  factory Result.fromMap(Map<String, dynamic> json) => Result(
        ask: json['ask'].toDouble(),
        baseCurrency: json['baseCurrency'],
        bid: json['bid'].toDouble(),
        change1H: json['change1h'].toDouble(),
        change24H: json['change24h'].toDouble(),
        changeBod: json['changeBod'].toDouble(),
        enabled: json['enabled'],
        highLeverageFeeExempt: json['highLeverageFeeExempt'],
        last: json['last'].toDouble(),
        minProvideSize: json['minProvideSize'].toDouble(),
        name: json['name'],
        postOnly: json['postOnly'],
        price: json['price'].toDouble(),
        priceIncrement: json['priceIncrement'].toDouble(),
        quoteCurrency: json['quoteCurrency'],
        quoteVolume24H: json['quoteVolume24h'].toDouble(),
        restricted: json['restricted'],
        sizeIncrement: json['sizeIncrement'].toDouble(),
        type: json['type'],
        underlying: json['underlying'],
        volumeUsd24H: json['volumeUsd24h'].toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'ask': ask,
        'baseCurrency': baseCurrency,
        'bid': bid,
        'change1h': change1H,
        'change24h': change24H,
        'changeBod': changeBod,
        'enabled': enabled,
        'highLeverageFeeExempt': highLeverageFeeExempt,
        'last': last,
        'minProvideSize': minProvideSize,
        'name': name,
        'postOnly': postOnly,
        'price': price,
        'priceIncrement': priceIncrement,
        'quoteCurrency': quoteCurrency,
        'quoteVolume24h': quoteVolume24H,
        'restricted': restricted,
        'sizeIncrement': sizeIncrement,
        'type': type,
        'underlying': underlying,
        'volumeUsd24h': volumeUsd24H,
      };
}

// To parse this JSON data, do
//
//     final historical = historicalFromMap(jsonString);

Historical historicalFromMap(String str) =>
    Historical.fromMap(json.decode(str));

String historicalToMap(Historical data) => json.encode(data.toMap());

class Historical {
  Historical({
    this.result,
    this.success,
  });

  List<Result_h> result;
  bool success;

  factory Historical.fromMap(Map<String, dynamic> json) => Historical(
        result:
            List<Result_h>.from(json['result'].map((x) => Result_h.fromMap(x))),
        success: json['success'],
      );

  Map<String, dynamic> toMap() => {
        'result': List<dynamic>.from(result.map((x) => x.toMap())),
        'success': success,
      };
}

class Result_h {
  Result_h({
    this.close,
    this.high,
    this.low,
    this.open,
    this.startTime,
    this.time,
    this.volume,
  });

  double close;
  double high;
  double low;
  double open;
  DateTime startTime;
  double time;
  double volume;

  factory Result_h.fromMap(Map<String, dynamic> json) => Result_h(
        close: json['close'].toDouble(),
        high: json['high'].toDouble(),
        low: json['low'].toDouble(),
        open: json['open'].toDouble(),
        startTime: DateTime.parse(json['startTime']),
        time: json['time'].toDouble(),
        volume: json['volume'].toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'close': close,
        'high': high,
        'low': low,
        'open': open,
        'startTime': startTime.toIso8601String(),
        'time': time,
        'volume': volume,
      };
}

void onError(e, String txt_error) {
  print('Errore string $txt_error');
  print('error: $e');
}


/*
    print('\ndata.increment_base: ${data.increment_base}');
    print('data.increment: ${data.increment}');
    print('data.sizeIncrement: ${data.sizeIncrement}');
    print('data.size_base: ${data.size_base}');
    print('data.size_buy: ${data.size_buy}');
    print('data.size_sell: ${data.size_sell}');
    print('data.size_add: ${data.size_add}');

*/
