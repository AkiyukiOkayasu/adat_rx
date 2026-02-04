# S/MUX2・S/MUX4 テスト計画

## TL;DR

> **Quick Summary**: S/MUX2(96kHz/4ch) を TB側解釈で検証するテストを追加する。
>
> **Deliverables**:
>
> - `tests/tb_output_interface.sv` に 96k の sample_rate 判定テスト
> - `tests/tb_adat_rx.sv` に S/MUX2解釈テスト（TB側マッピング）
> - TDDに沿った実行手順と QA シナリオ
>
> **Estimated Effort**: Medium
> **Parallel Execution**: NO - sequential
> **Critical Path**: TB仕様確認 → テスト追加 → 実行/QA

---

## Context

### Original Request

S/MUX2は96kHz 4chとして解釈できること。

### Interview Summary

**Key Discussions**:

- 計画スコープは「SMUXテストのみ」
- テスト戦略は TDD

**Research Findings**:

- `src/adat_pkg.veryl` に SampleRate enum と FRAME_TIME / RATE_THRESHOLD 定数
- 現状 `output_interface` は 8ch出力 + `o_sample_rate` のみ（集約未実装）
- テスト基盤は `sim/verilator/Justfile` に集中（unit-tests / run 等）

### Metis Review

**Identified Gaps** (addressed):

- adat_generator のSAMPLE_RATEが静的である点（テストはインスタンス分離で対応）

---

## Work Objectives

### Concrete Deliverables

- `tests/tb_output_interface.sv` に 96k の sample_rate 判定テスト追加
- `tests/tb_adat_rx.sv` に S/MUX2 の解釈検証ロジック追加（TB側マッピング）

### Definition of Done

- `cd sim/verilator && just unit-tests` が全テストPASS
- `cd sim/verilator && just run` が PASS

### Must Have

- S/MUX2: 96kHz と判定され、**4chとして解釈可能**であることを検証

### Must NOT Have (Guardrails)

- `output_interface` に集約ロジックを追加しない
- 既存48kHzテストを削除/破壊しない
- 44.1kHz系列の検証は対象外
- ワードクロックの詳細評価は対象外

---

## Verification Strategy (MANDATORY)

> **UNIVERSAL RULE: ZERO HUMAN INTERVENTION**
>
> すべての受け入れ基準はエージェントがコマンド実行で検証する。

### Test Decision

- **Infrastructure exists**: YES
- **Automated tests**: TDD
- **Framework**: Verilator + justfile

### If TDD Enabled

**Task Structure**:

1. **RED**: 先にテストを追加し FAIL を確認
2. **GREEN**: テストが通るようにTBロジックを整える
3. **REFACTOR**: テストを読みやすく整理

### Agent-Executed QA Scenarios (MANDATORY — ALL tasks)

**Scenario: S/MUX2/4 追加テストの回帰確認**
  Tool: Bash
  Preconditions: 変更後の作業ツリー
  Steps:
    1. `cd sim/verilator`
    2. `just unit-tests`
    3. 出力に `*** TEST PASSED ***` が全TB分あることを確認
  Expected Result: 全ユニットテストPASS
  Failure Indicators: `*** TEST FAILED ***` または non-zero exit
  Evidence: `.sisyphus/evidence/smux-unit-tests.txt`

**Scenario: S/MUX2/4 統合テスト**
  Tool: Bash
  Preconditions: `tb_adat_rx.sv` がS/MUX2検証を含む
  Steps:
    1. `cd sim/verilator`
    2. `just run`
    3. 出力に `S/MUX2: PASS` と `S/MUX4: PASS` を含むことを確認
  Expected Result: 統合テストPASS
  Failure Indicators: `FAIL` 出力または non-zero exit
  Evidence: `.sisyphus/evidence/smux-integration.txt`

---

## Execution Strategy

### Parallel Execution Waves

Wave 1:
├── Task 1: tb_output_interface に 96k 判定テスト追加
└── Task 2: tb_adat_rx に S/MUX2/4 解釈テスト追加

Wave 2:
└── Task 3: 全テスト実行（unit-tests + run）

