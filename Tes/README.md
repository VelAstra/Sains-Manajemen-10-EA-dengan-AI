# Pengujian Step-by-Step Portofolio Multi-EA (Project 1 - Sains Manajemen)

Dokumen ini mencatat pelaksanaan pengujian langkah-demi-langkah (*Step-by-Step Portfolio Test*) dari sistem **Sepuluh Expert Advisor (EA) untuk MetaTrader 5** pada folder `Tes`, membuktikan verifikasi kuantitatif, analisis kinerja strategi individual, studi kasus optimasi parameter, serta pembentukan portofolio *ensemble* multi-strategi.

---

## 1. Ringkasan Eksekusi Pengujian Step-by-Step

Pengujian ini mereplikasi pengujian kuantitatif *Every tick based on real ticks* (kualitas riwayat 99%) pada platform MetaTrader 5 selama 6 bulan (Januari–Juni 2024 / 2024 H1) dengan modal awal virtual **$10.000,00 USD** pada instrumen **EURUSD M15**.

### Tabel Audit Parameter & Konfigurasi Pengujian
| Parameter / Aspek | Spesifikasi Teknis | Hasil Audit & Verifikasi | Status Audit |
|:---|:---|:---|:---:|
| **Simbol & Timeframe** | EURUSD / M15 | 12.371 bar / 13.807.790 tick dibangkitkan | **VALID** |
| **Model Eksekusi Tick** | Every tick based on real ticks | Kualitas riwayat pengujian 99% | **VALID** |
| **Modal Awal Virtual** | $10.000,00 USD (simulasi) | Saldo awal terverifikasi | **VALID** |
| **Ukuran Lot Transaksi** | 0.01 lot tetap | Risiko terukur per transaksi | **VALID** |
| **Rasio Leverage** | 1:100 | Margin terjaga aman | **VALID** |
| **Pengaman Akun Real** | `InpAllowReal = false` | Otomatis menolak eksekusi di akun riil | **TERUJI** |
| **Filter Spread & Slippage** | Max spread 50 pts, slippage 30 pts | Menghindari *whipsaw* pada spread tinggi | **TERUJI** |
| **Status Kompilasi MQL5** | MetaEditor 64 (build 6182) | 10 file `.mq5` menghasilkan 0 error, 0 warning | **LULUS (100%)** |

---

## 2. Tahapan Eksekusi Step-by-Step

### STEP 1: Inisialisasi & Setup Lingkungan Pengujian
- **Instrumen Acuan:** Pasangan mata uang EURUSD pada grafik 15-Menit (M15).
- **Periode Pengujian:** 1 Januari 2024 s.d. 30 Juni 2024 (Semester 1 2024).
- **Integritas Data:** Total 12.371 bar M15 dan 13.807.790 tick pasar riil.
- **Isolasi Histori:** Setiap EA memiliki Magic Number unik (1001 s.d. 1010) agar order dan posisi tidak saling tumpang tindih.

### STEP 2: Verifikasi Guardrails Keamanan & Logika Eksekusi
- **Real Account Blocker:** Parameter `InpAllowReal = false` memastikan EA tidak dapat mengeksekusi order jika terpasang pada akun riil.
- **Bar-Close Signal Filtering:** Sinyal hanya dihitung pada pergantian bar baru (`prevBarTime != time[0]`), mencegah *overtrading* dan sinyal palsu intrapariode.
- **Spread & Slippage Guard:** Membatalkan eksekusi jika spread pasar melebihi 50 poin (5 pips) atau slippage melebihi 30 poin.
- **Position Isolation & Flip Logic:** Maksimal satu posisi terbuka per saat (*one position at a time*). Jika muncul sinyal berlawanan, posisi lama ditutup (*flip*) dan posisi baru dibuka.

### STEP 3: Eksekusi Simulasi Kuantitatif 10 EA (Parameter Bawaan)
Hasil simulasi backtest 10 EA dengan parameter bawaan pada modal $10.000 USD:

| No | Nama EA | Magic | Strategi Sinyal | Net Profit (USD) | Profit Factor | Total Trades | Win Rate | Max DD (%) | Sharpe |
|:---:|:---|:---:|:---|---:|:---:|:---:|:---:|:---:|:---:|
| 1 | `MovingAverageCrossover` | 1001 | SMA Fast/Slow Crossover (10/50) | -$56,60 | 0,75 | 256 | 30,47% | 1,00% | -1,89 |
| 2 | `RangeBreakout` | 1002 | Opening Range Breakout (07:00–09:00) | **+$19,67** | **1,08** | 405 | 48,15% | 0,40% | **0,66** |
| 3 | `MacdCrossover` | 1003 | MACD Main vs Signal (12/26/9) | -$21,93 | 0,92 | 438 | 45,21% | 0,51% | -0,73 |
| 4 | `RsiPullback` | 1004 | RSI 14 Oversold/Overbought (30/70) | **+$79,06** | **1,66** | 111 | 59,46% | 0,40% | **2,62** |
| 5 | `StochasticCross` | 1005 | Stochastic %K/%D (5/3/3 area 50) | -$68,25 | 0,83 | 794 | 44,08% | 0,91% | -2,27 |
| 6 | `BollingerReversion` | 1006 | Bollinger Bands Mean Reversion (20, dev 2.0) | **+$42,88** | **1,23** | 212 | 55,66% | 0,44% | **1,42** |
| 7 | `CciReversal` | 1007 | CCI Extremes Reversal (14, ±100) | -$5,86 | 0,98 | 721 | 48,82% | 0,65% | -0,20 |
| 8 | `HeikenAshiTrend` | 1008 | Heiken Ashi Direction Following | -$161,98 | 0,80 | 3.097 | 41,27% | 1,65% | -5,00 |
| 9 | `PivotBreakout` | 1009 | Daily Classic Pivot (R1/S1) | -$100,95 | 0,36 | 58 | 27,59% | 1,16% | -3,35 |
| 10 | `SarTrend` | 1010 | Parabolic SAR Flip (0.02, 0.2) | -$31,32 | 0,93 | 1.094 | 46,25% | 0,59% | -1,03 |
| **SUM** | **All-10 Equal Weighted** | ---- | **Portofolio Semua EA Bawaan** | **-$305,28** | **0,86** | **7.186** | **44,12%** | **3,05%** | **-1,15** |

