//
//  NeonArray.c
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "NeonTypes.h"
#import <stdbool.h>

typedef struct
{
    unsigned int mInitialNumElements;
    unsigned int mElementSize;
} NeonArrayParams;

typedef struct
{
    void* mArrayContents;
    unsigned int mNumElements;
    unsigned int mCapacity;
    unsigned int mElementSize;
} NeonArray;

#define NEON_ARRAY_INVALID_ELEMENT  (0xFFFFFFFF)

NeonArray*  NeonArray_Create(NeonArrayParams* inParams);
void        NeonArray_Destroy(NeonArray* inNeonArray);

void        NeonArray_InitParams(NeonArrayParams* outParams);
void        NeonArray_InsertElementAtIndex(NeonArray* inNeonArray, void* inData, int inIndex);
void        NeonArray_InsertElementAtEnd(NeonArray* inNeonArray, void* inData);

void        NeonArray_RemoveElementAtIndex(NeonArray* inNeonArray, int inIndex);

void*       NeonArray_GetElementAtIndexFast(NeonArray* inNeonArray, int inIndex);
void        NeonArray_GetElementAtIndex(NeonArray* inNeonArray, int inIndex, void* outData);

u32         NeonArray_GetNumElements(NeonArray* inNeonArray);

u32         NeonArray_IndexOfElement(NeonArray* inNeonArray, void* inElement);
bool        NeonArray_RemoveElement(NeonArray* inNeonArray, void* inElement);

void        NeonArray_Grow(NeonArray* inNeonArray);