import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dotenv/dotenv.dart';
import 'package:ftxgridbot/class_ftx.dart';
import 'package:ftxgridbot/ftx_request_class.dart';
import 'package:pausable_timer/pausable_timer.dart';

var id_now;

Future run() async {
  const _requiredEnvVars = ['API_SECRET_ftx', 'API_ftx'];
  if (isEveryDefined(_requiredEnvVars)) {
  } else {
    load('.env');
  }

  var ftxApi = ApiProvide();
  var data = PrimitiveWrapper();
  data.list_orders_sell = {};
  data.list_orders_buy = {};
  data.list_orders_exec = {};
  data.position_open = 0;
  data.ask_first_order = 0.0;
  data.bid_first_order = 0.0;
  cancel_limit_start(ftxApi, data);
  await Future<void>.delayed(Duration(milliseconds: 10000));
  var future = await ftxApi
      .ftx_Get(env['URL_ftx'], 'futures/${env['Cross_ftx']}')
      .catchError((e, s) => handleError_1(e, s, 'ftx_Get', 'future'));
  data.increment_base =
      Decimal.parse(future.data['result']['priceIncrement'].toString());
  data.increment = data.increment_base * Decimal.parse(env['distance_ord']);

  data.sizeIncrement = future.data['result']['sizeIncrement'].toString();
  data.size_base =
      Decimal.parse(env['size']) * Decimal.parse(data.sizeIncrement);
  data.size_buy =
      Decimal.parse(env['size']) * Decimal.parse(data.sizeIncrement);
  data.size_sell =
      Decimal.parse(env['size']) * Decimal.parse(data.sizeIncrement);
  data.size_add =
      Decimal.parse(env['size_add']) * Decimal.parse(data.sizeIncrement);
  data.limit_order = data.increment * Decimal.parse(env['limit_order']);

  data.posizione_start = await get_data_account(ftxApi, init: 'start');

  var channel = ['orders', 'fills', 'ticker'];

  var websocket = await ftxApi
      .ftx_WebSocket(env['URL_ftx_ws'], env['Cross_ftx'], channel: channel)
      .catchError((e, s) => handleError_1(e, s, 'ftx_WebSocket', 'websocket'));
  websocket.listen((event) async {
    var event_json = jsonDecode(event);
    if (env['PRINT_ALL_WS'] == 'true') {
      print('Channel ws ALL: ${event}\n');
    }
    if (event_json['channel'] == 'ticker') {
      if (env['PRINT_CH_TICKER'] == 'true') {
        print('Channel ws TICKER: ${event}\n');
      }

      if (event_json['type'] == 'update') {
        double ask = event_json['data']['ask'];
        double bid = event_json['data']['bid'];
        double last = event_json['data']['last'];
        data.ask_start ??= ask;
        data.bid_start ??= bid;
        data.last_start ??= last;

        if (data.last_start != last) {
          if (env['PRINT_CHANGE_PRICE'] == 'true') {
            print('\nChange LAST_start: ${data.last_start} to LAST: ${last}');
          }
          await add_list_orders_limit(last, data.increment, data);
        }
      }
    }
    if (event_json['channel'] == 'orders') {
      if (env['PRINT_CH_ORDERS'] == 'true') {
        print('Channel ws ORDERS: ${event}\n');
      }

      if (event_json['type'] == 'update' &&
          event_json['data']['market'] == env['Cross_ftx'] &&
          event_json['data']['status'] == 'closed') {
        data.list_orders_exec.remove(event_json['data']['price']);
        data.time_mod.pause();
      }
    }
    if (event_json['channel'] == 'fills') {
      if (env['PRINT_CH_FILLS'] == 'true') {
        print('Channel ws FILLS: ${event}\n');
      }
    }
    if (event_json['channel'] != 'ticker' &&
        event_json['channel'] != 'orders' &&
        event_json['channel'] != 'fills') {
      if (event_json['type'] == 'info' && event_json['code'] == 20001) {
        print('Server problem: ${event_json}\n');
        print('Reconnect...');
        await run();
      }
      if (env['PRINT_WS_INFO'] == 'true') {
        print('WS INFO: ${event_json}\n');
      }
    }
  });

  data.time_ord =
      PausableTimer(Duration(milliseconds: int.parse(env['time_ord'])), () {
    //print('time_ord Fired!${DateTime.now().toUtc()}');
    funzione_timer_ordini(ftxApi, data);
  });

  data.time_data = PausableTimer(
      Duration(milliseconds: int.parse(env['time_data'])), () async {
    //print('time_data Fired!${DateTime.now().toUtc()}');
    var position_now = await get_data_account(ftxApi, data: data);
  });

  data.time_mod = PausableTimer(
      Duration(milliseconds: int.parse(env['time_mod'])), () async {
    //print('time_mod Fired!${DateTime.now().toUtc()}');
    await mod_limit(ftxApi, data);
  });

  data.time_print = PausableTimer(
      Duration(milliseconds: int.parse(env['time_print'])), () async {
    print('\nTime Fired!\n${DateTime.now().toUtc()}');
    print('balance        : ${data.balance}');
    print('freeCollateral : ${data.freeCollateral}');
    print('posizione_start: ${data.posizione_start}');
    print('position_open  : ${data.position_open}');
    print('posizione_now  : ${data.posizione_now}');
    /*
    print(
        'time_mod isPaused: ${data.time_mod.isPaused} isActive: ${data.time_mod.isActive} isCancelled: ${data.time_mod.isCancelled} isExpired: ${data.time_mod.isExpired} tick: ${data.time_mod.tick}');
    print(
        'time_data isPaused: ${data.time_data.isPaused} isActive: ${data.time_data.isActive} isCancelled: ${data.time_data.isCancelled} isExpired: ${data.time_data.isExpired} tick: ${data.time_data.tick}');
    print(
        'time_ord isPaused: ${data.time_ord.isPaused} isActive: ${data.time_ord.isActive} isCancelled: ${data.time_ord.isCancelled} isExpired: ${data.time_ord.isExpired} tick: ${data.time_ord.tick}');
    */
    //print('list_orders_exec: ${data.list_orders_exec}');
    //print('list_orders_modificati: ${data.list_orders_modificati}');
    //print('open_orders length: ${data.open_orders.data['result'].length}');
    /*
    print('\nelapsed: ${data.time_mod.elapsed}');
    print('isActive: ${data.time_mod.isActive}');
    print('isCancelled: ${data.time_mod.isCancelled}');
    print('isExpired: ${data.time_mod.isExpired}');
    print('isPaused: ${data.time_mod.isPaused}');
    print('tick: ${data.time_mod.tick}\n');
    */
    data.time_print.reset();
    data.time_print.start();
  });

  data.time_time = PausableTimer(
      Duration(milliseconds: int.parse(env['time_time'])), () async {
    if (env['PRINT_MOD_TIME'] == 'true') {
      print('\nelapsed: ${data.time_mod.elapsed}');
      print('isActive: ${data.time_mod.isActive}');
      print('isCancelled: ${data.time_mod.isCancelled}');
      print('isExpired: ${data.time_mod.isExpired}');
      print('isPaused: ${data.time_mod.isPaused}');
      print('tick: ${data.time_mod.tick}\n');
    }
    await sync_exec(ftxApi, data);
    data.time_mod.reset();
    await Future<void>.delayed(Duration(milliseconds: 50));
    data.time_mod.start();
    //if (!data.time_exec.isActive) {
    data.time_exec.reset();
    await Future<void>.delayed(Duration(milliseconds: 50));
    data.time_exec.start();
    //}
    data.time_time.reset();
    data.time_time.start();
  });

  data.time_exec = PausableTimer(
      Duration(milliseconds: int.parse(env['time_exec'])), () async {
    //print('time_exec Fired!${DateTime.now().toUtc()}');
    await order_exec_list(ftxApi, data);
  });

  data.time_ord.start();
  data.time_data.start();
  data.time_mod.start();
  data.time_time.start();
  data.time_exec.start();
  data.time_print.start();
}

