/**
 * @file
 * Implements Ichimoku strategy based on the Ichimoku Kinko Hyo indicator.
 */

// User input params.
INPUT_GROUP("Ichimoku strategy: strategy params");
INPUT float Ichimoku_LotSize = 0;                // Lot size
INPUT int Ichimoku_SignalOpenMethod = 2;         // Signal open method (-127-127)
INPUT float Ichimoku_SignalOpenLevel = 0.0f;     // Signal open level
INPUT int Ichimoku_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int Ichimoku_SignalOpenFilterTime = 6;     // Signal open filter time
INPUT int Ichimoku_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int Ichimoku_SignalCloseMethod = 2;        // Signal close method (-127-127)
INPUT int Ichimoku_SignalCloseFilter = 0;        // Signal close filter (-127-127)
INPUT float Ichimoku_SignalCloseLevel = 0.0f;    // Signal close level
INPUT int Ichimoku_PriceStopMethod = 1;          // Price stop method
INPUT float Ichimoku_PriceStopLevel = 0;         // Price stop level
INPUT int Ichimoku_TickFilterMethod = 1;         // Tick filter method
INPUT float Ichimoku_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short Ichimoku_Shift = 0;                  // Shift
INPUT float Ichimoku_OrderCloseLoss = 0;         // Order close loss
INPUT float Ichimoku_OrderCloseProfit = 0;       // Order close profit
INPUT int Ichimoku_OrderCloseTime = -20;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("Ichimoku strategy: Ichimoku indicator params");
INPUT int Ichimoku_Indi_Ichimoku_Period_Tenkan_Sen = 9;      // Period Tenkan Sen
INPUT int Ichimoku_Indi_Ichimoku_Period_Kijun_Sen = 26;      // Period Kijun Sen
INPUT int Ichimoku_Indi_Ichimoku_Period_Senkou_Span_B = 52;  // Period Senkou Span B
INPUT int Ichimoku_Indi_Ichimoku_Shift = 0;                  // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_Ichimoku_Params_Defaults : IchimokuParams {
  Indi_Ichimoku_Params_Defaults()
      : IchimokuParams(::Ichimoku_Indi_Ichimoku_Period_Tenkan_Sen, ::Ichimoku_Indi_Ichimoku_Period_Kijun_Sen,
                       ::Ichimoku_Indi_Ichimoku_Period_Senkou_Span_B, ::Ichimoku_Indi_Ichimoku_Shift) {}
} indi_ichi_defaults;

// Defines struct with default user strategy values.
struct Stg_Ichimoku_Params_Defaults : StgParams {
  Stg_Ichimoku_Params_Defaults()
      : StgParams(::Ichimoku_SignalOpenMethod, ::Ichimoku_SignalOpenFilterMethod, ::Ichimoku_SignalOpenLevel,
                  ::Ichimoku_SignalOpenBoostMethod, ::Ichimoku_SignalCloseMethod, ::Ichimoku_SignalCloseFilter,
                  ::Ichimoku_SignalCloseLevel, ::Ichimoku_PriceStopMethod, ::Ichimoku_PriceStopLevel,
                  ::Ichimoku_TickFilterMethod, ::Ichimoku_MaxSpread, ::Ichimoku_Shift) {
    Set(STRAT_PARAM_OCL, Ichimoku_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, Ichimoku_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, Ichimoku_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, Ichimoku_SignalOpenFilterTime);
  }
} stg_ichi_defaults;

