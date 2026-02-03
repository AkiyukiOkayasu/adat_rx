#include "Vtb_bit_decoder.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtb_bit_decoder* top = new Vtb_bit_decoder;
    while (!Verilated::gotFinish()) {
        top->eval();
        Verilated::timeInc(1);
    }
    delete top;
    return 0;
}
