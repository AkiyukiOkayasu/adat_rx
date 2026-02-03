#include "Vtb_frame_parser.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtb_frame_parser* top = new Vtb_frame_parser;
    while (!Verilated::gotFinish()) {
        top->eval();
        Verilated::timeInc(1);
    }
    delete top;
    return 0;
}
