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
| 1 | `eas/MovingAverageCrossover.mq5` | Moving Average Crossover | [Rene Balke](https://www.youtube.com/watch?v=T78Q7K3c11s) | Done (dengan hasil backtest) |
| 2 | `eas/RangeBreakout.mq5` | Range / Opening Range Breakout | [Rene Balke](https://www.youtube.com/@ReneBalke) | In Progress |
| 3 | TBD | Menyusul | - | Planned |
| 4 | TBD | Menyusul | - | Planned |
| 5 | TBD | Menyusul | - | Planned |
| 6 | TBD | Menyusul | - | Planned |
| 7 | TBD | Menyusul | - | Planned |
| 8 | TBD | Menyusul | - | Planned |
| 9 | TBD | Menyusul | - | Planned |
| 10 | TBD | Menyusul | - | Planned |

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

## Referensi Channel

- **Rene Balke - Fx Bot Trading**: https://www.youtube.com/@ReneBalke
- **IQCapital**: https://www.youtube.com/@IQCapital_io

## Panduan Optimasi

Optimasi EA di MT5 Strategy Tester menggunakan menu **Strategy Tester > Settings > Optimization**:

- Parameter yang dioptimasi (contoh): periode MA cepat, periode MA lambat, metode MA, SL/TP
- Kriteria optimasi: Profit factor, Expected Payoff, atau Balance Drawdown
- Hindari overfitting dengan uji forward (out-of-sample) setelah optimasi
