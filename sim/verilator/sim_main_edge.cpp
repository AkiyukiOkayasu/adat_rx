#include "Vtb_edge_detector.h"
#include "verilated.h"
#if VM_TRACE
#include "verilated_fst_c.h"
#endif

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Vtb_edge_detector *top = new Vtb_edge_detector;
#if VM_TRACE
  Verilated::traceEverOn(true);
  VerilatedFstC *tfp = new VerilatedFstC;
  top->trace(tfp, 99);
  tfp->open("tb_edge_detector.fst");
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
