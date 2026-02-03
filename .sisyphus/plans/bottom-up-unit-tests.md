# ADAT Receiver ボトムアップ単体テスト計画

## TL;DR

> **Quick Summary**: ADATレシーバーの「ロックできない」問題をボトムアップで切り分けるため、5つのモジュール単体テストを作成し、順次実行してバグを特定・修正する。
> 
> **Deliverables**:
> - `tests/tb_edge_detector.sv` - エッジ検出単体テスト
> - `tests/tb_timing_tracker.sv` - タイミング追跡単体テスト
> - `tests/tb_bit_decoder.sv` - ビットデコーダ単体テスト
> - `tests/tb_frame_parser.sv` - フレームパーサ単体テスト
> - `tests/tb_output_interface.sv` - 出力インターフェース単体テスト
> - `sim/verilator/Justfile` 更新 - 各モジュール用ビルド/実行タスク追加
> - バグ修正（発見次第）
> 
> **Estimated Effort**: Medium (各テスト作成30分 + デバッグ時間)
> **Parallel Execution**: NO - 順次実行（上流モジュールから）
> **Critical Path**: Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 6 → Task 7

---

## Context

### Original Request
ユーザー: 「デバッグを続けて。モジュールごとの単体テストを実行してボトムアップで進めるのが望ましい。」

### Current Problem
- **症状**: レシーバーがロックしない（`locked=0`）
- **debug_log.md記載**:
  - `synced=0` - edge_detectorの同期済み信号が出力されていない
  - `bits_valid=0` - bit_decoderがデータを出力していない
  - `bit_counter=147` - frame_parserが256まで到達しない
  - `frame_time=2048` (期待値: ~2083)
  - `shift_reg=3fffffff` - 異常なパターン

### Interview Summary
**Key Decisions**:
- テストベンチは `tests/` に `tb_*.sv` を追加
- `sim/verilator/Justfile` に各モジュール用タスクを追加
- `sim_main.cpp` は共通のまま（Verilatorが `--top-module` で切り替え）
- 刺激は最小の手動パターン（クロック+リセット+直接駆動）
- `adat_generator.sv` は参照のみ、再利用しない
- 実行順序: Wave1→Wave5 → 統合

**Research Findings**:
- モジュール間の依存関係を確認済み
- 既存テストベンチのパターン（100MHzクロック、アクティブローリセット）を踏襲

---

## Work Objectives

### Core Objective
ADATレシーバーの「ロックできない」問題を、ボトムアップ単体テストで切り分け・特定・修正する。

### Concrete Deliverables
1. 5つの単体テストベンチファイル（tests/tb_*.sv）
2. Justfileへのビルド/実行タスク追加
3. 各モジュールの動作確認（PASS/FAIL）
4. 発見されたバグの修正
5. 最終的に統合テストでlocked=1 & 8ch一致

### Definition of Done
- [ ] 全5単体テストがPASS
- [ ] `cd sim/verilator && just run` で統合テストがPASS
- [ ] `locked=1` かつ全8チャンネルのデータがテストデータと一致

### Must Have
- 各モジュールの基本動作を検証するテストケース
- エッジケース（リセット直後、境界値）の検証
- VCDトレース出力対応（デバッグ用）

### Must NOT Have (Guardrails)
- 新機能の追加（デバッグのみ）
- adat_generator.svの修正（参照のみ）
- 複雑なランダムテスト生成（最小限の手動パターンで十分）
- 他のファイル構成変更（sim_main.cppは共通のまま）

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: YES (Verilator + Justfile)
- **User wants tests**: Manual verification (単体テストはPASS/FAILを`$display`で出力)
- **Framework**: Verilator + SystemVerilog testbench

### Automated Verification

各テストベンチは以下のパターンで検証：

```bash
# 各モジュールの実行
cd sim/verilator
just run-{module}  # 例: just run-edge

# 期待出力
# *** TEST PASSED *** または *** TEST FAILED ***
```

**Evidence Requirements:**
- 各テスト実行時のコンソール出力
- 失敗時はVCDトレースで詳細確認

---

## Execution Strategy

### Sequential Execution (Bottom-Up)

```
Task 1: Justfile更新（全テスト用タスク追加）
    ↓
Task 2: edge_detector単体テスト作成・実行
    ↓
Task 3: timing_tracker単体テスト作成・実行
    ↓
Task 4: bit_decoder単体テスト作成・実行
    ↓
Task 5: frame_parser単体テスト作成・実行
    ↓
Task 6: output_interface単体テスト作成・実行
    ↓
Task 7: 統合テスト再実行・確認
```

