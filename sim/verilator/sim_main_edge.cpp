#include "Vtb_edge_detector.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtb_edge_detector* top = new Vtb_edge_detector;
    while (!Verilated::gotFinish()) {
        top->eval();
        Verilated::timeInc(1);
    }
    delete top;
    return 0;
}
