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
| 1 | `eas/MovingAverageCrossover.mq5` | Moving Average Crossover | [Rene Balke](https://www.youtube.com/watch?v=T78Q7K3c11s) | In Progress |
| 2 | `eas/RangeBreakout.mq5` | Range / Opening Range Breakout | [Rene Balke](https://www.youtube.com/@ReneBalke) | In Progress |
| 3 | TBD | Menyusul | - | Planned |
| 4 | TBD | Menyusul | - | Planned |
| 5 | TBD | Menyusul | - | Planned |
| 6 | TBD | Menyusul | - | Planned |
| 7 | TBD | Menyusul | - | Planned |
| 8 | TBD | Menyusul | - | Planned |
| 9 | TBD | Menyusul | - | Planned |
| 10 | TBD | Menyusul | - | Planned |

## Referensi Channel

- **Rene Balke - Fx Bot Trading**: https://www.youtube.com/@ReneBalke
- **IQCapital**: https://www.youtube.com/@IQCapital_io

## Panduan Optimasi

Optimasi EA di MT5 Strategy Tester menggunakan menu **Strategy Tester > Settings > Optimization**:

- Parameter yang dioptimasi (contoh): periode MA cepat, periode MA lambat, metode MA, SL/TP
- Kriteria optimasi: Profit factor, Expected Payoff, atau Balance Drawdown
- Hindari overfitting dengan uji forward (out-of-sample) setelah optimasi
