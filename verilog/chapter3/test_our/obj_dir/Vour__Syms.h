// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VOUR__SYMS_H_
#define VERILATED_VOUR__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vour.h"

// INCLUDE MODULE CLASSES
#include "Vour___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vour__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vour* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vour___024root                 TOP;

    // CONSTRUCTORS
    Vour__Syms(VerilatedContext* contextp, const char* namep, Vour* modelp);
    ~Vour__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
