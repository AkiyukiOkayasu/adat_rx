#include "Vtb_adat_rx.h"
#include "verilated.h"
#if VM_TRACE
#include "verilated_fst_c.h"
#endif

#include <cstdio>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // `bash` 経由だとstdoutがブロックバッファになるため、$displayが見えにくい。
    // 行バッファにしてテスト進行/失敗理由を即時に出力する。
    setvbuf(stdout, nullptr, _IOLBF, 0);
    setvbuf(stderr, nullptr, _IONBF, 0);
    
    Vtb_adat_rx* top = new Vtb_adat_rx;
    
#if VM_TRACE
    Verilated::traceEverOn(true);
    VerilatedFstC* tfp = new VerilatedFstC;
    top->trace(tfp, 99);
    tfp->open("adat_rx.fst");
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
