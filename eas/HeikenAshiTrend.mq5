//+------------------------------------------------------------------+
//|                                      HeikenAshiTrend.mq5          |
//|                     Referensi: Rene Balke - Fx Bot Trading       |
//|                     https://www.youtube.com/@ReneBalke            |
//+------------------------------------------------------------------+
#property copyright "Sains Manajemen 261 - 10 EA dengan AI"
#property version   "1.00"
#property description "EA Heiken Ashi Trend untuk MT5."
#property description "Ikuti arah candle Heiken Ashi (hijau = buy,"
#property description "merah = sell) dengan flip pada perubahan warna."

#include <Trade/Trade.mqh>

CTrade trade;

input group "=== Heiken Ashi Settings ==="
input int              InpHABars      = 50;         // Bar history untuk kalkulasi HA

input group "=== Trade Settings ==="
input double           InpLotSize       = 0.01;     // Ukuran lot
input double           InpStopLoss      = 0.0;      // Stop loss (poin, 0 = nonaktif)
input double           InpTakeProfit    = 0.0;      // Take profit (poin, 0 = nonaktif)
input int              InpMaxSpread     = 50;       // Batas maksimum spread (poin)
input int              InpMagicNumber   = 1008;     // Nomor ajaib EA
input int              InpSlippage      = 30;       // Slippage (poin)
input bool             InpAllowReal     = false;    // IZINKAN berjalan di akun REAL (default: TIDAK)

datetime lastBarTime = 0;

int OnInit()
  {
   if(!IsAccountAllowed())
      return(INIT_FAILED);

   if(InpHABars < 5)
     {
      Print("Minimal bar history adalah 5.");
      return(INIT_PARAMETERS_INCORRECT);
     }

    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippage);

    Print("HeikenAshiTrend EA berhasil diinisialisasi.");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
  }

void OnTick()
  {
   if(!IsNewBar())
      return;

   if(!IsSpreadOK())
      return;

   MqlRates rates[];
   ResetLastError();
   int copied = CopyRates(_Symbol, _Period, 1, InpHABars, rates);
   if(copied < 5)
      return;

   datetime haTime[];
   double haOpen[], haClose[];
   ArrayResize(haTime, copied);
   ArrayResize(haOpen, copied);
   ArrayResize(haClose, copied);

   haOpen[0] = (rates[0].open + rates[0].close) / 2.0;
   haClose[0] = (rates[0].open + rates[0].high + rates[0].low + rates[0].close) / 4.0;

   for(int i = 1; i < copied; i++)
     {
      haOpen[i] = (haOpen[i - 1] + haClose[i - 1]) / 2.0;
      haClose[i] = (rates[i].open + rates[i].high + rates[i].low + rates[i].close) / 4.0;
      haTime[i] = rates[i].time;
     }

   int last = copied - 1;
   int prev = copied - 2;

   bool lastBull = (haClose[last] > haOpen[last]);
   bool prevBull = (haClose[prev] > haOpen[prev]);

   bool flipUp   = !prevBull && lastBull;
   bool flipDown = prevBull && !lastBull;

   if(!flipUp && !flipDown)
      return;

   ENUM_POSITION_TYPE existing = GetOpenPositionType();

   if(flipUp)
     {
      if(existing == POSITION_TYPE_SELL)
         ClosePositions();
      if(CountPositions() == 0)
         OpenPosition(ORDER_TYPE_BUY);
     }
   else if(flipDown)
     {
      if(existing == POSITION_TYPE_BUY)
         ClosePositions();
      if(CountPositions() == 0)
         OpenPosition(ORDER_TYPE_SELL);
     }
  }

bool IsNewBar()
  {
   datetime t = iTime(_Symbol, _Period, 0);
   if(t != lastBarTime)
     {
      lastBarTime = t;
      return(true);
     }
   return(false);
  }

bool IsSpreadOK()
  {
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpread)
      return(false);
   return(true);
  }

bool OpenPosition(ENUM_ORDER_TYPE type)
  {
    double price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                            : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   bool result = false;

   if(type == ORDER_TYPE_BUY)
      result = trade.Buy(InpLotSize, _Symbol, price);
   else
      result = trade.Sell(InpLotSize, _Symbol, price);

   if(result)
      ApplySLTP();

   return(result);
  }

void ApplySLTP()
  {
   if(InpStopLoss == 0 && InpTakeProfit == 0)
      return;

   if(!PositionSelect(_Symbol))
      return;

   ulong ticket = PositionGetInteger(POSITION_TICKET);
   double open = PositionGetDouble(POSITION_PRICE_OPEN);
   long type = PositionGetInteger(POSITION_TYPE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double sl = 0.0, tp = 0.0;

   if(InpStopLoss > 0)
     {
      if(type == POSITION_TYPE_BUY)
         sl = open - InpStopLoss * point;
      else
         sl = open + InpStopLoss * point;
     }

   if(InpTakeProfit > 0)
     {
      if(type == POSITION_TYPE_BUY)
         tp = open + InpTakeProfit * point;
      else
         tp = open - InpTakeProfit * point;
     }

   if(!trade.PositionModify(ticket, sl, tp))
      Print("Gagal set SL/TP, error: ", GetLastError());
  }

bool IsAccountAllowed()
  {
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL && !InpAllowReal)
     {
      Print("PENGAMAN: Akun ini adalah akun REAL. EA tidak berjalan untuk melindungi dana.");
      Print("Ubah InpAllowReal menjadi true hanya jika Anda memahami risikonya.");
      return(false);
     }
   return(true);
  }

int CountPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      count++;
     }
   return(count);
  }

ENUM_POSITION_TYPE GetOpenPositionType()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      return((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE));
     }
   return((ENUM_POSITION_TYPE)-1);
  }

void ClosePositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      ulong ticket = PositionGetInteger(POSITION_TICKET);
      if(!trade.PositionClose(ticket))
         Print("Gagal menutup posisi #", ticket, ", error: ", GetLastError());
     }
  }