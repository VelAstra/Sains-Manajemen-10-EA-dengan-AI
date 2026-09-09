//+------------------------------------------------------------------+
//|                                       MacdCrossover.mq5           |
//|                     Referensi: Rene Balke - Fx Bot Trading       |
//|                     https://www.youtube.com/@ReneBalke            |
//+------------------------------------------------------------------+
#property copyright "Sains Manajemen 261 - 10 EA dengan AI"
#property version   "1.00"
#property description "EA MACD Crossover untuk MT5."
#property description "Buy saat garis MACD memotong garis signal ke atas,"
#property description "Sell saat memotong ke bawah."

#include <Trade/Trade.mqh>

CTrade trade;

input group "=== MACD Settings ==="
input int              InpFastEMA     = 12;         // Periode EMA cepat
input int              InpSlowEMA     = 26;         // Periode EMA lambat
input int              InpSignalSMA   = 9;          // Periode signal SMA
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; // Harga yang dipakai

input group "=== Trade Settings ==="
input double           InpLotSize       = 0.01;     // Ukuran lot
input double           InpStopLoss      = 0.0;      // Stop loss (poin, 0 = nonaktif)
input double           InpTakeProfit    = 0.0;      // Take profit (poin, 0 = nonaktif)
input int              InpMaxSpread     = 50;       // Batas maksimum spread (poin)
input int              InpMagicNumber   = 1003;     // Nomor ajaib EA
input int              InpSlippage      = 30;       // Slippage (poin)
input bool             InpAllowReal     = false;    // IZINKAN berjalan di akun REAL (default: TIDAK)

int      hMACD = INVALID_HANDLE;
datetime lastBarTime = 0;

int OnInit()
  {
   if(!IsAccountAllowed())
      return(INIT_FAILED);

   if(InpFastEMA <= 0 || InpSlowEMA <= 0 || InpSignalSMA <= 0)
     {
      Print("Periode MACD harus lebih besar dari 0.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   hMACD = iMACD(_Symbol, _Period, InpFastEMA, InpSlowEMA, InpSignalSMA, InpAppliedPrice);

   if(hMACD == INVALID_HANDLE)
     {
      Print("Gagal membuat handle indikator MACD.");
      return(INIT_FAILED);
     }

    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippage);

    Print("MacdCrossover EA berhasil diinisialisasi.");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(hMACD != INVALID_HANDLE)
      IndicatorRelease(hMACD);
  }

void OnTick()
  {
   if(!IsNewBar())
      return;

   if(!IsSpreadOK())
      return;

   double macd[], signal[];
   ArraySetAsSeries(macd, true);
   ArraySetAsSeries(signal, true);

   if(CopyBuffer(hMACD, 0, 0, 2, macd) < 2)
      return;
   if(CopyBuffer(hMACD, 1, 0, 2, signal) < 2)
      return;

   double macdPrev = macd[1];
   double macdCurr = macd[0];
   double sigPrev = signal[1];
   double sigCurr = signal[0];

   bool crossUp   = (macdPrev <= sigPrev) && (macdCurr > sigCurr);
   bool crossDown = (macdPrev >= sigPrev) && (macdCurr < sigCurr);

   if(!crossUp && !crossDown)
      return;

   ENUM_POSITION_TYPE existing = GetOpenPositionType();

   if(crossUp)
     {
      if(existing == POSITION_TYPE_SELL)
         ClosePositions();
      if(CountPositions() == 0)
         OpenPosition(ORDER_TYPE_BUY);
     }
   else if(crossDown)
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