# VerylによるADAT受信

ADAT信号を受信し、PCM信号を出力するRTL。クロックはADAT信号から作る。

## プロジェクト状況

**現在のステータス**: デバッグ中 - レシーバーがロックできない問題を調査中

詳細なデバッグ状況は `debug_log.md` を参照してください。

## クロック仕様

- システムクロック: 100MHz推奨
- ADATビットレート: 12.288Mbps (48kHz時)
- 1ビットあたりのクロック: 約8.14クロック (テストベンチは整数除算で8クロック)
- 1フレーム: 256bit

## シミュレーション

```
cd sim/verilator
just run
```

## フォーマット

```
cd sim/verilator
just fmt
```

`just build`/`just run` は自動で `veryl fmt` を実行します。

## SV Lint

```
svls
```

## 波形デバッグ

GTKWaveはmacOSで問題があるため、**Surfer**を使用します。

```bash
# インストール
brew install surfer

# シミュレーション実行（VCD出力付き）
cd sim/verilator
just run-trace

# Surferで波形表示
surfer adat_rx.vcd
```

またはシミュレーション後に自動でSurferを起動:
```bash
cd sim/verilator
just wave
```

## ドキュメント

Verylのドキュメンテーションコメントでは Wavedrom を使用できます。
`src/adat_rx.veryl` の例に倣い、以下のように `wavedrom` フェンスを使います。

```
/// ```wavedrom
/// { "signal": [ {"name": "clk", "wave": "P....."} ] }
/// ```
```

生成済みHTMLドキュメントは `doc/` に配置されています。

## 参考

<https://ackspace.nl/wiki/ADAT_project>
