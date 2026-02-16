# Agent Guidelines

<!-- Do not restructure or delete sections. Update individual values in-place when they change. -->

## Core Principles

- **Do NOT maintain backward compatibility** unless explicitly requested. Break things boldly.
- **Keep this file under 20-30 lines of instructions.** Every line competes for the agent's limited context budget (~150-200 total).

## OVERVIEW

Veryl RTL ADAT receiver. Decodes TOSLINK ADAT into 8-channel 24-bit PCM with S/MUX detection.

## WHERE TO LOOK

| Task | Location | Notes |
| --- | --- | --- |
| Top module wiring | src/adat_rx.veryl | Instantiates all pipeline modules |
| Shared types/constants | src/adat_pkg.veryl | SampleRate enum + frame timing constants |
| S/MUX + output | src/output_interface.veryl | Word clock, valid/locked, S/MUX active detection (UserBit only). Distinguishing S/MUX2 vs S/MUX4 from UserBit is impossible |
| Stdlib SV | dependencies/std/** | Generated std modules (do not edit) |

## CONVENTIONS

- Doc comments and implementation comments are Japanese; identifiers/ports are English.
- Ports: inputs use `i_`, outputs use `o_`, active-low uses `_n`.
- WaveDrom is embedded in Veryl doc comments with `/// ```wavedrom` blocks.
- Reset behavior in design is active-high (`i_rst`), but SV testbenches drive active-low reset signals where noted.
- Follow the existing patterns in the codebase
- Prefer explicit over clever
- Delete dead code immediately

## ANTI-PATTERNS (THIS PROJECT)

- Do not edit generated outputs under `target/` or `doc/` by hand.
- Do not edit vendored stdlib under `dependencies/std/` directly; regenerate upstream.
- Do not use GTKWave on macOS; use Surfer for FST traces.

## COMMANDS

```bash
# Format/build
veryl fmt
veryl build
veryl clean

# Simulation + tests
veryl test
veryl test --wave
surfer src/tb_adat_rx.fst
```

## NOTES

- `Veryl.toml` pins sources to `src/` and outputs SV to `target/`.
