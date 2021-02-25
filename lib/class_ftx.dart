import 'dart:convert';
import 'package:pausable_timer/pausable_timer.dart';

class PrimitiveWrapper {
  double ask_start;
  double bid_start;
  double last_start;
  double ask_first_order;
  double bid_first_order;
  String posizione_start;
  String posizione_now;
  Map map_limit;
  var size_buy;
  var size_sell;
  var size_base;
  var size_add;
  Set list_orders_sell;
  Set list_orders_buy;
  Set list_orders_exec;
  Set list_orders_delete;
  var increment;
  var increment_base;
  var sizeIncrement;

  PausableTimer time_ord;
  PausableTimer time_market;
  PausableTimer time_sur;
  PausableTimer time_mod;
  PausableTimer time_data;
  PausableTimer time_time;
  PausableTimer time_exec;
  PausableTimer time_print;
  var limit_order;
  var freeCollateral;
  var balance;
  var position_open;
  var open_orders;
  var type;

  PrimitiveWrapper(
      {this.ask_start,
      this.bid_start,
      this.last_start,
      this.ask_first_order,
      this.bid_first_order,
      this.posizione_start,
      this.posizione_now,
      this.map_limit,
      this.size_buy,
      this.size_sell,
      this.size_base,
      this.size_add,
      this.list_orders_sell,
      this.list_orders_buy,
      this.list_orders_exec,
      this.list_orders_delete,
      this.increment,
      this.increment_base,
      this.sizeIncrement,
      this.time_ord,
      this.time_market,
      this.time_sur,
      this.time_mod,
      this.time_data,
      this.time_time,
      this.time_exec,
      this.time_print,
      this.limit_order,
      this.freeCollateral,
      this.balance,
      this.position_open,
      this.open_orders,
      this.type});
}

/////////////////////////////////////////////////
// To parse this JSON data, do
//
//     final historical = historicalFromMap(jsonString);
Historical historicalFromMap(String str) =>
    Historical.fromMap(json.decode(str));

String historicalToMap(Historical data) => json.encode(data.toMap());

class Historical {
  Historical({
    this.result_h,
    this.success,
  });

  List<Result_h> result_h;
  bool success;

  factory Historical.fromMap(Map<String, dynamic> json) => Historical(
        result_h: List<Result_h>.from(
            json['result_h'].map((x) => Result_h.fromMap(x))),
        success: json['success'],
      );

  Map<String, dynamic> toMap() => {
        'result_h': List<dynamic>.from(result_h.map((x) => x.toMap())),
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

/////////////////////////////////////////////////
// To parse this JSON data, do
//
//     final market = marketFromMap(jsonString);
GetMarketCross marketFromMap(String str) =>
    GetMarketCross.fromMap(json.decode(str));

String marketToMap(GetMarketCross data) => json.encode(data.toMap());

class GetMarketCross {
  GetMarketCross({
    this.result_m,
    this.success,
  });

  Result_m result_m;
  bool success;

  factory GetMarketCross.fromMap(Map<String, dynamic> json) => GetMarketCross(
        result_m: Result_m.fromMap(json['result_m']),
        success: json['success'],
      );

  Map<String, dynamic> toMap() => {
        'result_m': result_m.toMap(),
        'success': success,
      };
}

class Result_m {
  Result_m({
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

  factory Result_m.fromMap(Map<String, dynamic> json) => Result_m(
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
