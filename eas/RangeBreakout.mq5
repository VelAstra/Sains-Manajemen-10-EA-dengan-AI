//+------------------------------------------------------------------+
//|                                            RangeBreakout.mq5      |
//|                     Referensi: Rene Balke - Fx Bot Trading       |
//|         https://en.bmtrading.de / channel Range Breakout EA       |
//+------------------------------------------------------------------+
#property copyright "Sains Manajemen 261 - 10 EA dengan AI"
#property version   "1.00"
#property description "EA Range Breakout untuk MT5."
#property description "Menunggu range waktu tertentu, lalu trade saat"
#property description "harga breakout ke atas/bawah range tersebut."

#include <Trade/Trade.mqh>

CTrade trade;

//+------------------------------------------------------------------+
//| Input - Pengaturan Range                                          |
//+------------------------------------------------------------------+
input group "=== Range Settings ==="
input int    InpStartHour   = 7;        // Jam mulai range (waktu broker)
input int    InpStartMinute = 0;        // Menit mulai range
input int    InpEndHour     = 9;        // Jam akhir range
input int    InpEndMinute   = 0;        // Menit akhir range

//+------------------------------------------------------------------+
//| Input - Pengaturan Trade                                          |
//+------------------------------------------------------------------+
input group "=== Trade Settings ==="
input double InpLotSize     = 0.01;     // Ukuran lot
input double InpStopLoss    = 0.0;      // Stop loss (poin, 0 = nonaktif)
input double InpTakeProfit  = 0.0;      // Take profit (poin, 0 = nonaktif)
input int    InpMaxSpread   = 50;       // Batas maksimum spread (poin)
input int    InpMagicNumber = 1002;     // Nomor ajaib EA
input int    InpSlippage    = 30;       // Slippage (poin)
input bool   InpAllowReal   = false;    // IZINKAN berjalan di akun REAL (default: TIDAK)

//+------------------------------------------------------------------+
//| Variabel global                                                   |
//+------------------------------------------------------------------+
double rangeHigh   = 0.0;
double rangeLow    = 0.0;
bool   rangeActive = false;
bool   breakoutArmed = false;
int    currentDay  = -1;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!IsAccountAllowed())
      return(INIT_FAILED);

   if(InpLotSize <= 0)
     {
      Print("Ukuran lot harus lebih besar dari 0.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);

   Print("RangeBreakout EA berhasil diinisialisasi.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   int dayOfYear = dt.year * 1000 + dt.day_of_year;
   int rangeStart = InpStartHour * 60 + InpStartMinute;
   int rangeEnd   = InpEndHour   * 60 + InpEndMinute;
   int currentMin = dt.hour * 60 + dt.min;

   if(rangeStart >= rangeEnd)
     {
      Print("Jam mulai range harus lebih awal dari jam akhir range.");
      return;
     }

   if(dayOfYear != currentDay)
     {
      currentDay  = dayOfYear;
      rangeActive = false;
      breakoutArmed = false;
      rangeHigh   = 0.0;
      rangeLow    = 0.0;
     }

   if(currentMin < rangeStart)
      return;

   if(!rangeActive && !breakoutArmed && currentMin >= rangeStart)
     {
      rangeActive   = true;
      rangeHigh     = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      rangeLow      = rangeHigh;
     }

   if(rangeActive && currentMin < rangeEnd)
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double high = iHigh(_Symbol, _Period, 0);
      double low  = iLow(_Symbol, _Period, 0);
      if(ask > rangeHigh) rangeHigh = ask;
      if(bid < rangeLow)  rangeLow  = bid;
      if(high > rangeHigh) rangeHigh = high;
      if(low  < rangeLow)  rangeLow  = low;
      return;
     }

   if(rangeActive && currentMin >= rangeEnd)
     {
      rangeActive   = false;
      breakoutArmed = true;
     }

   if(!breakoutArmed)
      return;

   if(CountPositions() > 0)
      return;

   if(!IsSpreadOK())
      return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(ask > rangeHigh + SymbolInfoDouble(_Symbol, SYMBOL_POINT))
     {
      if(trade.Buy(InpLotSize, _Symbol, ask))
        {
         ApplySLTP();
         Print("Range breakdown ke atas: ", rangeHigh);
        }
     }
   else if(bid < rangeLow - SymbolInfoDouble(_Symbol, SYMBOL_POINT))
     {
      if(trade.Sell(InpLotSize, _Symbol, bid))
        {
         ApplySLTP();
         Print("Range breakdown ke bawah: ", rangeLow);
        }
     }
  }

//+------------------------------------------------------------------+
//| Cek apakah spread masih dalam batas                               |
//+------------------------------------------------------------------+
bool IsSpreadOK()
  {
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpread)
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//| Terapkan SL/TP ke posisi terbaru                                  |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Pengaman: blokir EA pada akun real                               |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Hitung jumlah posisi milik EA                                    |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+