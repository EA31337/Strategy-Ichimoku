/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Ichimoku_Params_H8 : IchimokuParams {
  Indi_Ichimoku_Params_H8() : IchimokuParams(indi_ichi_defaults, PERIOD_H8) { shift = 0; }
} indi_ichi_h8;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Ichimoku_Params_H8 : StgParams {
  // Struct constructor.
  Stg_Ichimoku_Params_H8() : StgParams(stg_ichi_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)0;
    price_stop_method = 0;
    price_stop_level = (float)2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_ichi_h8;
