// Verilated -*- SystemC -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vour.h for the primary calling header

#include "Vour__pch.h"
#include "Vour__Syms.h"
#include "Vour___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vour___024root___dump_triggers__ico(Vour___024root* vlSelf);
#endif  // VL_DEBUG

void Vour___024root___eval_triggers__ico(Vour___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vour__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vour___024root___eval_triggers__ico\n"); );
    // Body
    vlSelf->__VicoTriggered.set(0U, (IData)(vlSelf->__VicoFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vour___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vour___024root___dump_triggers__act(Vour___024root* vlSelf);
#endif  // VL_DEBUG

void Vour___024root___eval_triggers__act(Vour___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vour__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vour___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.set(0U, ((IData)(vlSelf->__Vcellinp__our__clk) 
                                     & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP____Vcellinp__our__clk__0))));
    vlSelf->__Vtrigprevexpr___TOP____Vcellinp__our__clk__0 
        = vlSelf->__Vcellinp__our__clk;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vour___024root___dump_triggers__act(vlSelf);
    }
#endif
}