void funzione_timer_ordini(ApiProvide ftxApi, PrimitiveWrapper data) {
  //data.time_data.pause();
  data.time_exec.pause();
  openOrderLimit(ftxApi, data);
  if (data.list_orders_buy.isNotEmpty) {
    data.ask_first_order =
        (Decimal.parse(data.list_orders_buy.first.toDouble().toString()) -
                data.limit_order)
            .toDouble();
  }
  if (data.list_orders_sell.isNotEmpty) {
    data.bid_first_order =
        (Decimal.parse(data.list_orders_sell.first.toDouble().toString()) +
                data.limit_order)
            .toDouble();
  }
  //data.time_data.reset();
  //data.time_data.start();
}

Set ord = {};
void openOrderLimit(ApiProvide ftxApi, PrimitiveWrapper data) async {
  var list_orders_limit = <Map>{};
  Set list_orders = {};
  for (var item in data.list_orders_buy) {
    var data_open_order = {
      'market': env['Cross_ftx'],
      'side': 'buy',
      'price': item.toDouble(),
      'type': 'limit',
      'size': data.size_buy.toDouble(),
      'reduceOnly': false,
      'ioc': false,
      'postOnly': true,
      'externalReferralProgram': ''
    };
    list_orders_limit.add(data_open_order);
    list_orders.add(data_open_order['price']);
  }

  for (var item in data.list_orders_sell) {
    var data_open_order = {
      'market': env['Cross_ftx'],
      'side': 'sell',
      'price': item.toDouble(),
      'type': 'limit',
      'size': data.size_sell.toDouble(),
      'reduceOnly': false,
      'ioc': false,
      'postOnly': true,
      'externalReferralProgram': ''
    };
    list_orders_limit.add(data_open_order);
    list_orders.add(data_open_order['price']);
  }
  //print('openOrderLimit list: ${list_orders_limit}');
  //print('\n');

  for (var item in Set.from(list_orders_limit)) {
    /*if (list_orders.length > 1 &&
        data.list_orders_exec.length == list_orders.length) {
      //data.list_orders_exec.clear();
      data.list_orders_exec = list_orders;
    }*/

    //print('openOrderLimit list: ${item['price']}');
    if (list_orders.contains(item['price'])) {
      if (!data.list_orders_exec.contains(item['price'])) {
        data.list_orders_exec.add(item['price']);

        if (item['side'] == 'sell') {
          //print('openOrderLimit sell: ${item['price']}');
          await ftxApi
              .ftx_Post_Auth(env['URL_ftx'], 'orders', data: item)
              .catchError((e, s) =>
                  handleError_1(e, s, 'ftx_Post_Auth sell', 'openOrderLimit'));
          if (env['PRINT_OPEN_ORDERS'] == 'true') {
            //print('Open order SELL: ${item} RESPONSE: ${res.data['result']}');
          }
          //await Future<void>.delayed(Duration(milliseconds: 50));
        }
        if (item['side'] == 'buy') {
          //print('openOrderLimit buy: ${item['price']}');
          await ftxApi
              .ftx_Post_Auth(env['URL_ftx'], 'orders', data: item)
              .catchError((e, s) =>
                  handleError_1(e, s, 'ftx_Post_Auth buy', 'openOrderLimit'));
          if (env['PRINT_OPEN_ORDERS'] == 'true') {
            //print('Open order BUY: ${item} RESPONSE: ${res.data['result']}');
          }
        }
        //data.list_orders_exec.add(item['price']);

      }
    }
  }
  data.list_orders_sell.clear();
  data.list_orders_buy.clear();
  list_orders.clear();
  await sync_exec(ftxApi, data);
  data.time_ord.reset();
  data.time_ord.start();
  //data.time_exec.reset();
  //data.time_exec.start();
}

