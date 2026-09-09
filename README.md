# Sains-Manajemen-10-EA-dengan-AI
Mata Kuliah: Sains Manajemen


Nama: Rayhan Haldi Hermawan NIM: 24/545406/PA/23176


Project Sains Manajemen 261 - Membuat 10 Expert Advisor (EA) untuk MetaTrader 5 dengan bantuan AI.

## Cara Kerja

1. Ekspor file `.mq5` ke folder `MQL5/Experts/` di data folder MT5
2. Kompilasi di MetaEditor
3. Backtest di MT5 Strategy Tester
4. Optimasi parameter dengan built-in Strategy Optimization

## Daftar EA

| No | EA | Strategi | Referensi | Status |
|----|----|----------|-----------|--------|
| 1 | `eas/MovingAverageCrossover.mq5` | Moving Average Crossover | [Rene Balke](https://www.youtube.com/watch?v=T78Q7K3c11s) | Done (dengan hasil backtest & optimasi) |
| 2 | `eas/RangeBreakout.mq5` | Opening Range Breakout (range sesi pagi 07:00–09:00) | [Rene Balke](https://www.youtube.com/@ReneBalke) | Done (dengan hasil backtest) |
| 3 | `eas/MacdCrossover.mq5` | MACD Crossover | [Rene Balke](https://www.youtube.com/@ReneBalke) | Done (dengan hasil backtest) |
| 4 | `eas/RsiPullback.mq5` | RSI Pullback (oversold/overbought) | [Rene Balke](https://www.youtube.com/@ReneBalke) | Done (dengan hasil backtest) |
| 5 | `eas/StochasticCross.mq5` | Stochastic %K/%D Crossover | [Rene Balke](https://www.youtube.com/@ReneBalke) | Done (dengan hasil backtest) |
| 6 | `eas/BollingerReversion.mq5` | Bollinger Bands Mean Reversion | [Rene Balke](https://www.youtube.com/@ReneBalke) | Done (dengan hasil backtest) |
| 7 | `eas/CciReversal.mq5` | CCI Reversal (±100) | [Rene Balke](https://www.youtube.com/@ReneBalke) | Done (dengan hasil backtest) |
| 8 | `eas/HeikenAshiTrend.mq5` | Heiken Ashi Trend Following | [Rene Balke](https://www.youtube.com/@ReneBalke) | Done (dengan hasil backtest) |
| 9 | `eas/PivotBreakout.mq5` | Pivot Points Breakout (R1/S1) | [Rene Balke](https://www.youtube.com/@ReneBalke) | Done (dengan hasil backtest) |
| 10 | `eas/SarTrend.mq5` | Parabolic SAR Trend | [Rene Balke](https://www.youtube.com/@ReneBalke) | Done (dengan hasil backtest) |

## Hasil Backtest EA 1 - MovingAverageCrossover

Pengujian: **EURUSD M15, 2024-01-01 s.d. 2024-06-30**, model *Every tick based on real ticks*
(kualitas histori 99%), modal virtual 10.000 USD, leverage 1:100.

| Metrik | Parameter Bawaan (MA 10/50) | Terbaik Optimasi (Pass #88) |
|---|---|---|
| Periode MA cepat | 10 | 5 |
| Periode MA lambat | 50 | 70 |
| Stop loss | 0 (nonaktif) | 0 (nonaktif) |
| Take profit | 0 (nonaktif) | 100 poin |
| Total net profit | -56,60 USD | +43,80 USD |
| Profit factor | 0,75 | 1,39 |
| Total trades | 256 | 266 |
| Max equity drawdown | 1,00% | 0,20% |
| Recovery factor | -0,56 | 2,21 |
| Sharpe ratio | -1,89 | 4,43 |

Optimasi dilakukan pada 216 kombinasi (MA cepat 5-20, MA lambat 30-80, SL 0-200, TP 0-200 poin).
Kesimpulan: strategi crossover hanya menguntungkan dengan kombinasi parameter yang tepat dan
take profit aktif; parameter bawaan MA 10/50 tanpa TP menghasilkan profit factor < 1.

## Hasil Backtest EA 1-10 (Parameter Bawaan)

Pengujian: **EURUSD M15, 2024-01-01 s.d. 2024-06-30**, model *Every tick based on real ticks*,
modal virtual 10.000 USD, leverage 1:100. Parameter bawaan sesuai file EA.

| No | EA | Total Net Profit | Profit Factor | Total Trades | Max Equity DD | Sharpe | Keterangan |
|----|----|------------------|---------------|--------------|---------------|--------|------------|
| 1 | MovingAverageCrossover | -56,60 USD | 0,75 | 256 | 1,00% | -1,89 | Terbaik setelah optimasi: +43,80 (PF 1,39) |
| 2 | RangeBreakout | +19,67 USD | 1,08 | 405 | 0,40% | 0,66 | Breakout range pagi (07:00–09:00); profit tipis |
| 3 | MacdCrossover | -21,93 USD | 0,92 | 438 | 0,51% | -0,73 | Rugi kecil, perlu optimasi |
| 4 | RsiPullback | **+79,06 USD** | **1,66** | 111 | 0,40% | **2,62** | Profit konsisten |
| 5 | StochasticCross | -68,25 USD | 0,83 | 794 | 0,91% | -2,27 | Banyak sinyal, rugi |
| 6 | BollingerReversion | **+42,88 USD** | 1,23 | 212 | 0,44% | 1,42 | Profit, mean reversion |
| 7 | CciReversal | -5,86 USD | 0,98 | 721 | 0,65% | -0,20 | Hampir breakeven (rugi tipis) |
| 8 | HeikenAshiTrend | -161,98 USD | 0,80 | 3097 | 1,65% | -5,00 | Terlalu banyak flip |
| 9 | PivotBreakout | -100,95 USD | 0,36 | 58 | 1,16% | -3,35 | Sangat jarang sinyal |
| 10 | SarTrend | -31,32 USD | 0,93 | 1094 | 0,59% | -1,03 | Sering flip, rugi |

EA yang menguntungkan dengan parameter bawaan: **RsiPullback** dan **BollingerReversion**.
Kombinasi parameter dari setiap EA dapat dioptimasi lebih lanjut lewat *Strategy Optimization* MT5.

## Referensi

1. Balke, René. *BM Trading — Free Expert Advisors for MetaTrader 5.* https://en.bmtrading.de (diakses 8 September 2026).
2. René Balke. *Moving Average MT5 EA Tutorial.* YouTube. https://youtu.be/T78Q7K3c11s (diakses 8 September 2026).
3. **Rene Balke - Fx Bot Trading** (kanal). https://www.youtube.com/@ReneBalke
4. **IQCapital** (kanal). https://www.youtube.com/@IQCapital_io
5. MetaQuotes. *MQL5 Reference.* https://www.mql5.com/en/docs (diakses 8 September 2026).

## Panduan Optimasi

Optimasi EA di MT5 Strategy Tester menggunakan menu **Strategy Tester > Settings > Optimization**:

- Parameter yang dioptimasi (contoh): periode MA cepat, periode MA lambat, metode MA, SL/TP
- Kriteria optimasi: Profit factor, Expected Payoff, atau Balance Drawdown
- Hindari overfitting dengan uji forward (out-of-sample) setelah optimasi
