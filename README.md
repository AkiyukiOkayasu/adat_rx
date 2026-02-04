# VerylによるADAT受信

ADAT信号を受信し、PCM信号を出力するRTL。クロックはADAT信号から作る。

## プロジェクト状況

**現在のステータス**: デバッグ中 - frame_parserのビット順整合が未解決

詳細なデバッグ状況は `debug_log.md` を参照してください。

## クロック仕様

- システムクロック: 100MHz推奨
- ADATビットレート: 12.288Mbps (48kHz時)
- 1ビットあたりのクロック: 約8.14クロック (テストベンチは整数除算で8クロック)
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
# インストール
brew install surfer

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

## ドキュメント

Verylのドキュメンテーションコメントでは Wavedrom を使用できます。
`src/adat_rx.veryl` の例に倣い、以下のように `wavedrom` フェンスを使います。

```veryl
/// ```wavedrom
/// { "signal": [ {"name": "clk", "wave": "P....."} ] }
/// ```
```

生成済みHTMLドキュメントは `doc/` に配置されています。

## 参考

<https://ackspace.nl/wiki/ADAT_project>