// Struct to define strategy parameters to override.
struct Stg_Ichimoku_Params : StgParams {
  IchimokuParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_Ichimoku_Params(IchimokuParams &_iparams, StgParams &_sparams)
      : iparams(indi_ichi_defaults, _iparams.tf.GetTf()), sparams(stg_ichi_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"

class Stg_Ichimoku : public Strategy {
 public:
  Stg_Ichimoku(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_Ichimoku *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    IchimokuParams _indi_params(indi_ichi_defaults, _tf);
    StgParams _stg_params(stg_ichi_defaults);
#ifdef __config__
    SetParamsByTf<IchimokuParams>(_indi_params, _tf, indi_ichi_m1, indi_ichi_m5, indi_ichi_m15, indi_ichi_m30,
                                  indi_ichi_h1, indi_ichi_h4, indi_ichi_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_ichi_m1, stg_ichi_m5, stg_ichi_m15, stg_ichi_m30, stg_ichi_h1,
                             stg_ichi_h4, stg_ichi_h8);
#endif
    // Initialize indicator.
    IchimokuParams ichi_params(_indi_params);
    _stg_params.SetIndicator(new Indi_Ichimoku(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_Ichimoku(_stg_params, _tparams, _cparams, "Ichimoku");
    return _strat;
  }

  /**
   * Check if Ichimoku indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _method (int) - signal method to use by using bitwise AND operation
   *   _level (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_Ichimoku *_indi = GetIndicator();
    bool _result = _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _indi.IsIncreasing(2, LINE_TENKANSEN, _shift);
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= _indi[CURR][(int)LINE_TENKANSEN] >= _indi[CURR][(int)LINE_CHIKOUSPAN];
          // Buy 1: Tenkan-sen crosses Kijun-sen upwards.
          if (METHOD(_method, 1)) _result &= _indi[PREV][(int)LINE_TENKANSEN] < _indi[PREV][(int)LINE_CHIKOUSPAN];
          if (METHOD(_method, 2)) _result &= _indi.IsIncreasing(2, LINE_CHIKOUSPAN, _shift);
          if (METHOD(_method, 3)) _result &= _indi.IsIncreasing(2, LINE_TENKANSEN, _shift);
          if (METHOD(_method, 4)) _result &= _indi.IsIncreasing(2, LINE_KIJUNSEN, _shift);
          if (METHOD(_method, 5)) _result &= _indi.IsIncreasing(2, LINE_SENKOUSPANA, _shift);
          if (METHOD(_method, 6)) _result &= _indi.IsIncreasing(2, LINE_SENKOUSPANB, _shift);
        }
        // Buy 2: Chinkou Span crosses chart upwards; price is ib the cloud.
        // @todo: if
        // ((iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+1)<iClose(NULL,pich2,pkijun+1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+0)>=iClose(NULL,pich2,pkijun+0))&&((iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))||(iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))))
        // Buy 3: Price crosses Senkou Span-B upwards; price is outside Senkou Span cloud.
        // @todo:
        // (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,1)>iClose(NULL,pich2,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0)<=iClose(NULL,pich2,0)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)<iClose(NULL,pich2,0))
        break;
      case ORDER_TYPE_SELL:
        _result &= _indi.IsDecreasing(2, LINE_TENKANSEN, _shift);
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= _indi[CURR][(int)LINE_TENKANSEN] <= _indi[CURR][(int)LINE_CHIKOUSPAN];
          // Sell 1: Tenkan-sen crosses Kijun-sen downwards.
          if (METHOD(_method, 1)) _result &= _indi[PREV][(int)LINE_TENKANSEN] > _indi[PREV][(int)LINE_CHIKOUSPAN];
          if (METHOD(_method, 2)) _result &= _indi.IsDecreasing(2, LINE_CHIKOUSPAN, _shift);
          if (METHOD(_method, 3)) _result &= _indi.IsDecreasing(2, LINE_TENKANSEN, _shift);
          if (METHOD(_method, 4)) _result &= _indi.IsDecreasing(2, LINE_KIJUNSEN, _shift);
          if (METHOD(_method, 5)) _result &= _indi.IsDecreasing(2, LINE_SENKOUSPANA, _shift);
          if (METHOD(_method, 6)) _result &= _indi.IsDecreasing(2, LINE_SENKOUSPANB, _shift);
        }
        // Sell 2: Chinkou Span crosses chart downwards; price is ib the cloud.
        // @todo:
        // ((iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+1)>iClose(NULL,pich2,pkijun+1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+0)<=iClose(NULL,pich2,pkijun+0))&&((iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))||(iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))))
        // Sell 3: Price crosses Senkou Span-B downwards; price is outside Senkou Span cloud.
        // @todo:
        // (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,1)<iClose(NULL,pich2,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0)>=iClose(NULL,pich2,0)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)>iClose(NULL,pich2,0))
        break;
    }
    return _result;
  }
};