### Dependency Matrix

| Task | Depends On | Blocks | Rationale |
|------|------------|--------|-----------|
| 1 | None | 2-7 | Justfile更新が先 |
| 2 | 1 | 3 | edge_detectorが最上流 |
| 3 | 2 | 4 | timing_trackerはedge出力を使用 |
| 4 | 3 | 5 | bit_decoderはtiming出力を使用 |
| 5 | 4 | 6 | frame_parserはbit_decoder出力を使用 |
| 6 | 5 | 7 | output_interfaceはframe_parser出力を使用 |
| 7 | 6 | None | 最終統合確認 |

---

## TODOs

- [ ] 1. Justfileに各モジュール用ビルド/実行タスクを追加

  **What to do**:
  - `sim/verilator/Justfile` を編集
  - 以下のタスクを追加:
    - `build-edge`, `run-edge`, `run-edge-trace`
    - `build-timing`, `run-timing`, `run-timing-trace`
    - `build-bit`, `run-bit`, `run-bit-trace`
    - `build-frame`, `run-frame`, `run-frame-trace`
    - `build-output`, `run-output`, `run-output-trace`
  - 各タスクは適切なトップモジュール名（`tb_edge_detector`等）を指定

  **Must NOT do**:
  - sim_main.cppの変更
  - 既存のrun/buildタスクの削除

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 単純なファイル編集、15分以内で完了
  - **Skills**: なし
    - Reason: 汎用的なファイル編集のみ

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (first task)
  - **Blocks**: Task 2, 3, 4, 5, 6, 7
  - **Blocked By**: None

  **References**:
  - `sim/verilator/Justfile` - 既存のbuild/runタスクパターンを踏襲
  - `sim/verilator/sim_main.cpp` - Verilatorトップモジュール構造の参照

  **Acceptance Criteria**:
  ```bash
  cd sim/verilator
  just --list | grep -E "build-edge|run-edge"
  # Assert: 両方が表示される
  just --list | grep -E "build-timing|run-timing"
  # Assert: 両方が表示される
  # ... (全5モジュール分)
  ```

  **Commit**: YES
  - Message: `chore(sim): add unit test build/run tasks to Justfile`
  - Files: `sim/verilator/Justfile`
  - Pre-commit: `just --list` (タスク一覧表示成功)

---

- [ ] 2. edge_detector単体テスト作成・実行

  **What to do**:
  - `tests/tb_edge_detector.sv` を作成
  - テストケース:
    1. リセット直後: `o_edge=0`, `o_synced=0`
    2. `i_adat` を0→1に遷移: 2クロック後に `o_synced=1`, `o_edge=1`パルス
    3. `i_adat` を1→0に遷移: `o_synced=0`, `o_edge=1`パルス
    4. `i_adat` 変化なし: `o_edge=0` を維持
  - VCDダンプ対応

  **Must NOT do**:
  - adat_generator.svの使用
  - 複雑なパターン生成

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 小規模なテストベンチ作成、30分以内
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 1)
  - **Blocks**: Task 3
  - **Blocked By**: Task 1

  **References**:
  - `tests/tb_adat_rx.sv:33-36` - クロック生成パターン（100MHz）
  - `tests/tb_adat_rx.sv:103-124` - リセットハンドリング（アクティブロー→ハイ）
  - `src/edge_detector.veryl:17-45` - モジュールインターフェースと動作仕様
  - `target/edge_detector.sv` - 生成されたSystemVerilogコード

  **Acceptance Criteria**:
  ```bash
  cd sim/verilator
  just run-edge
  # Assert: 出力に "*** TEST PASSED ***" が含まれる
  # Assert: 出力に "Edge detected on rising" と "Edge detected on falling" が含まれる
  ```

  **Commit**: YES
  - Message: `test(edge_detector): add unit testbench`
  - Files: `tests/tb_edge_detector.sv`
  - Pre-commit: `just run-edge` (PASS)

---

