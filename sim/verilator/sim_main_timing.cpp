#include "Vtb_timing_tracker.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtb_timing_tracker* top = new Vtb_timing_tracker;
    while (!Verilated::gotFinish()) {
        top->eval();
        Verilated::timeInc(1);
    }
    delete top;
    return 0;
}
