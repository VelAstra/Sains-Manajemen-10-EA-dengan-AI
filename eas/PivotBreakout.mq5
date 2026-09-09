//+------------------------------------------------------------------+
//|                                      PivotBreakout.mq5            |
//|                     Referensi: Rene Balke - Fx Bot Trading       |
//|                     https://www.youtube.com/@ReneBalke            |
//+------------------------------------------------------------------+
#property copyright "Sains Manajemen 261 - 10 EA dengan AI"
#property version   "1.00"
#property description "EA Pivot Points Breakout untuk MT5."
#property description "Buy saat harga menembus level R1 (pivot harian),"
#property description "Sell saat harga menembus level S1."

#include <Trade/Trade.mqh>

CTrade trade;

input group "=== Trade Settings ==="
input double           InpLotSize       = 0.01;     // Ukuran lot
input double           InpStopLoss      = 0.0;      // Stop loss (poin, 0 = nonaktif)
input double           InpTakeProfit    = 0.0;      // Take profit (poin, 0 = nonaktif)
input int              InpMaxSpread     = 50;       // Batas maksimum spread (poin)
input int              InpMagicNumber   = 1009;     // Nomor ajaib EA
input int              InpSlippage      = 30;       // Slippage (poin)
input bool             InpAllowReal     = false;    // IZINKAN berjalan di akun REAL (default: TIDAK)

datetime lastBarTime = 0;

int OnInit()
  {
   if(!IsAccountAllowed())
      return(INIT_FAILED);

    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippage);

    Print("PivotBreakout EA berhasil diinisialisasi.");
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

   double p, r1, s1;
   if(!GetPivotLevels(p, r1, s1))
      return;

   double closeCurr = iClose(_Symbol, _Period, 1);

   if(!IsPositionOpen() && closeCurr > r1)
      OpenPosition(ORDER_TYPE_BUY);
   else if(!IsPositionOpen() && closeCurr < s1)
      OpenPosition(ORDER_TYPE_SELL);

   ENUM_POSITION_TYPE existing = GetOpenPositionType();
   if(existing == POSITION_TYPE_BUY && closeCurr < s1)
     {
      ClosePositions();
      OpenPosition(ORDER_TYPE_SELL);
     }
   else if(existing == POSITION_TYPE_SELL && closeCurr > r1)
     {
      ClosePositions();
      OpenPosition(ORDER_TYPE_BUY);
     }
  }

bool GetPivotLevels(double &p, double &r1, double &s1)
  {
   datetime prevDayStart = iTime(_Symbol, PERIOD_D1, 1);
   datetime todayStart  = iTime(_Symbol, PERIOD_D1, 0);

   if(prevDayStart == 0 || todayStart == 0)
      return(false);

   MqlRates rates[];
   int got = CopyRates(_Symbol, _Period, prevDayStart, todayStart, rates);
   if(got < 24)
      return(false);

   double prevH = rates[0].high;
   double prevL = rates[0].low;

   for(int i = 1; i < got; i++)
     {
      if(rates[i].high > prevH)
         prevH = rates[i].high;
      if(rates[i].low < prevL)
         prevL = rates[i].low;
     }

   double prevC = rates[got - 1].close;

   p  = (prevH + prevL + prevC) / 3.0;
   r1 = 2.0 * p - prevL;
   s1 = 2.0 * p - prevH;

   return(true);
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

bool IsPositionOpen()
  {
   return(CountPositions() > 0);
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