- [ ] 3. timing_tracker単体テスト作成・実行

  **What to do**:
  - `tests/tb_timing_tracker.sv` を作成
  - テストケース:
    1. リセット直後: 初期値確認（`max_time=20`, `frame_time=2083`）
    2. 短いエッジ間隔（8クロック）を入力: `o_sync_detect=1`（データ期間）
    3. 長いエッジ間隔（80クロック）を入力: `o_sync_detect=0`（同期期間）
    4. `o_edge_time` が正しくカウントされることを確認
    5. `o_frame_time` がsync_mask立ち上がりでキャプチャされることを確認
  - VCDダンプ対応

  **Must NOT do**:
  - adat_generator.svの使用
  - 実際のADATフレーム全体の生成

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 小規模なテストベンチ作成
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 2)
  - **Blocks**: Task 4
  - **Blocked By**: Task 2

  **References**:
  - `tests/tb_adat_rx.sv:33-36` - クロック生成パターン
  - `src/timing_tracker.veryl:19-118` - モジュール仕様、閾値計算ロジック
  - `src/timing_tracker.veryl:53` - threshold = (max_time >> 1) + (max_time >> 2)
  - `src/timing_tracker.veryl:70` - max_time初期値 = 20
  - `debug_log.md:66-90` - タイミング計算の理論値

  **Acceptance Criteria**:
  ```bash
  cd sim/verilator
  just run-timing
  # Assert: 出力に "*** TEST PASSED ***" が含まれる
  # Assert: "sync_detect=1 for short interval" メッセージ
  # Assert: "sync_detect=0 for long interval" メッセージ
  ```

  **Commit**: YES
  - Message: `test(timing_tracker): add unit testbench`
  - Files: `tests/tb_timing_tracker.sv`
  - Pre-commit: `just run-timing` (PASS)

---

- [ ] 4. bit_decoder単体テスト作成・実行

  **What to do**:
  - `tests/tb_bit_decoder.sv` を作成
  - テストケース:
    1. リセット直後: `o_valid=0`, `o_bits=0`
    2. 1ビット間隔（~8クロック）でエッジ入力: `o_bit_count=1`, `o_bits=00001`
    3. 2ビット間隔（~16クロック）でエッジ入力: `o_bit_count=2`, `o_bits=00011`
    4. 5ビット間隔（~40クロック）でエッジ入力: `o_bit_count=5`, `o_bits=11111`
    5. `i_sync_mask=0` 時: `o_valid=0`（同期期間中は出力なし）
  - `i_frame_time=2048` を固定入力として使用

  **Must NOT do**:
  - 複雑なNRZIパターン生成
  - frame_time動的変更

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 小規模なテストベンチ作成
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 3)
  - **Blocks**: Task 5
  - **Blocked By**: Task 3

  **References**:
  - `src/bit_decoder.veryl:25-107` - モジュール仕様、時間ビン計算
  - `src/bit_decoder.veryl:54` - bit_time = frame_time[11:4]（256で割る）
  - `src/bit_decoder.veryl:70-73` - 閾値計算（t1=1.5, t2=2.5, t3=3.5, t4=4.5）
  - `debug_log.md` - bits_valid=0の問題

  **Acceptance Criteria**:
  ```bash
  cd sim/verilator
  just run-bit
  # Assert: 出力に "*** TEST PASSED ***" が含まれる
  # Assert: "1-bit decode OK" メッセージ
  # Assert: "5-bit decode OK" メッセージ
  ```

  **Commit**: YES
  - Message: `test(bit_decoder): add unit testbench`
  - Files: `tests/tb_bit_decoder.sv`
  - Pre-commit: `just run-bit` (PASS)

---

- [ ] 5. frame_parser単体テスト作成・実行

  **What to do**:
  - `tests/tb_frame_parser.sv` を作成
  - テストケース:
    1. リセット直後: `o_data_valid=0`, `bit_counter=0`
    2. 既知のビットシーケンスを入力し、ユーザーデータ（bit 15）で `o_user` を確認
    3. チャンネル0データ（bit 45）で `o_data_valid=1`, `o_channel=0` を確認
    4. 30bit→24bit変換が正しいことを確認
    5. `i_sync=0` でカウンタリセットを確認
  - 手動でビットシーケンスを構築（シフトレジスタへの入力パターン）

  **Must NOT do**:
  - adat_generator.svの使用
  - 全8チャンネルの網羅的テスト（代表的なケースのみ）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 小規模なテストベンチ作成
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 4)
  - **Blocks**: Task 6
  - **Blocked By**: Task 4

  **References**:
  - `src/frame_parser.veryl:34-157` - モジュール仕様、ビット位置定義
  - `src/frame_parser.veryl:100-148` - case文によるビット位置トリガー
  - `src/frame_parser.veryl:110` - 30bit→24bit変換式
  - `debug_log.md:32` - bit_counter=147の問題

  **Acceptance Criteria**:
  ```bash
  cd sim/verilator
  just run-frame
  # Assert: 出力に "*** TEST PASSED ***" が含まれる
  # Assert: "User data extracted" メッセージ
  # Assert: "Channel 0 data valid" メッセージ
  ```

  **Commit**: YES
  - Message: `test(frame_parser): add unit testbench`
  - Files: `tests/tb_frame_parser.sv`
  - Pre-commit: `just run-frame` (PASS)

