//
//  MenuFlowTypes.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#ifdef NEON_ESCAPE
    #define SUPPRESS_FLOW_ERROR
    #import "SKUFlow_NeonEscape.h"
    #undef SUPPRESS_FLOW_ERROR
#elif defined(NEON_21)
    #define SUPPRESS_FLOW_ERROR
    #import "SKUFlow_Generic.h"
    #undef SUPPRESS_FLOW_ERROR
#elif defined(NEON_RUN_21)
    #define SUPPRESS_FLOW_ERROR
    #import "SKUFlow_NeonRun21.h"
    #undef SUPPRESS_FLOW_ERROR
#elif defined(NEON_21_SQUARED)
    #define SUPPRESS_FLOW_ERROR
    #import "SKUFlow_Neon21Squared.h"
    #undef SUPPRESS_FLOW_ERROR
#else
    #error "Unknown target"
#endif