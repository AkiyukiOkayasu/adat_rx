# CLAUDE.md

## Project Overview

ADAT transceiver RTL implementation in Veryl, simulated with Verilator.

- **RX**: ADAT optical input → 8ch 24bit PCM output (automatic clock recovery)
- **TX**: 8ch 24bit PCM input → ADAT optical output

## Commands

```bash
veryl fmt           # Format code
veryl build         # Generate SystemVerilog from Veryl
veryl test          # Run tests
veryl test --wave   # Run tests with waveform output (FST)
veryl clean         # Clean generated files
```

## Architecture

### RX Pipeline

```
ADAT input → timing_tracker → bit_decoder → frame_parser → output_interface → PCM output
              (edge detection)  (NRZI/4B5B)  (30bit→24bit)  (word clock gen)
```

### TX Pipeline

```
PCM input → tx_frame_builder → tx_bit_serializer → tx_nrzi_encoder → ADAT output
            (256bit frame build) (MSB-first serial)   (NRZI encode)
```

## Coding Conventions

- Comments in Japanese
- Port naming: inputs `i_`, outputs `o_`, active-low `_n` suffix
- Reset active-high `i_rst` across all modules

## Do Not Edit

- `target/` — Generated SystemVerilog
- `dependencies/std/` — Vendored standard library
- `doc/` — Generated documentation
