# PROJECT KNOWLEDGE BASE

**Generated:** 2026-02-07 16:59 JST
**Commit:** 971eee8
**Branch:** main

## OVERVIEW

Verilator simulation harness, Justfile automation, and C++ sim_main entrypoints.

## WHERE TO LOOK

| Task | Location | Notes |
| --- | --- | --- |
| Build/run targets | sim/verilator/Justfile | `just run`, `just unit-tests` |
| Top sim entry | sim/verilator/sim_main.cpp | Uses `adat_rx.fst` when tracing |
| Unit sim entries | sim/verilator/sim_main_*.cpp | One per `tb_<module>` |
| Build artifacts | sim/verilator/obj_dir/ | Verilator-generated C++ + executables |

## CONVENTIONS

- Justfile is the canonical runner; run from this directory.
- Trace builds use `--trace-fst`; output files live in `sim/verilator/*.fst`.
- `sim_main_*.cpp` naming matches `tb_<module>` and opens `tb_<module>.fst`.

## ANTI-PATTERNS (THIS DIRECTORY)

- Do not commit `obj_dir/` or trace outputs (`*.fst`, `sim_output.log`).
- Do not assume GTKWave works on macOS; use Surfer.

## UNIQUE STYLES

- `wave` target launches Surfer with an absolute path; update for your machine.
