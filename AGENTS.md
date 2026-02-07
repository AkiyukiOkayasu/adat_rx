# PROJECT KNOWLEDGE BASE

**Generated:** 2026-02-07 16:59 JST
**Commit:** 971eee8
**Branch:** main

## OVERVIEW
Veryl RTL ADAT receiver. Decodes TOSLINK ADAT into 8-channel 24-bit PCM with sample-rate detection (48/96/192kHz).

## STRUCTURE
```
adat_rx/
├── src/                  # Veryl RTL sources (top + submodules)
├── tests/                # SystemVerilog testbenches + generator
├── sim/verilator/        # Verilator harness + Justfile
├── target/               # Veryl-generated SystemVerilog output
├── dependencies/std/     # Vendored/generate stdlib SV
├── docs/                 # Project notes (S/MUX status)
└── doc/                  # Generated Veryl HTML docs
```

## WHERE TO LOOK
| Task | Location | Notes |
| --- | --- | --- |
| Top module wiring | src/adat_rx.veryl | Instantiates all pipeline modules |
| Shared types/constants | src/adat_pkg.veryl | SampleRate enum + frame timing constants |
| Sample-rate + output | src/output_interface.veryl | Word clock, valid/locked, rate detection |
| Integration tests | tests/tb_adat_rx.sv | Uses adat_generator + strict comparisons |
| Unit tests | tests/tb_*.sv | One tb per module |
| Simulation commands | sim/verilator/Justfile | Just targets for build/run/tests |
| S/MUX status notes | docs/smux_status.md | Design notes + test strategy |
| Stdlib SV | dependencies/std/** | Generated std modules (do not edit) |

## CONVENTIONS
- Doc comments and implementation comments are Japanese; identifiers/ports are English.
- Ports: inputs use `i_`, outputs use `o_`, active-low uses `_n`.
- WaveDrom is embedded in Veryl doc comments with `/// ```wavedrom` blocks.
- Reset behavior in design is active-high (`i_rst`), but SV testbenches drive active-low reset signals where noted.

## ANTI-PATTERNS (THIS PROJECT)
- Do not edit generated outputs under `target/` or `doc/` by hand.
- Do not edit vendored stdlib under `dependencies/std/` directly; regenerate upstream.
- Do not rely on Verilator `obj_dir/` artifacts being committed.
- Do not use GTKWave on macOS; use Surfer for FST traces.

## UNIQUE STYLES
- Simulation is driven from `sim/verilator/Justfile` (not repo root).
- Integration test uses FST traces (`adat_rx.fst`); unit tests emit VCD by default.
 - `Hardware/` is not useful for this project; avoid reading it to save context.

## COMMANDS
```bash
# Format/build
veryl fmt
veryl build
veryl clean

# Lint
svls
svls src/adat_rx.veryl

# Simulation + tests
cd sim/verilator
just run
just run-trace
just wave
just unit-tests
just unit-tests-trace
```

## NOTES
- `Veryl.toml` pins sources to `src/` and outputs SV to `target/`.
- `sim/verilator/Justfile` hard-codes an absolute path for `surfer`; adjust if needed.
