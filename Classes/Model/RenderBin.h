//
//  ModelManager.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

typedef enum
{
    RENDERBIN_UNDER_UI,
    RENDERBIN_REFLECTIVE,
    RENDERBIN_BASE,
    RENDERBIN_CARDS,
    RENDERBIN_XRAY_CARD,
    RENDERBIN_COMPANIONS,
    RENDERBIN_UI,
    RENDERBIN_XRAY_EFFECT,
	RENDERBIN_FOREMOST,
    RENDERBIN_NUM
} RenderBinId;

#define RENDERBIN_DEFAULT_PRIORITY  (0)

typedef struct
{
    int     mPriority;  // Lower priority means rendered first
    BOOL    mSorted;    // Whether we sort in this renderbin
} RenderBin;