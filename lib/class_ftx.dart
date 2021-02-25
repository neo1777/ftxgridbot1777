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
  //Set list_orders_fills;
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
      //this.list_orders_fills,
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
