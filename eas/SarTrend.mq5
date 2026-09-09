//+------------------------------------------------------------------+
//|                                       SarTrend.mq5                |
//|                     Referensi: Rene Balke - Fx Bot Trading       |
//|                     https://www.youtube.com/@ReneBalke            |
//+------------------------------------------------------------------+
#property copyright "Sains Manajemen 261 - 10 EA dengan AI"
#property version   "1.00"
#property description "EA Parabolic SAR Trend untuk MT5."
#property description "Buy saat SAR mengindikasikan uptrend,"
#property description "Sell saat mengindikasikan downtrend."

#include <Trade/Trade.mqh>

CTrade trade;

input group "=== Parabolic SAR Settings ==="
input double           InpSARStep     = 0.02;       // Langkah SAR
input double           InpSARMax      = 0.2;        // Nilai maksimum SAR

input group "=== Trade Settings ==="
input double           InpLotSize       = 0.01;     // Ukuran lot
input double           InpStopLoss      = 0.0;      // Stop loss (poin, 0 = nonaktif)
input double           InpTakeProfit    = 0.0;      // Take profit (poin, 0 = nonaktif)
input int              InpMaxSpread     = 50;       // Batas maksimum spread (poin)
input int              InpMagicNumber   = 1010;     // Nomor ajaib EA
input int              InpSlippage      = 30;       // Slippage (poin)
input bool             InpAllowReal     = false;    // IZINKAN berjalan di akun REAL (default: TIDAK)

int      hSAR = INVALID_HANDLE;
datetime lastBarTime = 0;

int OnInit()
  {
   if(!IsAccountAllowed())
      return(INIT_FAILED);

   if(InpSARStep <= 0 || InpSARMax <= 0)
     {
      Print("Step dan max SAR harus lebih besar dari 0.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   hSAR = iSAR(_Symbol, _Period, InpSARStep, InpSARMax);

   if(hSAR == INVALID_HANDLE)
     {
      Print("Gagal membuat handle indikator Parabolic SAR.");
      return(INIT_FAILED);
     }

    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippage);

    Print("SarTrend EA berhasil diinisialisasi.");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(hSAR != INVALID_HANDLE)
      IndicatorRelease(hSAR);
  }

void OnTick()
  {
   if(!IsNewBar())
      return;

   if(!IsSpreadOK())
      return;

   double sarVal[];
   ArraySetAsSeries(sarVal, true);

   if(CopyBuffer(hSAR, 0, 0, 3, sarVal) < 3)
      return;

   double sarPrev = sarVal[2];   // bar posisi 2 (selesai)
   double sarCurr = sarVal[1];   // bar posisi 1 (selesai)

   if(sarPrev == 0.0 || sarCurr == 0.0)
      return;

   double closePrev = iClose(_Symbol, _Period, 2);
   double closeCurr = iClose(_Symbol, _Period, 1);

   bool bullPrev = (sarPrev < closePrev);
   bool bullCurr = (sarCurr < closeCurr);

   bool flipUp   = !bullPrev && bullCurr;
   bool flipDown = bullPrev && !bullCurr;

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