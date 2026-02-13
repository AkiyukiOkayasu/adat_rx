# PROJECT KNOWLEDGE BASE

**Generated:** 2026-02-07 16:59 JST
**Commit:** 971eee8
**Branch:** main

## OVERVIEW
SystemVerilog testbenches for the ADAT receiver pipeline and integration flow.

## WHERE TO LOOK
| Task | Location | Notes |
| --- | --- | --- |
| Integration test | tests/tb_adat_rx.sv | Uses `adat_generator` + strict compares |
| ADAT stimulus | tests/adat_generator.sv | NRZI frame generator |
| Unit tests | tests/tb_*.sv | One tb per module |

## CONVENTIONS
- Testbench file name and module name match: `tb_<module>.sv` -> `module tb_<module>`.
- DUT instances use generated names: `adat_rx_<module>` (e.g., `adat_rx_frame_parser`).
- Instance naming: DUT is `u_dut`, generator is `u_gen`.
- Reset in tests is active-low (assert `rst=0`, release `rst=1`).
- Unit tests dump VCD (`tb_<module>.vcd`); integration test dumps FST (`adat_rx.fst`).
- Use strict comparisons (`!==`) for data validation.

## ANTI-PATTERNS (THIS DIRECTORY)
- Avoid ad-hoc stimulus when `adat_generator.sv` can be reused.