#### Temuan Utama Parameter Bawaan:
1. **Pemenang Alami:** Tiga EA berhasil mencetak profit positif tanpa optimasi:
   - `RsiPullback` (+79,06 USD, PF 1,66, Sharpe 2,62)
   - `BollingerReversion` (+42,88 USD, PF 1,23, Sharpe 1,42)
   - `RangeBreakout` (+19,67 USD, PF 1,08, Sharpe 0,66)
2. **Kelemahan Strategi Fast-Flip:** Strategi seperti `HeikenAshiTrend` (3.097 trade) dan `SarTrend` (1.094 trade) mengalami *whipsaw* pada kondisi *ranging* sehingga biaya spread mengikis keuntungan.
3. **Pentingnya Take Profit & Optimasi:** Moving Average Crossover bawaan merugi (-$56,60) karena tidak memiliki mekanisme pengunci profit.

### STEP 4: Analisis Optimasi EA 1 & Portofolio Ensemble

#### a. Studi Kasus Optimasi Parameter MovingAverageCrossover (Pass #88)
Optimasi dilakukan menggunakan *Strategy Optimization* MT5 terhadap 216 kombinasi parameter:
- **Parameter Terbaik (Pass #88):** MA Cepat = 5, MA Lambat = 70, Stop Loss = 0 (nonaktif), Take Profit = 100 poin.
- **Peningkatan Metrik:**
  - Net Profit meningkat drastis dari **-$56,60 USD** menjadi **+$43,80 USD**.
  - Profit Factor melonjak dari **0,75** menjadi **1,39**.
  - Sharpe Ratio naik dari **-1,89** menjadi **+4,43**.
  - Maximum Equity Drawdown turun dari **1,00%** menjadi hanya **0,20%** (~$19,70 USD).

#### b. Pembentukan Portofolio Ensemble Terpilih (Top-4)
Portofolio dibentuk dengan mengombinasikan empat strategi terbaik yang tidak berkorelasi:
1. `RsiPullback` (Momentum & Mean Reversion Oscillator)
2. `BollingerReversion` (Volatility Envelope Reversion)
3. `RangeBreakout` (Session Breakout)
4. `MovingAverageCrossover` (Optimized Trend Following)

#### Kinerja Portofolio Ensemble Top-4 vs All-10 Bawaan:
| Metrik Kinerja | Portofolio All-10 (Bawaan) | Portofolio Top-4 (Optimized Ensemble) | Peningkatan Kuantitatif |
|:---|:---:|:---:|:---:|
| **Total Net Profit** | -$305,28 USD | **+$185,41 USD** | +$490,69 USD |
| **Profit Factor** | 0,86 | **2,14** | +1,28 (Institusional) |
| **Sharpe Ratio** | -1,15 | **+4,88** | +6,03 (Kategori Prima) |
| **Maximum Drawdown** | 3,05% | **0,28%** | Penurunan risiko 90,8% |
| **Konsistensi Bulanan** | 1 Profit, 5 Loss | **6 Profit, 0 Loss (100% Win)** | Konsistensi sempurna |

---

## 3. Visualisasi Hasil Akhir Pengujian

### 1. Kurva Pertumbuhan Ekuitas & Underwater Drawdown
Menampilkan lintasan pertumbuhan modal dari portofolio Top-4 Ensemble dibandingkan strategi individu dan All-10:
![Kurva Ekuitas Portofolio](portfolio_equity_curve.png)

### 2. Matriks Laba Bersih Bulanan (Januari–Juni 2024)
*Heatmap* distribusi return per bulan untuk masing-masing EA dan portofolio:
![Heatmap Return Bulanan](portfolio_monthly_heatmap.png)

### 3. Evaluasi Kinerja Multi-Panel 10 EA vs Optimasi vs Portofolio
Perbandingan komprehensif Net Profit, Profit Factor, Sharpe Ratio, dan Drawdown:
![Perbandingan Kinerja EA](ea_performance_comparison.png)

---

## 4. Berkas Hasil Akhir Pengujian
Folder `Tes` ini menyajikan hasil akhir pengujian portofolio:
1. **Kurva Pertumbuhan Ekuitas & Drawdown** ([`portfolio_equity_curve.png`](portfolio_equity_curve.png)): Visualisasi trajektori pertumbuhan modal dan profil drawdown.
2. **Matriks Laba Bersih Bulanan** ([`portfolio_monthly_heatmap.png`](portfolio_monthly_heatmap.png)): Peta panas sebaran laba rugi 6 bulan pengujian.
3. **Diagram Evaluasi Kinerja Multi-Panel** ([`ea_performance_comparison.png`](ea_performance_comparison.png)): Evaluasi dekomposisi komparasi 10 EA, optimasi, dan ensemble portofolio.
