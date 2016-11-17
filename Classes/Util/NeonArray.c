//
//  NeonArray.c
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "NeonArray.h"

#import <stdlib.h>
#import <assert.h>
#import <string.h>
#import <stdbool.h>

NeonArray* NeonArray_Create(NeonArrayParams* inParams)
{
    assert(inParams->mInitialNumElements > 0);
    assert(inParams->mElementSize > 0);
    
    NeonArray* retArray = (NeonArray*)malloc(sizeof(NeonArray));
    
    u32 bufferSize = sizeof(inParams->mElementSize) * inParams->mInitialNumElements;
    
    retArray->mArrayContents = (void*)malloc(bufferSize);
    retArray->mElementSize = inParams->mElementSize;
    retArray->mNumElements = 0;
    retArray->mCapacity = inParams->mInitialNumElements;

    // Unless array creation performance is an issue, zero-fill to help debug possible memory trashing issues.
    memset(retArray->mArrayContents, 0, bufferSize);
    
    return retArray;
}

void NeonArray_Destroy(NeonArray* inNeonArray)
{
    free(inNeonArray->mArrayContents);
    free(inNeonArray);
}

void NeonArray_InitParams(NeonArrayParams* outParams)
{
    outParams->mInitialNumElements = 16;
    outParams->mElementSize = 4;
}

void NeonArray_InsertElementAtIndex(NeonArray* inNeonArray, void* inData, int inIndex)
{
    assert(inIndex >= 0);
    assert(inIndex <= inNeonArray->mNumElements);
    
    assert(inNeonArray->mNumElements <= inNeonArray->mCapacity);
    
    if (inNeonArray->mNumElements == inNeonArray->mCapacity)
    {
        NeonArray_Grow(inNeonArray);
    }
    
    // Make room for the element, shift all subsequent elements down by 1
    u32 numElementsToMove = inNeonArray->mNumElements - inIndex;
    void* srcAddress = (u8*)inNeonArray->mArrayContents + (inNeonArray->mElementSize * inIndex);
    void* destAddress = (u8*)srcAddress + inNeonArray->mElementSize;
    u32 moveSize = numElementsToMove * inNeonArray->mElementSize;
    
    if (moveSize != 0)
    {
        memcpy(destAddress, srcAddress, moveSize);
    }
    
    // Insert the new element
    memcpy(srcAddress, inData, inNeonArray->mElementSize);
    
    inNeonArray->mNumElements++;
    
    assert(inNeonArray->mNumElements < 0x7FFFFFFF);
}

void NeonArray_InsertElementAtEnd(NeonArray* inNeonArray, void* inData)
{
    NeonArray_InsertElementAtIndex(inNeonArray, inData, inNeonArray->mNumElements);
}

void NeonArray_RemoveElementAtIndex(NeonArray* inNeonArray, int inIndex)
{
    assert(inIndex >= 0);
    assert(inIndex < inNeonArray->mNumElements);
    
    if (inIndex < (inNeonArray->mNumElements - 1))
    {
        // Shift all elements backward by 1 to overwrite this element
        void* destAddress = (u8*)inNeonArray->mArrayContents + (inNeonArray->mElementSize * inIndex);
        void* srcAddress = (u8*)destAddress + inNeonArray->mElementSize;
        u32 numElementsToMove = inNeonArray->mNumElements - inIndex;
        u32 moveSize = numElementsToMove * inNeonArray->mElementSize;
        
        memcpy(destAddress, srcAddress, moveSize);
    }
    
    inNeonArray->mNumElements--;
}

void* NeonArray_GetElementAtIndexFast(NeonArray* inNeonArray, int inIndex)
{
    return (u8*)inNeonArray->mArrayContents + (inNeonArray->mElementSize * inIndex);
}

void NeonArray_GetElementAtIndex(NeonArray* inNeonArray, int inIndex, void* outData)
{
    void* elemAddress = (u8*)inNeonArray->mArrayContents + (inNeonArray->mElementSize * inIndex);
    
    memcpy(outData, elemAddress, inNeonArray->mElementSize);
}

u32 NeonArray_GetNumElements(NeonArray* inNeonArray)
{
    return inNeonArray->mNumElements;
}

u32 NeonArray_IndexOfElement(NeonArray* inNeonArray, void* inElement)
{
    for (int i = 0; i < inNeonArray->mNumElements; i++)
    {
        void* curElement = NeonArray_GetElementAtIndexFast(inNeonArray, i);
        
        if (memcmp(inElement, curElement, inNeonArray->mElementSize) == 0)
        {
            return i;
        }
    }
    
    return NEON_ARRAY_INVALID_ELEMENT;
}

bool NeonArray_RemoveElement(NeonArray* inNeonArray, void* inElement)
{
    u32 index = NeonArray_IndexOfElement(inNeonArray, inElement);
    
    if (index != NEON_ARRAY_INVALID_ELEMENT)
    {
        NeonArray_RemoveElementAtIndex(inNeonArray, index);
    }
    
    return (index != NEON_ARRAY_INVALID_ELEMENT);
}

void NeonArray_Grow(NeonArray* inNeonArray)
{
    int newCapacity = inNeonArray->mCapacity * 2;
    int bufSize = inNeonArray->mElementSize * newCapacity;
    void* newBuffer = (void*)malloc(bufSize);

    // Unless array growth performance is an issue, zero-fill to help debug possible memory trashing issues.    
    memset(newBuffer, 0, bufSize);
    
    memcpy(newBuffer, inNeonArray->mArrayContents, inNeonArray->mCapacity * inNeonArray->mElementSize);
    inNeonArray->mCapacity = newCapacity;
    
    free(inNeonArray->mArrayContents);
    inNeonArray->mArrayContents = newBuffer;
}