---

- [ ] 6. output_interface単体テスト作成・実行

  **What to do**:
  - `tests/tb_output_interface.sv` を作成
  - テストケース:
    1. リセット直後: `o_locked=0`, `o_valid=0`
    2. `i_data_valid=1` でチャンネルデータを順次入力
    3. チャンネル7入力後に `o_valid=1` を確認
    4. 5フレーム分のデータ入力後に `o_locked=1` を確認
    5. `o_word_clk` がフレーム時間の約50%デューティで出力されることを確認
    6. サンプルレート検出（frame_time=2048で48kHz）を確認

  **Must NOT do**:
  - S/MUX2/4のテスト（48kHzのみ）
  - 複雑なタイミング検証

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 小規模なテストベンチ作成
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 5)
  - **Blocks**: Task 7
  - **Blocked By**: Task 5

  **References**:
  - `src/output_interface.veryl:22-145` - モジュール仕様
  - `src/output_interface.veryl:91-104` - ロック検出ロジック（frame_cnt >= 4でlocked）
  - `src/output_interface.veryl:125-143` - チャンネルデータ格納ロジック
  - `src/adat_pkg.veryl:30-38` - サンプルレート閾値定義

  **Acceptance Criteria**:
  ```bash
  cd sim/verilator
  just run-output
  # Assert: 出力に "*** TEST PASSED ***" が含まれる
  # Assert: "Locked after 5 frames" メッセージ
  # Assert: "Valid pulse on channel 7" メッセージ
  ```

  **Commit**: YES
  - Message: `test(output_interface): add unit testbench`
  - Files: `tests/tb_output_interface.sv`
  - Pre-commit: `just run-output` (PASS)

---

- [ ] 7. 統合テスト再実行・最終確認

  **What to do**:
  - 単体テストで発見・修正されたバグを確認
  - 統合テスト `just run` を実行
  - `locked=1` かつ全8チャンネルデータ一致を確認
  - 失敗時はVCDトレースで追加デバッグ

  **Must NOT do**:
  - 新機能追加
  - テストデータの変更

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 既存テストの実行と確認のみ
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (final)
  - **Blocks**: None
  - **Blocked By**: Task 6

  **References**:
  - `tests/tb_adat_rx.sv` - 統合テストベンチ
  - `tests/adat_generator.sv` - 刺激生成
  - `debug_log.md` - 現在の問題記録

  **Acceptance Criteria**:
  ```bash
  cd sim/verilator
  just run
  # Assert: 出力に "*** TEST PASSED ***" が含まれる
  # Assert: "PASS: Receiver locked" が含まれる
  # Assert: 全8チャンネルで "PASS - [hex値]" が表示される
  ```

  **Commit**: YES (if bug fixes were made)
  - Message: `fix(adat_rx): resolve receiver lock issue via bottom-up debugging`
  - Files: 修正された.verylファイル
  - Pre-commit: `just run` (PASS)

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `chore(sim): add unit test build/run tasks to Justfile` | sim/verilator/Justfile | `just --list` |
| 2 | `test(edge_detector): add unit testbench` | tests/tb_edge_detector.sv | `just run-edge` |
| 3 | `test(timing_tracker): add unit testbench` | tests/tb_timing_tracker.sv | `just run-timing` |
| 4 | `test(bit_decoder): add unit testbench` | tests/tb_bit_decoder.sv | `just run-bit` |
| 5 | `test(frame_parser): add unit testbench` | tests/tb_frame_parser.sv | `just run-frame` |
| 6 | `test(output_interface): add unit testbench` | tests/tb_output_interface.sv | `just run-output` |
| 7 | `fix(adat_rx): resolve receiver lock issue` | 修正ファイル | `just run` |

---

## Success Criteria

### Verification Commands
```bash
cd sim/verilator

# 各単体テスト
just run-edge     # Expected: *** TEST PASSED ***
just run-timing   # Expected: *** TEST PASSED ***
just run-bit      # Expected: *** TEST PASSED ***
just run-frame    # Expected: *** TEST PASSED ***
just run-output   # Expected: *** TEST PASSED ***

# 統合テスト
just run          # Expected: *** TEST PASSED ***, locked=1, 8ch match
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] All 5 unit tests pass
- [ ] Integration test passes with locked=1 and 8-channel data match
