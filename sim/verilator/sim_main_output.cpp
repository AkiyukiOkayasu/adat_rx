#include "Vtb_output_interface.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtb_output_interface* top = new Vtb_output_interface;
    while (!Verilated::gotFinish()) {
        top->eval();
        Verilated::timeInc(1);
    }
    delete top;
    return 0;
}
