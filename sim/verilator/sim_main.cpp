#include "Vtb_adat_rx.h"
#include "verilated.h"

#include <cstdio>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // `bash` 経由だとstdoutがブロックバッファになるため、$displayが見えにくい。
    // 行バッファにしてテスト進行/失敗理由を即時に出力する。
    setvbuf(stdout, nullptr, _IOLBF, 0);
    setvbuf(stderr, nullptr, _IONBF, 0);
    
    Vtb_adat_rx* top = new Vtb_adat_rx;
    
    while (!Verilated::gotFinish()) {
        top->eval();
        Verilated::timeInc(1);
    }
    
    delete top;
    
    return 0;
}
