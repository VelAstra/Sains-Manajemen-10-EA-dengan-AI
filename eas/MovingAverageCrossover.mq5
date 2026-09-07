//+------------------------------------------------------------------+
//|                                    MovingAverageCrossover.mq5    |
//|                     Referensi: Rene Balke - Fx Bot Trading       |
//|         https://www.youtube.com/watch?v=T78Q7K3c11s              |
//+------------------------------------------------------------------+
#property copyright "Sains Manajemen 261 - 10 EA dengan AI"
#property version   "1.00"
#property description "EA Moving Average Crossover untuk MT5."
#property description "Buy saat MA cepat memotong MA lambat ke atas,"
#property description "Sell saat memotong ke bawah."

#include <Trade/Trade.mqh>

CTrade trade;

//+------------------------------------------------------------------+
//| Input - Pengaturan Moving Average                                 |
//+------------------------------------------------------------------+
input group "=== Moving Average Settings ==="
input int              InpFastMAPeriod = 10;          // Periode MA cepat
input int              InpSlowMAPeriod = 50;          // Periode MA lambat
input ENUM_MA_METHOD   InpMAMethod     = MODE_SMA;    // Metode MA (SMA/EMA/SMMA/LWMA)
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; // Harga yang dipakai

//+------------------------------------------------------------------+
//| Input - Pengaturan Trade                                          |
//+------------------------------------------------------------------+
input group "=== Trade Settings ==="
input double           InpLotSize       = 0.01;       // Ukuran lot
input double           InpStopLoss      = 0.0;        // Stop loss (poin, 0 = nonaktif)
input double           InpTakeProfit    = 0.0;        // Take profit (poin, 0 = nonaktif)
input int              InpMaxSpread     = 50;         // Batas maksimum spread (poin)
input int              InpMagicNumber   = 1001;       // Nomor ajaib EA
input int              InpSlippage      = 30;         // Slippage (poin)

//+------------------------------------------------------------------+
//| Variabel global                                                   |
//+------------------------------------------------------------------+
int      hFastMA = INVALID_HANDLE;
int      hSlowMA = INVALID_HANDLE;
int      prevBarTime = 0;
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpFastMAPeriod <= 0 || InpSlowMAPeriod <= 0)
     {
      Print("Periode MA harus lebih besar dari 0.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   hFastMA = iMA(_Symbol, _Period, InpFastMAPeriod, 0, InpMAMethod, InpAppliedPrice);
   hSlowMA = iMA(_Symbol, _Period, InpSlowMAPeriod, 0, InpMAMethod, InpAppliedPrice);

   if(hFastMA == INVALID_HANDLE || hSlowMA == INVALID_HANDLE)
     {
      Print("Gagal membuat handle indikator MA.");
      return(INIT_FAILED);
     }

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);

   prevBarTime = Bars(_Symbol, _Period);

   Print("MovingAverageCrossover EA berhasil diinisialisasi.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(hFastMA != INVALID_HANDLE)
      IndicatorRelease(hFastMA);
   if(hSlowMA != INVALID_HANDLE)
      IndicatorRelease(hSlowMA);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsNewBar())
      return;

   if(!IsSpreadOK())
      return;

   double fastVal[], slowVal[];
   ArraySetAsSeries(fastVal, true);
   ArraySetAsSeries(slowVal, true);

   if(CopyBuffer(hFastMA, 0, 0, 2, fastVal) < 2)
      return;
   if(CopyBuffer(hSlowMA, 0, 0, 2, slowVal) < 2)
      return;

   double fastPrev = fastVal[1];
   double fastCurr = fastVal[0];
   double slowPrev = slowVal[1];
   double slowCurr = slowVal[0];

   bool crossUp   = (fastPrev <= slowPrev) && (fastCurr > slowCurr);
   bool crossDown = (fastPrev >= slowPrev) && (fastCurr < slowCurr);

   if(CountPositions() > 0)
      return;

   if(crossUp)
      OpenPosition(ORDER_TYPE_BUY);
   else if(crossDown)
      OpenPosition(ORDER_TYPE_SELL);
  }

//+------------------------------------------------------------------+
//| Cek apakah sudah ada bar baru                                     |
//+------------------------------------------------------------------+
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
//| Buka posisi                                                       |
//+------------------------------------------------------------------+
bool OpenPosition(ENUM_ORDER_TYPE type)
  {
   int sl = 0, tp = 0;

   if(InpStopLoss > 0)
     {
      if(type == ORDER_TYPE_BUY)
         sl = (int)InpStopLoss;
      else
         sl = -(int)InpStopLoss;
     }

   if(InpTakeProfit > 0)
     {
      if(type == ORDER_TYPE_BUY)
         tp = (int)InpTakeProfit;
      else
         tp = -(int)InpTakeProfit;
     }

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