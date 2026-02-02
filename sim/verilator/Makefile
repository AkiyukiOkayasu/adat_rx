# ADAT Receiver Verilator Makefile
#
# 使用方法:
#   make        - ビルドと実行
#   make build  - ビルドのみ
#   make run    - 実行
#   make wave   - 波形表示 (GTKWave)
#   make clean  - クリーンアップ

PROJ_ROOT := ../..
TARGET := target
SRC_DIR := $(PROJ_ROOT)/src
TEST_DIR := $(PROJ_ROOT)/tests

# Verilator設定
VERILATOR := verilator
VERILATOR_FLAGS := --cc --exe --build -j 0
VERILATOR_FLAGS += -Wall
VERILATOR_FLAGS += -Wno-UNUSEDSIGNAL
VERILATOR_FLAGS += -Wno-UNUSEDPARAM
VERILATOR_FLAGS += -Wno-TIMESCALEMOD
VERILATOR_FLAGS += -Wno-WIDTHEXPAND
VERILATOR_FLAGS += -Wno-WIDTHTRUNC
VERILATOR_FLAGS += --timing

# ソースファイル
VERYL_SV := $(wildcard $(PROJ_ROOT)/target/*.sv)
TB_SV := $(TEST_DIR)/tb_adat_rx.sv $(TEST_DIR)/adat_generator.sv

# 出力ディレクトリ
OBJ_DIR := obj_dir

.PHONY: all build run wave clean veryl

all: veryl build run

# Verylビルド
veryl:
	cd $(PROJ_ROOT) && veryl build

# Verilatorビルド
build: veryl
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module tb_adat_rx \
		-I$(PROJ_ROOT)/target \
		-Wno-DECLFILENAME \
		$(PROJ_ROOT)/target/adat_pkg.sv \
		$(TB_SV) \
		$(PROJ_ROOT)/target/edge_detector.sv \
		$(PROJ_ROOT)/target/timing_tracker.sv \
		$(PROJ_ROOT)/target/bit_decoder.sv \
		$(PROJ_ROOT)/target/frame_parser.sv \
		$(PROJ_ROOT)/target/output_interface.sv \
		$(PROJ_ROOT)/target/adat_rx.sv \
		sim_main.cpp

# 実行
run: build
	./$(OBJ_DIR)/Vtb_adat_rx

# 波形表示
wave: run
	gtkwave adat_rx.vcd &

# クリーンアップ
clean:
	rm -rf $(OBJ_DIR)
	rm -f *.vcd
	rm -f $(PROJ_ROOT)/target/*.sv
