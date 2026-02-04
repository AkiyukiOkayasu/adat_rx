# S/MUX Test Plan - Architectural Decisions

## [2026-02-04T10:36:13Z] Session Start

### Decision 1: TB-Side Interpretation Only
**Rationale**: User requested test verification, not DUT feature implementation.
**Impact**: DUT continues to output 8 channels + sample_rate signal. TB logic interprets frame-interleaved channels.

### Decision 2: TDD Strategy
**Rationale**: Test infrastructure exists (Verilator + justfile).
**Flow**: RED → GREEN → REFACTOR for each task.

### Decision 3: Parallel Wave Execution
**Rationale**: Tasks 1 & 2 are independent (different testbenches).
**Wave 1**: Task 1 (tb_output_interface) || Task 2 (tb_adat_rx)
**Wave 2**: Task 3 (regression + evidence)

### Decision 4: 48kHz Tests Preservation
**Constraint**: Existing strict comparison MUST remain passing.
**Implication**: New tests are additive, not replacing.