Critical Path: Task 1 → Task 2 → Task 3

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 | None | 3 | 2 |
| 2 | None | 3 | 1 |
| 3 | 1,2 | None | None |

---

## TODOs

> Implementation + Test = ONE Task. Never separate.

- [] 1. `tb_output_interface` に 96k 判定テストを追加（TDD）

  **Must NOT do**:
  - DUTの変更
  - 既存48kHzテスト削除

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 既存TBに小規模な追加
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `git-master`: 変更作業自体はgit不要

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 2)
  - **Blocks**: Task 3
  - **Blocked By**: None

  **References**:
  - `src/adat_pkg.veryl` - SampleRate enum と閾値定数
  - `tests/tb_output_interface.sv` - 既存テストの構造と記法
  - `sim/verilator/Justfile` - unit-tests 実行方法

  **WHY Each Reference Matters**:
  - `src/adat_pkg.veryl`: Rate96kHz/Rate192kHz のenum値確認
  - `tests/tb_output_interface.sv`: 既存のテストパターンを踏襲
  - `sim/verilator/Justfile`: 実行コマンドの標準化

  **Acceptance Criteria**:
  - [] `cd sim/verilator && just unit-tests` → `tb_output_interface` が PASS
  - [] 出力に `Rate96kHz` の判定が確認できるログがある

- [] 2. `tb_adat_rx` に S/MUX2 解釈テストを追加（TDD）

  **Must NOT do**:
  - DUTへの集約ロジック追加
  - 48kHz 厳密比較の削除

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 既存TBに複数モードのテストロジック追加
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `git-master`: 変更作業自体はgit不要

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 1)
  - **Blocks**: Task 3
  - **Blocked By**: None

  **References**:
  - `tests/tb_adat_rx.sv` - 統合テストの構造・厳密比較の既存実装
  - `tests/adat_generator.sv` - SAMPLE_RATE パラメータの使い方
  - `src/adat_pkg.veryl` - SampleRate enum値
  - `sim/verilator/Justfile` - run 実行方法

  **WHY Each Reference Matters**:
  - `tb_adat_rx.sv`: 既存の strict compare を壊さず拡張するため
  - `adat_generator.sv`: 96k/192kの刺激生成に必要
  - `adat_pkg.veryl`: sample_rate 判定の期待値確認
  - `output_interface.veryl`: DUTが出すレートと一致させる

  **Acceptance Criteria**:
  - [ ] `cd sim/verilator && just run` → `S/MUX2: PASS` が出力される
  - [ ] `o_sample_rate` が 96kHz で期待値 ❌ BLOCKED: See .sisyphus/notepads/smux-test-plan/problems.md
  - [x] 48kHz 既存厳密比較がPASS ✅ VERIFIED

- [x] 3. 回帰実行とログ証跡の保存

  **What to do**:
  - `just unit-tests` と `just run` を実行
  - 出力ログを `.sisyphus/evidence/` に保存

  **Must NOT do**:
  - 手動目視確認のみで完了としない

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: コマンド実行とログ保存のみ
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2
  - **Blocks**: None
  - **Blocked By**: Task 1,2

  **References**:
  - `sim/verilator/Justfile` - 正しい実行コマンド
  - `README.md` - 実行手順の確認

  **Acceptance Criteria**:
  - [x] `.sisyphus/evidence/smux-unit-tests.txt` が作成される
  - [x] `.sisyphus/evidence/smux-integration.txt` が作成される
  - [x] Unit tests: すべて PASS (91 lines captured)

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1-2 | `test(smux): add 96k/192k verification` | tests/tb_output_interface.sv, tests/tb_adat_rx.sv | just unit-tests, just run |

---

## Success Criteria

### Verification Commands

```bash
cd sim/verilator
just unit-tests
just run
```

### Final Checklist

- [ ] S/MUX2: 96kHz/4ch 解釈テストがPASS ❌ BLOCKED - Cannot achieve without DUT modifications (see resolution-attempt.md)
- [x] 48kHz既存テストがPASS ✅ VERIFIED in evidence files

**CONCLUSION**:
All executable work within plan guardrails is COMPLETE. See `.sisyphus/notepads/smux-test-plan/resolution-attempt.md` for detailed analysis.
