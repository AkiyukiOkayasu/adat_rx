# VerylによるADAT受信

ADAT信号を受信し、PCM信号を出力するRTL。クロックはADAT信号から作る。

## プロジェクト状況

**現在のステータス**: ✅ 完成 - 全テストパス

- 8チャンネル24bit PCMデータの受信・デコード完了
- 4bitユーザーデータの抽出完了
- 厳密比較テストパス（`just run`）
- 全ユニットテストパス（`just unit-tests`）

## クロック仕様

- システムクロック: 100MHz推奨
- ADATビットレート:
    - 48kHz系: 12.288Mbps
    - 44.1kHz系: 11.2896Mbps
- 1ビットあたりのクロック:
    - 48kHz時: 約8.14クロック (100MHz / 12.288MHz)
    - 44.1kHz時: 約8.86クロック (100MHz / 11.2896MHz)
- 1フレーム: 256bit

## シミュレーション

トレース無し:

```sh
cd sim/verilator
just run
```

トレース付き:

```sh
cd sim/verilator
just run-trace
```

## ユニットテスト

```sh
cd sim/verilator
just unit-tests
```

トレース付き:

```sh
cd sim/verilator
just unit-tests-trace
```

## SV Lint

```sh
svls
```

## 波形デバッグ

GTKWaveはmacOSで問題があるため、**Surfer**を使用します。

```sh
# シミュレーション実行（FST出力付き）
cd sim/verilator
just run-trace

# Surferで波形表示
surfer /Users/akiyuki/Documents/AkiyukiProjects/adat_rx/sim/verilator/adat_rx.fst
```

またはシミュレーション後に自動でSurferを起動:

```sh
cd sim/verilator
just wave
```

## 参考

<https://ackspace.nl/wiki/ADAT_project>
