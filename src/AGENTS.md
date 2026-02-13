# PROJECT KNOWLEDGE BASE

**Generated:** 2026-02-07 16:59 JST
**Commit:** 971eee8
**Branch:** main

## OVERVIEW

Veryl RTL sources for the ADAT receiver pipeline and shared package definitions.

## WHERE TO LOOK

| Task | Location | Notes |
| --- | --- | --- |
| Top module | src/adat_rx.veryl | Wires all pipeline stages |
| Shared types/constants | src/adat_pkg.veryl | S/MUX mode enum + timing thresholds |
| Edge detection | src/edge_detector.veryl | Input sync + edge pulse |
| Timing tracking | src/timing_tracker.veryl | Edge timing + sync detect |
| Bit decoding | src/bit_decoder.veryl | NRZI/time-bin decode |
| Frame parsing | src/frame_parser.veryl | 30-bit nibbles -> 24-bit PCM |
| Output/rate detect | src/output_interface.veryl | Word clock, valid/locked |

## CONVENTIONS

- Import `adat_pkg::*` at file top when using shared types/constants.
- Reset input is active-high `i_rst` across modules.
- Doc comments are Japanese, identifiers are English.
- WaveDrom blocks live inside Veryl doc comments (`/// ```wavedrom`).

## ANTI-PATTERNS (THIS DIRECTORY)

- Do not edit `target/*.sv` for RTL changes; regenerate via `veryl build`.

## UNIQUE STYLES

- Module docs include detailed ADAT frame structure and timing WaveDroms.
