# S/MUX Test Plan - Issues & Gotchas

## [2026-02-04T10:36:13Z] Session Start

### Known Issues from Previous Work
1. **Testbench Timing**: fork/join_any can terminate prematurely → use fork/join_none + main wait
2. **User Data Bit Order**: Must extract as `{shift[0], shift[1], shift[2], shift[3]}` not reversed
3. **SV Lint Warnings**: 11 cosmetic warnings exist (documented in debug_log.md)

### Potential Gotchas for S/MUX Testing
- **Frame Timing**: adat_generator CLOCKS_PER_BIT must scale correctly:
  - 48kHz: 100M/(48k*256) ≈ 8 clocks
  - 96kHz: 100M/(96k*256) ≈ 4 clocks
  - 192kHz: 100M/(192k*256) ≈ 2 clocks
- **Lock Time**: Higher sample rates may require different lock detection thresholds
- **Data Collection**: TB must accumulate multiple frames before verifying interleaving


## [2026-02-04T11:05:00Z] Task 2 Blocker Documented

### Blocker Summary
Task 2 (S/MUX2/4 integration tests) is BLOCKED by timing_tracker architectural limitation.

### What Works
✅ Test infrastructure complete:
- Multiple adat_generator instances (48/96/192 kHz)
- Input multiplexer functional
- S/MUX2/4 frame interleaving logic implemented
- Debug instrumentation comprehensive

### What's Blocked
❌ Sample rate detection during transitions:
- timing_tracker.frame_time stuck at initialization value (2083)
- Sync edge detection fails at 96kHz/192kHz after generator switch
- max_time adaptive mechanism incompatible with sample rate transitions

### Root Cause
timing_tracker.veryl lines 109-130: sync detection threshold calculation
- threshold = 0.75 * max_time
- With reset: max_time=20 → threshold=15, but 96kHz sync=40 clocks → cur_time[11:2]=10 < 15 → fails
- Without reset: max_time overshoots → incorrect frame_time measurements

### Attempted Solutions
1. ✅ DUT reset before generator switch → sync detection still fails (max_time init too high)
2. ✅ Extended stabilization periods → measurements remain incorrect
3. ⚠️ DUT modification → VIOLATES plan guardrails (line 61: "DUT変更は禁止")

### Impact on Acceptance Criteria
Task 2 has 5 acceptance criteria (lines 218-224):
- ❌ `o_sample_rate` が 96kHz / 192kHz で期待値 → BLOCKED
- ❌ 48kHz既存テストがPASS → Currently passes, but S/MUX tests fail/hang
- ⚠️ S/MUX2: 2フレームインターリーブ検証 → Logic ready, can't verify due to sample_rate issue
- ⚠️ S/MUX4: 4フレームインターリーブ検証 → Logic ready, can't verify due to sample_rate issue
- ❌ 出力に "S/MUX2: PASS" と "S/MUX4: PASS" → BLOCKED

### Decision: Move to Task 3
Per boulder continuation rules: "If blocked, document the blocker and move to the next task"
- Task 2 infrastructure is complete but cannot pass acceptance criteria without DUT changes
- Documented in problems.md with full analysis
- Proceeding to Task 3 (evidence collection) with current state

