#include "Vtb_frame_parser.h"
#include "verilated.h"
#if VM_TRACE
#include "verilated_fst_c.h"
#endif

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Vtb_frame_parser *top = new Vtb_frame_parser;
#if VM_TRACE
  Verilated::traceEverOn(true);
  VerilatedFstC *tfp = new VerilatedFstC;
  top->trace(tfp, 99);
  tfp->open("tb_frame_parser.fst");
#endif
  while (!Verilated::gotFinish()) {
    top->eval();
#if VM_TRACE
    tfp->dump(Verilated::time());
#endif
    Verilated::timeInc(1);
  }
#if VM_TRACE
  tfp->close();
  delete tfp;
#endif
  delete top;
  return 0;
}
