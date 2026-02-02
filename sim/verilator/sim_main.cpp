#include "Vtb_adat_rx.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    Vtb_adat_rx* top = new Vtb_adat_rx;
    
    while (!Verilated::gotFinish()) {
        top->eval();
        Verilated::timeInc(1);
    }
    
    delete top;
    
    return 0;
}
