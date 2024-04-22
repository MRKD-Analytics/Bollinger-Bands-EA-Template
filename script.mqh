


/*
   This file contains a script for a generic Bollinger Bands strategy. 
   
   Sends a BUY signal when candle low is below lower band, and closes above lower band 
   sends a SELL signal when candle high is above upper band , but closes below upper band 
   
   
   DISCLAIMER: This script does not guarantee future profits, and is 
   created for demonstration purposes only. Do not use this script 
   with live funds. 
*/

/*
#include <B63/Generic.mqh> 
#include "trade_ops.mqh"
*/ 
#include <utilities/Utilities.mqh> 
#include <utilities/TradeOps.mqh> 

enum TradeSignal { Long, Short, None }; 

input int      InpMagic       = 111111; // Magic Number
input int      InpBandsLen    = 14; 
input int      InpNumSd       = 2;

class CBBandsTrade : public CTradeOps {
private:
            int      bbands_length_, num_sdev_;  
public:
   CBBandsTrade();
   ~CBBandsTrade() {}
   
            void        Stage();
            TradeSignal Signal(); 
            int         SendOrder(TradeSignal signal); 
            int         ClosePositions(ENUM_ORDER_TYPE order_type); 
            bool        DeadlineReached(); 
            
            double      BBandsUpper();
            double      BBandsLower(); 
};

CBBandsTrade::CBBandsTrade() 
   : CTradeOps(Symbol(), InpMagic)
   , bbands_length_ (InpBandsLen)
   , num_sdev_ (InpNumSd) {}
   
double   CBBandsTrade::BBandsUpper() { return iBands(Symbol(), PERIOD_CURRENT, bbands_length_, num_sdev_, 0, PRICE_CLOSE, MODE_UPPER, 1); }
double   CBBandsTrade::BBandsLower() { return iBands(Symbol(), PERIOD_CURRENT, bbands_length_, num_sdev_, 0, PRICE_CLOSE, MODE_LOWER, 1); } 


bool     CBBandsTrade::DeadlineReached() { return UTIL_TIME_HOUR(TimeCurrent()) >= 20; }

TradeSignal CBBandsTrade::Signal() {
   double bands_upper = BBandsUpper();
   double bands_lower = BBandsLower(); 
   
   // long condition
   double last_high = UTIL_CANDLE_HIGH();
   double last_low = UTIL_CANDLE_LOW();
   double last_close = UTIL_CANDLE_CLOSE(1);
   
   if (last_low < bands_lower && last_close > bands_lower) return Long;
   if (last_high > bands_upper && last_close < bands_upper) return Short; 
   return None; 
}

int         CBBandsTrade::SendOrder(TradeSignal signal) {
   ENUM_ORDER_TYPE order_type;
   double entry_price;
   
   switch(signal) {
      case Long:
         order_type = ORDER_TYPE_BUY;
         entry_price = UTIL_PRICE_ASK();
         OP_OrdersCloseBatchOrderType(ORDER_TYPE_SELL); 
         break; 
      case Short:
         order_type = ORDER_TYPE_SELL;
         entry_price = UTIL_PRICE_BID(); 
         OP_OrdersCloseBatchOrderType(ORDER_TYPE_BUY ); 
         break;
      case None:
         return -1; 
      default:
         return -1; 
      
   }
   return OP_OrderOpen(Symbol(), order_type, 0.01, entry_price, 0, 0, NULL); 
}

void        CBBandsTrade::Stage() {
   if (DeadlineReached()) {
      OP_OrdersCloseAll(); 
      return; 
   }
   TradeSignal signal = Signal(); 
   if (signal == None) return; 
   SendOrder(signal);
}

CBBandsTrade bbands_trade; 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (UTIL_IS_NEW_CANDLE()) {
      bbands_trade.Stage();
   }
   
  }
//+------------------------------------------------------------------+