Future add_list_orders_limit(
    double price_start, Decimal inc, PrimitiveWrapper data) async {
  var map_limit = await prep_list_orderLimit(inc);
  //var stream = Stream.fromIterable(map_limit.entries);
  var price_start_B = price_start;
  var price_start_S = price_start;
  //print('price_start: $price_start');
  var n = Decimal.parse(price_start.toString());
  while (n % inc != Decimal.fromInt(0)) {
    n += data.increment_base;
    price_start_S = n.toDouble();
    //print('price_start_S: $price_start_S');
  }
  n = Decimal.parse(price_start.toString());
  while (n % inc != Decimal.fromInt(0)) {
    n -= data.increment_base;
    price_start_B = n.toDouble();
    //print('price_start_B: $price_start_B');
  }

  map_limit.forEach((k, v) {
    //print('$k $v');
    //print('price_start_B: $price_start_B --  price_start_S: $price_start_S');
    var n_s = (Decimal.parse(price_start_S.toString()) + Decimal.parse(v));
    if ((Decimal.parse(n_s.toString()) % inc == Decimal.fromInt(0))) {
      data.list_orders_sell.add(n_s);
    }
    var n_b = (Decimal.parse(price_start_B.toString()) - Decimal.parse(v));
    if ((Decimal.parse(n_b.toString()) % inc == Decimal.fromInt(0))) {
      data.list_orders_buy.add(n_b);
    }
  });
  if (env['PRINT_CHANGE_PRICE'] == 'true') {
    print('List orders BUY: ${data.list_orders_buy}');
    print('List orders SELL: ${data.list_orders_sell}');
  }
  data.last_start = price_start;
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

Future<String> get_data_account(ApiProvide ftxApi,
    {PrimitiveWrapper data, String init}) async {
  if (init != 'start') {
    data.time_ord.pause();
    data.time_exec.pause();
  }
  var account_info = await ftxApi
      .ftx_Get_Auth(env['URL_ftx'], 'account')
      .catchError(
          (e, s) => handleError_1(e, s, 'get_data_account', 'open_orders'));
  var pos = 'flat';
  try {
    for (var item in account_info.data['result']['positions']) {
      //print('item: ${item}');
      if (item['future'] == env['Cross_ftx']) {
        //print('item: ${item}');
        //if (item['netSize'] == null) {
        if (init != 'start') {
          data.position_open = item['netSize'];
        }
        if (item['netSize'] > 0) {
          pos = 'long';
          if (init == 'start') {
            print('Start position LONG');
            print(' - size: ${item['size']}');
            print(
                ' - unrealized Pnl: ${item['unrealizedPnl']} - collateral used: ${item['collateralUsed']}');
            print(
                ' - cost: ${item['cost']} - realized Pnl: ${item['realizedPnl']}\n');
          } else {
            data.size_buy = data.size_base;
            data.size_sell = data.size_base + data.size_add;
          }
        }
        if (item['netSize'] < 0) {
          pos = 'short';
          if (init == 'start') {
            print('Start position SHORT');
            print('${DateTime.now().toUtc()}');
            print(' - size: ${item['size']}');
            print(
                ' - unrealized Pnl: ${item['unrealizedPnl']} - collateral used: ${item['collateralUsed']}');
            print(
                ' - cost: ${item['cost']} - realized Pnl: ${item['realizedPnl']}');
          } else {
            data.size_buy = data.size_base + data.size_add;
            data.size_sell = data.size_base;
          }
        }
        if (item['netSize'] == 0.0) {
          pos = 'flat';
          if (init == 'start') {
            print('No position start');
          } else {
            data.size_buy = data.size_base;
            data.size_sell = data.size_base;
          }
        }
        //}
      }
    }
  } catch (e, s) {
    await handleError_1(
        e, s, 'try data get_data_account', 'data get_data_account');
  }

  if (init != 'start') {
    data.posizione_now = pos;
    if (account_info != null) {
      data.balance = account_info.data['result']['collateral'];
      data.freeCollateral = account_info.data['result']['freeCollateral'];
    }

    /*
if (data.list_orders_exec.length !=
        data.open_orders.data['result'].length) {
      var set_orders = <dynamic>{};
      var list_orders = [];
      for (var i = 0; i < data.open_orders.data['result'].length; i++) {
        if (data.open_orders.data['result'][i]['side'] == 'buy') {
          if (data.open_orders.data['result'][i]['size'] == data.size_buy) {
            data.list_orders_modificati
                .add(data.open_orders.data['result'][i]['price']);
            //data.list_orders_exec
            //.add(data.open_orders.data['result'][i]['price']);
          } else {
            data.list_orders_modificati
                .remove(data.open_orders.data['result'][i]['price']);
          }
        }
        if (data.open_orders.data['result'][i]['side'] == 'sell') {
          if (data.open_orders.data['result'][i]['size'] == data.size_sell) {
            data.list_orders_modificati
                .add(data.open_orders.data['result'][i]['price']);
            //data.list_orders_exec
            //.add(data.open_orders.data['result'][i]['price']);
          } else {
            data.list_orders_modificati
                .remove(data.open_orders.data['result'][i]['price']);
          }
        }

        set_orders.add(data.open_orders.data['result'][i]['price']);
        list_orders.add(data.open_orders.data['result'][i]['price']);
      }

      var l = list_orders;
      if (set_orders.length != list_orders.length) {
        for (var elem in set_orders) {
          l.remove(elem);
        }
        print('\ndouble order: ${l}');
        for (var i = 0; i < data.open_orders.data['result'].length; i++) {
          if (l.contains(data.open_orders.data['result'][i]['price'])) {
            l.remove(data.open_orders.data['result'][i]['price']);
            print(
                'double order id: ${data.open_orders.data['result'][i]['id']} -  ${data.open_orders.data['result'][i]['price']}');
            set_orders.remove(data.open_orders.data['result'][i]['price']);
            await ftxApi
                .ftx_Del_Auth(env['URL_ftx'],
                    'orders/${data.open_orders.data['result'][i]['id']}')
                .catchError((e, s) {
              handleError_1(e, s, 'double order', 'double order bis');
            });
            try {
              data.list_orders_exec
                  .remove(data.open_orders.data['result'][i]['price']);
            } catch (e, s) {
              await handleError_1(
                  e, s, 'try remove double exec', 'try remove double exec');
            }
            //i = data.open_orders.data['result'].length;

            //await Future<void>.delayed(Duration(milliseconds: 50));
          }
        }
        data.list_orders_exec = set_orders;
      } else {
        //data.list_orders_exec.clear();
        //data.list_orders_exec = set_orders;
      }
    }
    */
  }
  if (init != 'start') {
    data.time_data.reset();
    data.time_data.start();
    data.time_ord.reset();
    data.time_ord.start();
  }

  return pos;
}

void cancel_limit_start(ApiProvide ftxApi, PrimitiveWrapper data) async {
  var data_open_orders = {'market': '${env['Cross_ftx']}'};
  data.open_orders = await ftxApi
      .ftx_Get_Auth(env['URL_ftx'], 'orders', data: data_open_orders)
      .catchError((e, s) =>
          handleError_1(e, s, 'data.open_orders', 'cancel_limit_start'));
  for (var i = 0; i < data.open_orders.data['result'].length; i++) {
    //print('item order ${data.open_orders.data['result'][i]}');
    if (data.open_orders.data['result'][i]['type'] == 'limit') {
      await ftxApi
          .ftx_Del_Auth(env['URL_ftx'],
              'orders/${data.open_orders.data['result'][i]['id']}')
          .catchError((e, s) =>
              handleError_1(e, s, 'ftx_Del_Auth', 'cancel_limit_start'));
    }
  }
}

void mod_limit(ApiProvide ftxApi, PrimitiveWrapper data) async {
  data.time_exec.pause();
  var n_B = Decimal.parse('0.0');
  var n_S = Decimal.parse('0.0');
  //Set list_mod = {};
  try {
    var data_open_orders = {'market': '${env['Cross_ftx']}'};
    data.open_orders = await ftxApi
        .ftx_Get_Auth(env['URL_ftx'], 'orders', data: data_open_orders)
        .catchError(
            (e, s) => handleError_1(e, s, 'mod_limit', 'data.open_orders'));
  } catch (e, s) {
    await handleError_1(e, s, 'try ftx_Get_Auth', 'ftx_Get_Auth');
  }
  try {
    for (var i = 0; i < data.open_orders.data['result'].length; i++) {
      //print('item order ${data.open_orders.data['result'][i]}');
      if (i < data.open_orders.data['result'].length) {
        if (data.open_orders.data['result'][i]['type'] == 'limit') {
          if (data.open_orders.data['result'][i]['price'] >
                  data.bid_first_order ||
              data.open_orders.data['result'][i]['price'] <
                  data.ask_first_order) {
            await ftxApi
                .ftx_Del_Auth(env['URL_ftx'],
                    'orders/${data.open_orders.data['result'][i]['id']}')
                .catchError(
                    (e, s) => handleError_1(e, s, 'mod_limit', 'mod_limit'));
            //data.list_orders_modificati
            //.add(data.open_orders.data['result'][i]['price']);
            data.list_orders_exec
                .remove(data.open_orders.data['result'][i]['price']);
            i++;
          }
          if (i < data.open_orders.data['result'].length) {
            if (data.open_orders.data['result'][i]['side'] == 'buy') {
              if (data.open_orders.data['result'][i]['size'] !=
                  data.size_buy.toDouble()) {
                var option_mod_order = {
                  'size': data.size_buy.toDouble(),
                  'price': data.open_orders.data['result'][i]['price']
                };
                if (i < data.open_orders.data['result'].length) {
                  await mod_order_limit(
                          ftxApi,
                          data,
                          data.open_orders.data['result'][i]['id'],
                          option_mod_order)
                      .catchError((e, s) =>
                          handleError_1(e, s, 'mod_limit', 'mod_order_limit'));
                }
                //data.list_orders_exec
                //.add(data.open_orders.data['result'][i]['price']);
              }
            }
          }
          if (i < data.open_orders.data['result'].length) {
            if (data.open_orders.data['result'][i]['side'] == 'sell') {
              if (data.open_orders.data['result'][i]['size'] !=
                  data.size_sell.toDouble()) {
                var option_mod_order = {
                  'size': data.size_sell.toDouble(),
                  'price': data.open_orders.data['result'][i]['price']
                };
                if (i < data.open_orders.data['result'].length) {
                  await mod_order_limit(
                          ftxApi,
                          data,
                          data.open_orders.data['result'][i]['id'],
                          option_mod_order)
                      .catchError((e, s) =>
                          handleError_1(e, s, 'mod_limit', 'mod_order_limit'));
                }
                //data.list_orders_exec
                //.add(data.open_orders.data['result'][i]['price']);
              }
            }
          }
        }
      }
    }
  } catch (e, s) {
    await handleError_1(e, s, 'ciclo for mod_limit', 'mod_limit');
  }
  //data.list_orders_modificati.clear();
  data.time_mod.reset();
  data.time_mod.start();
  //mod_order_limit(ftxApi, data);
}

Future mod_order_limit(
    ApiProvide ftxApi, PrimitiveWrapper data, id, option) async {
  if (id == id_now) {
  } else {
    //data.list_orders_modificati = {};
    await Future<void>.delayed(Duration(milliseconds: 75));
    await ftxApi
        .ftx_Post_Auth(env['URL_ftx'], 'orders/${id}/modify',
            data: option, txt: 'MODIFY')
        .catchError((e, s) {
      //data.list_orders_exec.add(id);
      handleError_1(e, s, 'mod_order_limit', 'ftx_Post_Auth');
    });
    //await Future<void>.delayed(Duration(milliseconds: 50));
    //print('price: ${option['price']}');
    //print('id: ${id}');
    //data.list_orders_exec.add(option['price']);
    //data.list_orders_modificati.add(option['price']);
    id_now = id;
  }
}

Future order_exec_list(ApiProvide ftxApi, PrimitiveWrapper data) async {
  data.time_mod.pause();
  data.time_ord.pause();
  var set_orders = <dynamic>{};
  var del_orders = <dynamic>{};
  var list_orders = [];
  var l = list_orders;
  for (var i = 0; i < data.open_orders.data['result'].length; i++) {
    set_orders.add(data.open_orders.data['result'][i]['price']);
    list_orders.add(data.open_orders.data['result'][i]['price']);
  }
  data.list_orders_exec = set_orders;
  if (set_orders.length != list_orders.length) {
    for (var elem in set_orders) {
      l.remove(elem);
    }
    //print('\ndouble order: ${l}');
    Set.from(l).forEach((e) {
      del_orders.add(e);
      //print('\ndouble order E: ${e}');
    });

    for (var i = 0; i < data.open_orders.data['result'].length; i++) {
      //await Future<void>.delayed(Duration(milliseconds: 10));
      if (del_orders.contains(data.open_orders.data['result'][i]['price'])) {
        //del_orders.remove(data.open_orders.data['result'][i]['price']);
        l.remove(data.open_orders.data['result'][i]['price']);
        list_orders.remove(data.open_orders.data['result'][i]['price']);
        set_orders.remove(data.open_orders.data['result'][i]['price']);
        await ftxApi
            .ftx_Del_Auth(env['URL_ftx'],
                'orders/${data.open_orders.data['result'][i]['id']}')
            .catchError((e, s) {
          //del_orders.remove(data.open_orders.data['result'][i]['price']);
          handleError_1(
              e,
              s,
              'del order_exec_list ${data.open_orders.data['result'][i]['id']}',
              'del order_exec_list ${data.open_orders.data['result'][i]['id']}');
        });
        del_orders.remove(data.open_orders.data['result'][i]['price']);
      }
    }
  }
}

Future sync_exec(ApiProvide ftxApi, PrimitiveWrapper data) async {
  var data_open_orders = {'market': '${env['Cross_ftx']}'};
  data.open_orders = await ftxApi
      .ftx_Get_Auth(env['URL_ftx'], 'orders', data: data_open_orders)
      .catchError((e, s) =>
          handleError_1(e, s, 'data.open_orders', 'cancel_limit_start'));
  data.list_orders_exec.clear();
  try {
    for (var i = 0; i < data.open_orders.data['result'].length; i++) {
      //print('item order ${data.open_orders.data['result'][i]}');
      if (data.open_orders.data['result'][i]['type'] == 'limit') {
        data.list_orders_exec.add(data.open_orders.data['result'][i]['price']);
        /*await ftxApi
          .ftx_Del_Auth(env['URL_ftx'],
              'orders/${data.open_orders.data['result'][i]['id']}')
          .catchError((e, s) =>
              handleError_1(e, s, 'ftx_Del_Auth', 'cancel_limit_start'));*/
      }
    }
  } catch (e, s) {
    await handleError_1(e, s, 'try sync_exec', 'try sync_exec');
  }
}

Future<void> handleError_1(e, s, String txt, other, {txt2}) async {
  print('HANDLE ERROR ftx_function ${txt.toUpperCase()}');
  print('ERROR: ${e.toString()}');
  print('REQUEST: ${other}');
  print('ENDPOINT: ${txt2}');
  print('STACK TRACE: ${s.toString()}');
  await Future<void>.delayed(Duration(milliseconds: 1000));
  //run();
}

/*
void cancel_limit_start(ApiProvide ftxApi, PrimitiveWrapper data,
    {String condition}) async {
  for (var item in data.open_orders.data['result']) {
    if (item['type'] == 'limit') {
      if (condition == 'start') {
        await ftxApi.ftx_Del_Auth(env['URL_ftx'], 'orders/${item['id']}');
      } else if (item['side'] == 'sell') {
        if (item['price'] > data.bid_first_order) {
          print(
              'DEL ORDER SELL > first order ${data.bid_first_order}: ${item['id']}');
          await ftxApi.ftx_Del_Auth(env['URL_ftx'], 'orders/${item['id']}');
        } else if (item['size'] != data.size_sell.toDouble()) {
          var option_mod_order = {
            'size': data.size_sell.toDouble(),
            'price': item['price']
          };
          print('DEL ORDER SELL != size_sell ${data.size_sell}: ${item['id']}');
          await ftxApi
              .ftx_Post_Auth(env['URL_ftx'], 'orders/${item['id']}/modify',
                  data: option_mod_order, txt: 'MODIFY - id: ${item['id']}')
              .catchError((e, s) => handleError_1(
                  e, s, 'MODIFY - ftx_function', option_mod_order,
                  txt2: 'orders/${item['id']}\n${data.list_orders_exec}'));
        }
      } else if (item['side'] == 'buy') {
        if (item['price'] < data.ask_first_order) {
          print(
              'DEL ORDER BUY < first order ${data.ask_first_order}: ${item['id']}');
          await ftxApi.ftx_Del_Auth(env['URL_ftx'], 'orders/${item['id']}');
        } else if (item['size'] != data.size_buy.toDouble()) {
          var option_mod_order = {
            'size': data.size_buy.toDouble(),
            'price': item['price']
          };
          print('DEL ORDER BUY != size_buy ${data.size_buy}: ${item['id']}');
          await ftxApi
              .ftx_Post_Auth(env['URL_ftx'], 'orders/${item['id']}/modify',
                  data: option_mod_order, txt: 'MODIFY - id: ${item['id']}')
              .catchError((e, s) => handleError_1(
                  e, s, 'MODIFY - ftx_function', option_mod_order,
                  txt2: 'orders/${item['id']}\n${data.list_orders_exec}'));
        }
      }
    }
  }
}

*/
