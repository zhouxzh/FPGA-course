// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vour__pch.h"

//============================================================
// Constructors

Vour::Vour(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vour__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vour::Vour(const char* _vcname__)
    : Vour(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vour::~Vour() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vour___024root___eval_debug_assertions(Vour___024root* vlSelf);
#endif  // VL_DEBUG
void Vour___024root___eval_static(Vour___024root* vlSelf);
void Vour___024root___eval_initial(Vour___024root* vlSelf);
void Vour___024root___eval_settle(Vour___024root* vlSelf);
void Vour___024root___eval(Vour___024root* vlSelf);

void Vour::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vour::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vour___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vour___024root___eval_static(&(vlSymsp->TOP));
        Vour___024root___eval_initial(&(vlSymsp->TOP));
        Vour___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vour___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vour::eventsPending() { return false; }

uint64_t Vour::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vour::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vour___024root___eval_final(Vour___024root* vlSelf);

VL_ATTR_COLD void Vour::final() {
    Vour___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vour::hierName() const { return vlSymsp->name(); }
const char* Vour::modelName() const { return "Vour"; }
unsigned Vour::threads() const { return 1; }
void Vour::prepareClone() const { contextp()->prepareClone(); }
void Vour::atClone() const {
    contextp()->threadPoolpOnClone();
}

//============================================================
// Trace configuration

VL_ATTR_COLD void Vour::trace(VerilatedVcdC* tfp, int levels, int options) {
    vl_fatal(__FILE__, __LINE__, __FILE__,"'Vour::trace()' called on model that was Verilated without --trace option");
}
