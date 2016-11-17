//
//  NeonMath.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#include "NeonMath.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdbool.h>
#include <assert.h>
#include <stdio.h>

#include "TargetConditionals.h"

#ifdef __cplusplus
extern "C"
{
#endif

#define NEON_PRINT_TABS(x)  { for (int i = 0; i < x; i++) printf("\t"); }

// Not sure if the simulator is internally using a lower precision depth buffer or something,
// but we're getting Z-fighting with cards and table using the smaller epsilon now (sim only).
#if TARGET_IPHONE_SIMULATOR
const float EPSILON = 0.02;
#else
const float EPSILON = 0.01;
#endif

const float SMALL_EPSILON = 0.002;

#pragma mark Scalar

float DegreesToRadians(float inDegrees)
{
    return (inDegrees * M_PI) / 180.0f;
}

float RadiansToDegrees(float inRadians)
{
    return inRadians * (180.0f / M_PI);
}

float ClampFloat(float inValue, float inLower, float inUpper)
{
    float retVal = inValue;
    
    if (inValue < inLower)
    {
        retVal = inLower;
    }
    else if (inValue > inUpper)
    {
        retVal = inUpper;
    }
    
    return retVal;
}

int ClampInt(int inValue, int inLower, int inUpper)
{
    int retVal = inValue;
    
    if (inValue < inLower)
    {
        retVal = inLower;
    }
    else if (inValue > inUpper)
    {
        retVal = inUpper;
    }
    
    return retVal;
}

unsigned int ClampUInt(unsigned int inValue, unsigned int inLower, unsigned int inUpper)
{
    int retVal = inValue;
    
    if (inValue < inLower)
    {
        retVal = inLower;
    }
    else if (inValue > inUpper)
    {
        retVal = inUpper;
    }
    
    return retVal;
}

float LClampFloat(float inValue, float inLower)
{
    float retVal = inValue;
    
    if (inValue < inLower)
    {
        retVal = inLower;
    }
    
    return retVal;
}

int LClampInt(float inValue, float inLower)
{
    int retVal = inValue;
    
    if (inValue < inLower)
    {
        retVal = inLower;
    }
    
    return retVal;
}

float FloorToMultipleFloat(float inValue, float inMultiplier)
{
    float divisor = (float)((int)(inValue / inMultiplier));
    
    return divisor * inMultiplier;
}

bool RangesIntersect(Range* inLeft, Range* inRight)
{
    // Case where the left range is entirely contained within the right range
    //
    // Left Range:           -------
    // Right Range:      ---------------
    if ((inLeft->mStart >= inRight->mStart) && ((inLeft->mStart + inLeft->mLength) <= (inRight->mStart + inRight->mLength)))
    {
        return true;
    }
    // Case where right range is entirely contained within the left range
    //
    // Left Range:       -----------------
    // Right Range:         --------
    else if ((inLeft->mStart <= inRight->mStart) && ((inLeft->mStart + inLeft->mLength) >= (inRight->mStart + inRight->mLength)))
    {
        return true;
    }
    // Case where the left range is to the left, but overlaps with the right range
    //
    // Left Range:      ---------
    // Right Range:         ----------
    else if ((inLeft->mStart <= inRight->mStart) && ((inLeft->mStart + inLeft->mLength) <= (inRight->mStart + inRight->mLength)))
    {
        return true;
    }
    // Case where the left range is to the right, but overlaps with the right range
    //
    // Left Range :          ----------
    // Right Range:      ---------
    else if ((inLeft->mStart >= inRight->mStart) && (inLeft->mStart <= (inRight->mStart + inRight->mLength)))
    {
        return true;
    }
    
    return false;
}

int  RoundUpPOT(int inValue)
{
    float logVal = log2f((float)inValue);
    int exponent = (int)ceilf(logVal);
    return pow(2, exponent);
}

int  RoundDownPOT(int inValue)
{
    float logVal = log2f((float)inValue);
    int exponent = (int)floorf(logVal);
    return pow(2, exponent);
}

#define ARC4RANDOM_MAX      0x100000000

float RandFloat(float inLower, float inUpper)
{
    if (inLower > inUpper)
    {
        float temp = inLower;
        inLower = inUpper;
        inUpper = temp;
    }
    
    float randNum = (float)arc4random();
    float ratio = randNum / (float)(ARC4RANDOM_MAX);
    
    return (ratio * (inUpper - inLower)) + inLower;
}

double Sinc(double x)
{
    if (x == 0.0)
    {
        return 1.0;
    }
    
    return sin(M_PI * x) / (M_PI * x);
}

double Bessel0(double x)
{
    const double EPSILON_RATIO = 1E-16;
    double xh, sum, pow, ds;

    xh = 0.5 * x;
    sum = 1.0;
    pow = 1.0;
    ds = 1.0;

    int k = 0;
    while (ds > sum * EPSILON_RATIO)
    {
        k++;
        pow *= (xh / k);
        ds = pow * pow;
        sum = sum + ds;
    }

    return sum;
}

double Kaiser(double alpha, double half_width, double x)
{
    double ratio = (x / half_width);
    return Bessel0(alpha * sqrt(1 - ratio * ratio)) / Bessel0(alpha);
}

float LerpFloat(float inLeft, float inRight, float inBlend)
{
    return ((inLeft * (1.0 - inBlend)) + (inRight * inBlend));
}

#define BEZIER_APPROXIMATION_EPSILON (1.0e-06)
#define BEZIER_VERY_SMALL (1.0e-9)
#define BEZIER_MAXIMUM_ITERATIONS (12)

/**
* This function taken from: http://www.collada.org/public_forum/viewtopic.php?f=12&t=1132
* Returns the approximated parameter of a parametric curve for the value X
* @param atX At which value should the parameter be evaluated
* @param P0_X The first interpolation point of a curve segment
* @param C0_X The first control point of a curve segment
* @param C1_X The second control point of a curve segment
* @param P1_x The second interpolation point of a curve segment
* @return The parametric argument that is used to retrieve atX using the parametric function representation of this curve
*/

float ApproximateCubicBezierParameter(float atX, float P0_X, float C0_X, float C1_X, float P1_X )
{
   if (atX - P0_X < BEZIER_VERY_SMALL)
      return 0.0; 
   
   if (P1_X - atX < BEZIER_VERY_SMALL)  
      return 1.0; 
   
   long iterationStep = 0; 
   
   float u = 0.0f; float v = 1.0f; 
   
   //iteratively apply subdivision to approach value atX
   while (iterationStep < BEZIER_MAXIMUM_ITERATIONS) { 
      
      // de Casteljau Subdivision. 
      double a = (P0_X + C0_X)*0.5f; 
      double b = (C0_X + C1_X)*0.5f; 
      double c = (C1_X + P1_X)*0.5f; 
      double d = (a + b)*0.5f; 
      double e = (b + c)*0.5f; 
      double f = (d + e)*0.5f; //this one is on the curve!
      
      //The curve point is close enough to our wanted atX
      if (fabs(f - atX) < BEZIER_APPROXIMATION_EPSILON) 
         return ClampFloat((u + v)*0.5f, 0.0f, 1.0f); 
      
      //dichotomy
      if (f < atX) { 
         P0_X = f; 
         C0_X = e; 
         C1_X = c; 
         u = (u + v)*0.5f; 
      } else { 
         C0_X = a; C1_X = d; P1_X = f; v = (u + v)*0.5f; 
      } 
      
      iterationStep++; 
   } 
   
   return ClampFloat((u + v)*0.5f, 0.0f, 1.0f); 
}

float Min3(float inX, float inY, float inZ)
{
    float a = min(inX, inY);
    return min(a, inZ);
}

float Min3WithComponent(float inX, float inY, float inZ, unsigned int* outComponent)
{
    if (inX < inY)
    {
        if (inZ < inX)
        {
            *outComponent = 2;
            return inZ;
        }
        else
        {
            *outComponent = 0;
            return inX;
        }
    }
    else
    {
        if (inZ < inY)
        {
            *outComponent = 2;
            return inZ;
        }
        else
        {
            *outComponent = 1;
            return inY;
        }
    }
}

void DistributeItemsOverRange(float inRangeWidth, float inNumItems, float inItemWidth, float* outStart, float* outStep)
{
    *outStep = (float)inRangeWidth / (float)inNumItems;
    *outStart = (*outStep / 2.0f) - ((float)inItemWidth / 2.0f);
}

#pragma mark Vector

void Set(Vector3* inVector, float inX, float inY, float inZ)
{
    inVector->mVector[x] = inX;
    inVector->mVector[y] = inY;
    inVector->mVector[z] = inZ;
}

void SetVec2(Vector2* inVector, float inX, float inY)
{
    inVector->mVector[x] = inX;
    inVector->mVector[y] = inY;
}

void SetVec4(Vector4* inVector, float inX, float inY, float inZ, float inW)
{
    inVector->mVector[x] = inX;
    inVector->mVector[y] = inY;
    inVector->mVector[z] = inZ;
    inVector->mVector[w] = inW;
}

Vector4* SetVec4From3(Vector4* inVector, Vector3* inVector3, float inW)
{
    inVector->mVector[x] = inVector3->mVector[x];
    inVector->mVector[y] = inVector3->mVector[y];
    inVector->mVector[z] = inVector3->mVector[z];
    inVector->mVector[w] = inW;
    
    return inVector;
}

Vector3* SetVec3From4(Vector3* inVector, Vector4* inVector4)
{
    inVector->mVector[x] = inVector4->mVector[x];
    inVector->mVector[y] = inVector4->mVector[y];
    inVector->mVector[z] = inVector4->mVector[z];

    return inVector;
}

void ZeroVec3(Vector3* inVector)
{
    inVector->mVector[x] = 0.0f;
    inVector->mVector[y] = 0.0f;
    inVector->mVector[z] = 0.0f;
}

void ZeroVec4(Vector4* inVector)
{
    inVector->mVector[x] = 0.0f;
    inVector->mVector[y] = 0.0f;
    inVector->mVector[z] = 0.0f;
    inVector->mVector[w] = 0.0f;
}

void CloneVec4(Vector4* inSource, Vector4* inDest)
{
    memcpy(inDest->mVector, inSource->mVector, sizeof(float) * 4);
}

void CloneVec3(Vector3* inSource, Vector3* inDest)
{
    memcpy(inDest->mVector, inSource->mVector, sizeof(float) * 3);
}

void CloneVec2(Vector2* inSource, Vector2* inDest)
{
    memcpy(inDest->mVector, inSource->mVector, sizeof(float) * 2);
}

void Add3(Vector3* inFirst, Vector3* inSecond, Vector3* outResult)
{
    outResult->mVector[x] = inFirst->mVector[x] + inSecond->mVector[x];
    outResult->mVector[y] = inFirst->mVector[y] + inSecond->mVector[y];
    outResult->mVector[z] = inFirst->mVector[z] + inSecond->mVector[z];
}

void Add4(Vector4* inFirst, Vector4* inSecond, Vector4* outResult)
{
    outResult->mVector[x] = inFirst->mVector[x] + inSecond->mVector[x];
    outResult->mVector[y] = inFirst->mVector[y] + inSecond->mVector[y];
    outResult->mVector[z] = inFirst->mVector[z] + inSecond->mVector[z];
    outResult->mVector[w] = inFirst->mVector[w] + inSecond->mVector[w];
}

void Sub2(Vector2* inFirst, Vector2* inSecond, Vector2* outResult)
{
    outResult->mVector[x] = inFirst->mVector[x] - inSecond->mVector[x];
    outResult->mVector[y] = inFirst->mVector[y] - inSecond->mVector[y];
}

void Sub3(Vector3* inFirst, Vector3* inSecond, Vector3* outResult)
{
    outResult->mVector[x] = inFirst->mVector[x] - inSecond->mVector[x];
    outResult->mVector[y] = inFirst->mVector[y] - inSecond->mVector[y];
    outResult->mVector[z] = inFirst->mVector[z] - inSecond->mVector[z];
}

void Sub4(Vector4* inFirst, Vector4* inSecond, Vector4* outResult)
{
    outResult->mVector[x] = inFirst->mVector[x] - inSecond->mVector[x];
    outResult->mVector[y] = inFirst->mVector[y] - inSecond->mVector[y];
    outResult->mVector[z] = inFirst->mVector[z] - inSecond->mVector[z];
    outResult->mVector[w] = inFirst->mVector[w] - inSecond->mVector[w];
}

void Scale3(Vector3* inVec, float inScale)
{
    inVec->mVector[x] *= inScale;
    inVec->mVector[y] *= inScale;
    inVec->mVector[z] *= inScale;
}

void Scale4(Vector4* inVec, float inScale)
{
    inVec->mVector[x] *= inScale;
    inVec->mVector[y] *= inScale;
    inVec->mVector[z] *= inScale;
    inVec->mVector[w] *= inScale;
}

float Length2(Vector2* inVector)
{
    return sqrt((inVector->mVector[x] * inVector->mVector[x]) + (inVector->mVector[y] * inVector->mVector[y]));
}

void Mul3(float inMultiplier, Vector3* inOutVector)
{
    inOutVector->mVector[x] *= inMultiplier;
    inOutVector->mVector[y] *= inMultiplier;
    inOutVector->mVector[z] *= inMultiplier;
}

void Normalize3(Vector3* inOutVector)
{
    float magnitudeSquared =   (inOutVector->mVector[x] * inOutVector->mVector[x]) + 
                                (inOutVector->mVector[y] * inOutVector->mVector[y]) +
                                (inOutVector->mVector[z] * inOutVector->mVector[z]);
                                
    float magnitude = sqrt(magnitudeSquared);
    
    if (magnitude != 0.0f)
    {
        inOutVector->mVector[x] = inOutVector->mVector[x] / magnitude;
        inOutVector->mVector[y] = inOutVector->mVector[y] / magnitude;
        inOutVector->mVector[z] = inOutVector->mVector[z] / magnitude;
    }
    else
    {
        Set(inOutVector, 0.0f, 0.0f, 0.0f);
    }
}

void Normalize4(Vector4* inOutVector)
{
    float length = Length4(inOutVector);
    
    if (length != 0.0f)
    {
        inOutVector->mVector[x] /= length;
        inOutVector->mVector[y] /= length;
        inOutVector->mVector[z] /= length;
        inOutVector->mVector[w] /= length;
    }
    else
    {
        SetVec4(inOutVector, 0.0f, 0.0f, 0.0f, 0.0f);
    }
}

void Cross3(Vector3* inFirst, Vector3* inSecond, Vector3* outResult)
{
    // Cannot do in place cross-product.
    assert((inFirst != outResult) && (inSecond != outResult));
    
    outResult->mVector[x] = (inFirst->mVector[y] * inSecond->mVector[z]) - (inFirst->mVector[z] * inSecond->mVector[y]);
    outResult->mVector[y] = (inFirst->mVector[z] * inSecond->mVector[x]) - (inFirst->mVector[x] * inSecond->mVector[z]);
    outResult->mVector[z] = (inFirst->mVector[x] * inSecond->mVector[y]) - (inFirst->mVector[y] * inSecond->mVector[x]);
}

float Dot3(Vector3* inFirst, Vector3* inSecond)
{
    return (inFirst->mVector[x] * inSecond->mVector[x]) + (inFirst->mVector[y] * inSecond->mVector[y]) + (inFirst->mVector[z] * inSecond->mVector[z]);
}

float Length3(Vector3* inVector)
{
    return sqrt( (inVector->mVector[x] * inVector->mVector[x]) +
                 (inVector->mVector[y] * inVector->mVector[y]) +
                 (inVector->mVector[z] * inVector->mVector[z]) );
}

float Length4(Vector4* inVector)
{
    return sqrt( (inVector->mVector[x] * inVector->mVector[x]) +
                 (inVector->mVector[y] * inVector->mVector[y]) +
                 (inVector->mVector[z] * inVector->mVector[z]) +
                 (inVector->mVector[w] * inVector->mVector[2]) );
}

bool Equal(Vector3* inLeft, Vector3* inRight)
{
    return ((inLeft->mVector[x] == inRight->mVector[x]) && (inLeft->mVector[y] == inRight->mVector[y]) && (inLeft->mVector[z] == inRight->mVector[z]));
}

void MidPointVec3(Vector3* inFirst, Vector3* inSecond, Vector3* outMidPoint)
{
    outMidPoint->mVector[x] = (inFirst->mVector[x] + inSecond->mVector[x]) / 2.0f;
    outMidPoint->mVector[y] = (inFirst->mVector[y] + inSecond->mVector[y]) / 2.0f;
    outMidPoint->mVector[z] = (inFirst->mVector[z] + inSecond->mVector[z]) / 2.0f;
}

void LerpVec3(Vector3* inLeft, Vector3* inRight, float inBlend, Vector3* outResult)
{
    outResult->mVector[x] = (inLeft->mVector[x] * (1.0 - inBlend)) + (inRight->mVector[x] * inBlend);
    outResult->mVector[y] = (inLeft->mVector[y] * (1.0 - inBlend)) + (inRight->mVector[y] * inBlend);
    outResult->mVector[z] = (inLeft->mVector[z] * (1.0 - inBlend)) + (inRight->mVector[z] * inBlend);
}

void PerpVec3(Vector3* inSource, Vector3* inDest)
{
    // Use the method described in http://www.gamedev.net/community/forums/topic.asp?topic_id=445164 for finding
    // an arbitrary vector perpendicular to another vector.
    
    unsigned int component = 0;
    Min3WithComponent(fabsf(inSource->mVector[x]), fabsf(inSource->mVector[y]), fabsf(inSource->mVector[z]), &component);
    
    // Check for valid component
    assert(component >= 0 && component <= 2);
    
    Vector3 temp;
    Set(&temp, 0.0f, 0.0f, 0.0f);
    temp.mVector[component] = 1.0f;
    
    Cross3(inSource, &temp, inDest);
    Normalize3(inDest);
    
    // PerpVec3 failed
    assert(Dot3(inSource, inDest) == 0.0f);
}

#pragma mark Matrix

void PrintMatrix44(Matrix44* inMatrix, int inNumTabs)
{
    for (int row = 0; row < 4; row++)
    {
        NEON_PRINT_TABS(inNumTabs);
        printf("%f,\t%f,\t%f,\t%f\n", inMatrix->mMatrix[0 + row], inMatrix->mMatrix[4 + row], inMatrix->mMatrix[8 + row], inMatrix->mMatrix[12 + row]);
    }
}

void CloneMatrix44(Matrix44* inSrc, Matrix44* inDest)
{
    memcpy(inDest->mMatrix, inSrc->mMatrix, (sizeof(float) * 16));
}

void SetIdentity(Matrix44* inMatrix)
{
    memset(inMatrix, 0, sizeof(Matrix44));
    
    inMatrix->mMatrix[0] = 1.0f;
    inMatrix->mMatrix[5] = 1.0f;
    inMatrix->mMatrix[10] = 1.0f;
    inMatrix->mMatrix[15] = 1.0f;
}

void Transpose(Matrix44* inMatrix)
{
    Matrix44 transpose;
    
    transpose.mMatrix[0] = inMatrix->mMatrix[0];
    transpose.mMatrix[1] = inMatrix->mMatrix[4];
    transpose.mMatrix[2] = inMatrix->mMatrix[8];
    transpose.mMatrix[3] = inMatrix->mMatrix[12];
    
    transpose.mMatrix[4] = inMatrix->mMatrix[1];
    transpose.mMatrix[5] = inMatrix->mMatrix[5];
    transpose.mMatrix[6] = inMatrix->mMatrix[9];
    transpose.mMatrix[7] = inMatrix->mMatrix[13];
    
    transpose.mMatrix[8] = inMatrix->mMatrix[2];
    transpose.mMatrix[9] = inMatrix->mMatrix[6];
    transpose.mMatrix[10] = inMatrix->mMatrix[10];
    transpose.mMatrix[11] = inMatrix->mMatrix[14];
    
    transpose.mMatrix[12] = inMatrix->mMatrix[3];
    transpose.mMatrix[13] = inMatrix->mMatrix[7];
    transpose.mMatrix[14] = inMatrix->mMatrix[11];
    transpose.mMatrix[15] = inMatrix->mMatrix[15];
    
    memcpy(inMatrix, &transpose, sizeof(Matrix44));
}

void DivideRow(Matrix44* inMatrix, int inRow, float inDivisor)
{
    for (int col = 0; col < 4; col++)
    {
        int index = inRow + (col * 4);
        
        inMatrix->mMatrix[index] /= inDivisor;
    }
}

void SubtractRow(Matrix44* inMatrix, int inLeftRow, int inRightRow, float inRightRowScale, int inDestRow)
{
    for (int col = 0; col < 4; col++)
    {
        int leftIndex = inLeftRow + (col * 4);
        int rightIndex = inRightRow + (col * 4);
        int destIndex = inDestRow + (col * 4);
        
        float left = inMatrix->mMatrix[leftIndex];
        float right = inMatrix->mMatrix[rightIndex];
        
        inMatrix->mMatrix[destIndex] = left - (inRightRowScale * right);
    }
}

bool Inverse(Matrix44* inMatrix, Matrix44* outInverse)
{
    double inv[16], det;
    int i;
    float* m = inMatrix->mMatrix;
    
    // Taken from the MESA implementation of gluInvertMatrix

    inv[0] = m[5]  * m[10] * m[15] - 
             m[5]  * m[11] * m[14] - 
             m[9]  * m[6]  * m[15] + 
             m[9]  * m[7]  * m[14] +
             m[13] * m[6]  * m[11] - 
             m[13] * m[7]  * m[10];

    inv[4] = -m[4]  * m[10] * m[15] + 
              m[4]  * m[11] * m[14] + 
              m[8]  * m[6]  * m[15] - 
              m[8]  * m[7]  * m[14] - 
              m[12] * m[6]  * m[11] + 
              m[12] * m[7]  * m[10];

    inv[8] = m[4]  * m[9] * m[15] - 
             m[4]  * m[11] * m[13] - 
             m[8]  * m[5] * m[15] + 
             m[8]  * m[7] * m[13] + 
             m[12] * m[5] * m[11] - 
             m[12] * m[7] * m[9];

    inv[12] = -m[4]  * m[9] * m[14] + 
               m[4]  * m[10] * m[13] +
               m[8]  * m[5] * m[14] - 
               m[8]  * m[6] * m[13] - 
               m[12] * m[5] * m[10] + 
               m[12] * m[6] * m[9];

    inv[1] = -m[1]  * m[10] * m[15] + 
              m[1]  * m[11] * m[14] + 
              m[9]  * m[2] * m[15] - 
              m[9]  * m[3] * m[14] - 
              m[13] * m[2] * m[11] + 
              m[13] * m[3] * m[10];

    inv[5] = m[0]  * m[10] * m[15] - 
             m[0]  * m[11] * m[14] - 
             m[8]  * m[2] * m[15] + 
             m[8]  * m[3] * m[14] + 
             m[12] * m[2] * m[11] - 
             m[12] * m[3] * m[10];

    inv[9] = -m[0]  * m[9] * m[15] + 
              m[0]  * m[11] * m[13] + 
              m[8]  * m[1] * m[15] - 
              m[8]  * m[3] * m[13] - 
              m[12] * m[1] * m[11] + 
              m[12] * m[3] * m[9];

    inv[13] = m[0]  * m[9] * m[14] - 
              m[0]  * m[10] * m[13] - 
              m[8]  * m[1] * m[14] + 
              m[8]  * m[2] * m[13] + 
              m[12] * m[1] * m[10] - 
              m[12] * m[2] * m[9];

    inv[2] = m[1]  * m[6] * m[15] - 
             m[1]  * m[7] * m[14] - 
             m[5]  * m[2] * m[15] + 
             m[5]  * m[3] * m[14] + 
             m[13] * m[2] * m[7] - 
             m[13] * m[3] * m[6];

    inv[6] = -m[0]  * m[6] * m[15] + 
              m[0]  * m[7] * m[14] + 
              m[4]  * m[2] * m[15] - 
              m[4]  * m[3] * m[14] - 
              m[12] * m[2] * m[7] + 
              m[12] * m[3] * m[6];

    inv[10] = m[0]  * m[5] * m[15] - 
              m[0]  * m[7] * m[13] - 
              m[4]  * m[1] * m[15] + 
              m[4]  * m[3] * m[13] + 
              m[12] * m[1] * m[7] - 
              m[12] * m[3] * m[5];

    inv[14] = -m[0]  * m[5] * m[14] + 
               m[0]  * m[6] * m[13] + 
               m[4]  * m[1] * m[14] - 
               m[4]  * m[2] * m[13] - 
               m[12] * m[1] * m[6] + 
               m[12] * m[2] * m[5];

    inv[3] = -m[1] * m[6] * m[11] + 
              m[1] * m[7] * m[10] + 
              m[5] * m[2] * m[11] - 
              m[5] * m[3] * m[10] - 
              m[9] * m[2] * m[7] + 
              m[9] * m[3] * m[6];

    inv[7] = m[0] * m[6] * m[11] - 
             m[0] * m[7] * m[10] - 
             m[4] * m[2] * m[11] + 
             m[4] * m[3] * m[10] + 
             m[8] * m[2] * m[7] - 
             m[8] * m[3] * m[6];

    inv[11] = -m[0] * m[5] * m[11] + 
               m[0] * m[7] * m[9] + 
               m[4] * m[1] * m[11] - 
               m[4] * m[3] * m[9] - 
               m[8] * m[1] * m[7] + 
               m[8] * m[3] * m[5];

    inv[15] = m[0] * m[5] * m[10] - 
              m[0] * m[6] * m[9] - 
              m[4] * m[1] * m[10] + 
              m[4] * m[2] * m[9] + 
              m[8] * m[1] * m[6] - 
              m[8] * m[2] * m[5];

    det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];

    if (det == 0)
        return false;

    det = 1.0 / det;

    for (i = 0; i < 16; i++)
        outInverse->mMatrix[i] = inv[i] * det;

    return true;
}

void NeonAssert(bool condition)
{
    if (!condition)
    {
        int* foo = NULL;
        *foo = 99;
    }
}

void InverseTranspose(Matrix44* inMatrix, Matrix44* outInverseTranspose)
{
    Inverse(inMatrix, outInverseTranspose);
    Transpose(outInverseTranspose);
}

void InverseView(Matrix44* inMatrix, Matrix44* outInverse)
{
    SetIdentity(outInverse);
    
    outInverse->mMatrix[1] = inMatrix->mMatrix[4];
    outInverse->mMatrix[2] = inMatrix->mMatrix[8];
    outInverse->mMatrix[4] = inMatrix->mMatrix[1];
    outInverse->mMatrix[6] = inMatrix->mMatrix[9];
    outInverse->mMatrix[8] = inMatrix->mMatrix[2];
    outInverse->mMatrix[9] = inMatrix->mMatrix[6];
    
    outInverse->mMatrix[12] = -inMatrix->mMatrix[12];
    outInverse->mMatrix[13] = -inMatrix->mMatrix[13];
    outInverse->mMatrix[14] = -inMatrix->mMatrix[14];
}

void InverseProjection(Matrix44* inMatrix, Matrix44* outInverse)
{
    SetIdentity(outInverse);
    
    // Assuming matrix in the form
    //
    // a 0 0 0
    // 0 b 0 0
    // 0 0 c d
    // 0 0 e 0
    //
    
    float a = inMatrix->mMatrix[0];
    float b = inMatrix->mMatrix[5];
    float c = inMatrix->mMatrix[10];
    float d = inMatrix->mMatrix[14];
    float e = inMatrix->mMatrix[11];
    
    outInverse->mMatrix[0] = 1.0 / a;
    outInverse->mMatrix[5] = 1.0 / b;
    outInverse->mMatrix[10] = 0.0f;
    outInverse->mMatrix[11] = 1.0 / d;
    outInverse->mMatrix[14] = 1.0 / e;
    outInverse->mMatrix[15] = - c / (d * e);
}

void MatrixMultiply(Matrix44* inLeft, Matrix44* inRight, Matrix44* outResult)
{
    Matrix44* leftSource = inLeft;
    Matrix44* rightSource = inRight;
    Matrix44 tempLeft, tempRight;
    
    if (inLeft == outResult)
    {
        CloneMatrix44(inLeft, &tempLeft);
        leftSource = &tempLeft;
    }
    
    if (inRight == outResult)
    {
        CloneMatrix44(inRight, &tempRight);
        rightSource = &tempRight;
    }
    
    float* l = leftSource->mMatrix;
    float* r = rightSource->mMatrix;
        
    for (int row = 0; row < 4; row++)
    {
        int writeIndex = (0 * 4) + row;
        
        int leftReadBase = row;
        int rightReadBase = (0 * 4);
        
        outResult->mMatrix[writeIndex] =    (l[leftReadBase] * r[rightReadBase]) + 
                                            (l[leftReadBase + 4] * r[rightReadBase + 1]) + 
                                            (l[leftReadBase + 8] * r[rightReadBase + 2]) +
                                            (l[leftReadBase + 12] * r[rightReadBase + 3]);
                                            
        writeIndex = (1 * 4) + row;
        
        leftReadBase = row;
        rightReadBase = (1 * 4);
        
        outResult->mMatrix[writeIndex] =    (l[leftReadBase] * r[rightReadBase]) + 
                                            (l[leftReadBase + 4] * r[rightReadBase + 1]) + 
                                            (l[leftReadBase + 8] * r[rightReadBase + 2]) +
                                            (l[leftReadBase + 12] * r[rightReadBase + 3]);
        writeIndex = (2 * 4) + row;
        
        leftReadBase = row;
        rightReadBase = (2 * 4);
        
        outResult->mMatrix[writeIndex] =    (l[leftReadBase] * r[rightReadBase]) + 
                                            (l[leftReadBase + 4] * r[rightReadBase + 1]) + 
                                            (l[leftReadBase + 8] * r[rightReadBase + 2]) +
                                            (l[leftReadBase + 12] * r[rightReadBase + 3]);
        writeIndex = (3 * 4) + row;
        
        leftReadBase = row;
        rightReadBase = (3 * 4);
        
        outResult->mMatrix[writeIndex] =    (l[leftReadBase] * r[rightReadBase]) + 
                                            (l[leftReadBase + 4] * r[rightReadBase + 1]) + 
                                            (l[leftReadBase + 8] * r[rightReadBase + 2]) +
                                            (l[leftReadBase + 12] * r[rightReadBase + 3]);

    }
}


void FlipMatrixY(Matrix44* inOutMatrix)
{
    Matrix44 scale;
    
    GenerateScaleMatrix(1.0f, -1.0f, 1.0f, &scale);
    MatrixMultiply(&scale, inOutMatrix, inOutMatrix);
}

void FlipMatrixZ(Matrix44* inOutMatrix)
{
    Matrix44 scale;
    
    GenerateScaleMatrix(1.0f, 1.0f, -1.0f, &scale);
    MatrixMultiply(&scale, inOutMatrix, inOutMatrix);
}

void GenerateRotationMatrix(float inAngleDegrees, float inX, float inY, float inZ, Matrix44* outMatrix)
{
    // Formula taken from http://www.opengl.org/documentation/specs/man_pages/hardcopy/GL/html/gl/rotate.html
    // to be consistent with OpenGL spec.
    
    float rX, rY, rZ;
    
    rX = inX;
    rY = inY;
    rZ = inZ;
    
    Vector3 axisRotation;
    Set(&axisRotation, inX, inY, inZ);
    
    Normalize3(&axisRotation);
    
    rX = axisRotation.mVector[x];
    rY = axisRotation.mVector[y];
    rZ = axisRotation.mVector[z];
    
    float c = cos(DegreesToRadians(inAngleDegrees));
    float s = sin(DegreesToRadians(inAngleDegrees));
    
    outMatrix->mMatrix[0] = (rX * rX * (1.0f - c)) + c;
    outMatrix->mMatrix[1] = (rY * rX * (1.0f - c)) + (rZ * s);
    outMatrix->mMatrix[2] = (rX * rZ * (1.0f - c)) - (rY * s);
    outMatrix->mMatrix[3] = 0.0f;
    
    outMatrix->mMatrix[4] = (rX * rY * (1.0f - c)) - (rZ * s);
    outMatrix->mMatrix[5] = (rY * rY * (1.0f - c)) + c;
    outMatrix->mMatrix[6] = (rY * rZ * (1.0f - c)) + (rX * s);
    outMatrix->mMatrix[7] = 0.0f;
    
    outMatrix->mMatrix[8] = (rX * rZ * (1.0f - c)) + (rY * s);
    outMatrix->mMatrix[9] = (rY * rZ * (1.0f - c)) - (rX * s);
    outMatrix->mMatrix[10] = (rZ * rZ * (1.0f - c)) + c;
    outMatrix->mMatrix[11] = 0.0f;
    
    outMatrix->mMatrix[12] = 0.0f;
    outMatrix->mMatrix[13] = 0.0f;
    outMatrix->mMatrix[14] = 0.0f;
    outMatrix->mMatrix[15] = 1.0f;
}

void GenerateRotationAroundLine(float inAngle, Vector3* inPoint, Vector3* inDirection, Matrix44* outMatrix)
{
    Matrix44 rotationMatrix;
    Matrix44 translationMatrix;
    Matrix44 reverseTranslationMatrix;
        
    GenerateTranslationMatrix(inPoint->mVector[x], inPoint->mVector[y], inPoint->mVector[z], &translationMatrix);
    GenerateTranslationMatrix(-inPoint->mVector[x], -inPoint->mVector[y], -inPoint->mVector[z], &reverseTranslationMatrix);
    GenerateRotationMatrix(inAngle, inDirection->mVector[x], inDirection->mVector[y], inDirection->mVector[z], &rotationMatrix);
    
    MatrixMultiply(&rotationMatrix, &reverseTranslationMatrix, outMatrix);
    MatrixMultiply(&translationMatrix, outMatrix, outMatrix);
}

void GenerateTranslationMatrix(float inTranslateX, float inTranslateY, float inTranslateZ, Matrix44* outMatrix)
{
    SetIdentity(outMatrix);
    
    outMatrix->mMatrix[12] = inTranslateX;
    outMatrix->mMatrix[13] = inTranslateY;
    outMatrix->mMatrix[14] = inTranslateZ;
}

void GenerateTranslationMatrixFromVector(Vector3* inTranslationVector, Matrix44* outMatrix)
{
    GenerateTranslationMatrix(  inTranslationVector->mVector[x],
                                inTranslationVector->mVector[y],
                                inTranslationVector->mVector[z],
                                outMatrix   );
}

void GenerateScaleMatrix(float inScaleX, float inScaleY, float inScaleZ, Matrix44* outMatrix)
{
    SetIdentity(outMatrix);
    
    outMatrix->mMatrix[0] = inScaleX;
    outMatrix->mMatrix[5] = inScaleY;
    outMatrix->mMatrix[10] = inScaleZ;
}

void GenerateVectorToVectorTransform(Vector3* inOrig, Vector3* inDest, Matrix44* outTransform)
{
    Vector3 cross;
    Cross3(inOrig, inDest, &cross);
    Normalize3(&cross);
    
    float angle = acos(Dot3(inOrig, inDest));
    
    GenerateRotationMatrix(RadiansToDegrees(angle), cross.mVector[x], cross.mVector[y], cross.mVector[z], outTransform);
}

void NeonUnionRect(Rect2D* inBase, Rect2D* inAdd)
{
    inBase->mXMin = min(inBase->mXMin, inAdd->mXMin);
    inBase->mXMax = max(inBase->mXMax, inAdd->mXMax);
    inBase->mYMin = min(inBase->mYMin, inAdd->mYMin);
    inBase->mYMax = max(inBase->mYMax, inAdd->mYMax);
}

bool PointInRect3D(Vector3* inPoint, Rect3D* inRect)
{
	return false;
}

static bool SameSide(Vector3* p1, Vector3* p2, Vector3* a, Vector3* b)
{
    Vector3 cp1, cp2;
    Vector3 v_ab, v_ap1, v_ap2;
    
    Sub3(b, a, &v_ab);
    Sub3(p1, a, &v_ap1);
    Sub3(p2, a, &v_ap2);
    
    Cross3(&v_ab, &v_ap1, &cp1);
    Cross3(&v_ab, &v_ap2, &cp2);
    
    if (Dot3(&cp1, &cp2) >= 0)
    {
        return true;
    }
    
    return false;
}

static bool PointInTriangle(Vector3* p, Vector3* a, Vector3* b, Vector3 *c)
{
    if (SameSide(p, a, b, c) && SameSide(p, b, a, c) && SameSide(p, c, a, b))
    {
        return true;
    }
    
    return false;
}

bool RayIntersectsRect3D(Vector3* inPoint, Vector3* inDirection, Rect3D* inRect)
{	
	Plane plane;
	PlaneFromRect3D(inRect, &plane);
	
	Vector3 intersectionPoint;
	float	t;
	RayIntersectionWithPlane(inPoint, inDirection, &plane, &intersectionPoint, &t);
	
	// Plane is "behind" the ray in this case
	if (t < 0)
	{
		return false;
	}

#if !NEON_PRODUCTION	
	assert(VerifyRectWinding(inRect));
#endif

#if 0
    Vector3 V1, V3, V4, V5;
    
    Sub3(&inRect->mVectors[1], &inRect->mVectors[0], &V1);
    Sub3(&inRect->mVectors[3], &inRect->mVectors[2], &V3);
    Sub3(&intersectionPoint, &inRect->mVectors[0], &V4);
    Sub3(&intersectionPoint, &inRect->mVectors[2], &V5);

    Normalize3(&V1);
    Normalize3(&V3);
    Normalize3(&V4);
    Normalize3(&V5);
    
    if ((Dot3(&V1, &V4) > 0) && (Dot3(&V3, &V5) > 0))
    {
        return true;
    }
#endif

    if ((PointInTriangle(&intersectionPoint, &inRect->mVectors[0], &inRect->mVectors[1], &inRect->mVectors[2])) || (PointInTriangle(&intersectionPoint, &inRect->mVectors[0], &inRect->mVectors[2], &inRect->mVectors[3])))
    {
        return true;
    }
    
	return false;
}

bool VerifyRectWinding(Rect3D* inRect)
{
    // Rectangle points are P1, P2, P3, P4.  Corresponding direction vectors are A, B, C
    
    Vector3 A, B, C;
    
    Sub3(&inRect->mVectors[0], &inRect->mVectors[1], &A);
    Sub3(&inRect->mVectors[1], &inRect->mVectors[2], &B);
    Sub3(&inRect->mVectors[2], &inRect->mVectors[3], &C);
    
    Vector3 C1, C2;
    
    Cross3(&A, &B, &C1);
    Cross3(&B, &C, &C2);
    
    Normalize3(&C1);
    Normalize3(&C2);
    
    if (fabsf(1.0f - Dot3(&C1, &C2)) < EPSILON)
    {
        return true;
    }
    
    return false;
}



void ZeroBoundingBox(BoundingBox* inOutBox)
{
    inOutBox->mMinX = 0.0f;
    inOutBox->mMaxX = 0.0f;
    inOutBox->mMinY = 0.0f;
    inOutBox->mMaxY = 0.0f;
    inOutBox->mMinZ = 0.0f;
    inOutBox->mMaxZ = 0.0f;
}

void CopyBoundingBox(BoundingBox* inSource, BoundingBox* outDest)
{
    outDest->mMinX = inSource->mMinX;
    outDest->mMaxX = inSource->mMaxX;
    
    outDest->mMinY = inSource->mMinY;
    outDest->mMaxY = inSource->mMaxY;
    
    outDest->mMinZ = inSource->mMinZ;
    outDest->mMaxZ = inSource->mMaxZ;
}

void BoxFromBoundingBox(BoundingBox* inBoundingBox, Box* outBox)
{
    outBox->mVertices[0].mVector[x] = inBoundingBox->mMinX;
    outBox->mVertices[0].mVector[y] = inBoundingBox->mMaxY;
    outBox->mVertices[0].mVector[z] = inBoundingBox->mMaxZ;
    
    outBox->mVertices[1].mVector[x] = inBoundingBox->mMaxX;
    outBox->mVertices[1].mVector[y] = inBoundingBox->mMaxY;
    outBox->mVertices[1].mVector[z] = inBoundingBox->mMaxZ;

    outBox->mVertices[2].mVector[x] = inBoundingBox->mMaxX;
    outBox->mVertices[2].mVector[y] = inBoundingBox->mMaxY;
    outBox->mVertices[2].mVector[z] = inBoundingBox->mMinZ;
    
    outBox->mVertices[3].mVector[x] = inBoundingBox->mMinX;
    outBox->mVertices[3].mVector[y] = inBoundingBox->mMaxY;
    outBox->mVertices[3].mVector[z] = inBoundingBox->mMinZ;

    outBox->mVertices[4].mVector[x] = inBoundingBox->mMinX;
    outBox->mVertices[4].mVector[y] = inBoundingBox->mMinY;
    outBox->mVertices[4].mVector[z] = inBoundingBox->mMaxZ;
    
    outBox->mVertices[5].mVector[x] = inBoundingBox->mMaxX;
    outBox->mVertices[5].mVector[y] = inBoundingBox->mMinY;
    outBox->mVertices[5].mVector[z] = inBoundingBox->mMaxZ;
    
    outBox->mVertices[6].mVector[x] = inBoundingBox->mMaxX;
    outBox->mVertices[6].mVector[y] = inBoundingBox->mMinY;
    outBox->mVertices[6].mVector[z] = inBoundingBox->mMinZ;

    outBox->mVertices[7].mVector[x] = inBoundingBox->mMinX;
    outBox->mVertices[7].mVector[y] = inBoundingBox->mMinY;
    outBox->mVertices[7].mVector[z] = inBoundingBox->mMinZ;
}

int TopFaceBoxComparator(const void* inLeft, const void* inRight)
{
    int retVal = 0;
    
    Vector3* left = (Vector3*)inLeft;
    Vector3* right = (Vector3*)inRight;
    
    if (left->mVector[y] < right->mVector[y])
    {
        retVal = 1;
    }
    else if (left->mVector[y] > right->mVector[y])
    {
        retVal = -1;
    }
    
    return retVal;
}

void GetTopCenterForBox(Box* inBox, Vector3* outTopCenter)
{
    Vector3 points[4];
    Box box;
    CloneBox(inBox, &box);
    
    qsort(box.mVertices, 8, sizeof(Vector3), TopFaceBoxComparator);
    
    memcpy(points, box.mVertices, sizeof(float) * 4 * 3);
    FaceCenter(points, outTopCenter);
}

// This function will not work if the world space box isn't aligned to the world axes.
// This is a limitation we can live with for now.
void GetTopFaceForBox(Box* inBox, Face* outFace)
{
    Box box;
    CloneBox(inBox, &box);
    
    qsort(box.mVertices, 8, sizeof(Vector3), TopFaceBoxComparator);

    memcpy(outFace->mVertices, box.mVertices, sizeof(float) * 4 * 3);
}

void CloneBox(Box* inSource, Box* outDest)
{
    memcpy(outDest->mVertices, inSource->mVertices, sizeof(float) * 8 * 3);
}

void FaceCenter(Vector3* inPoints, Vector3* outCenter)
{
    // Find out which points make perpendicular lines.
    
    Vector3* pointOne = NULL;
    Vector3* pointTwo = NULL;
    Vector3* pointThree = NULL;
    
    // Choose an arbitrary root point.
    pointOne = &inPoints[0];
    
    // Find two other points that make perpendicular lines.
    
    bool validPoints = false;
    
    for (int i = 1; i < 4; i++)
    {
        for (int j = 1; j < 4; j++)
        {
            if (i != j)
            {
                Vector3 vectorOne, vectorTwo;
                
                Sub3(&inPoints[i], pointOne, &vectorOne);
                Sub3(&inPoints[j], pointOne, &vectorTwo);
                
                if (abs(Dot3(&vectorOne, &vectorTwo)) < EPSILON)
                {
                    pointTwo = &inPoints[i];
                    pointThree = &inPoints[j];
                    validPoints = true;
                    break;
                }
            }
        }
        
        if (validPoints)
        {
            break;
        }
    }
    
    // If we didn't find perpendicular lines on the box face, the box face points are inconsistent
    assert(validPoints);

    if (validPoints)
    {
        Vector3 midPoint1;
        Vector3 midPoint2;
        
        MidPointVec3(pointOne, pointTwo, &midPoint1);
        MidPointVec3(pointOne, pointThree, &midPoint2);
        
        Vector3 slope1;
        Vector3 slope2;
        
        Sub3(pointOne, pointThree, &slope1);
        Sub3(pointOne, pointTwo, &slope2);
        
        // Bounding box top isn't rectangular.  Double check how this bounding box was generated
        assert(abs(Dot3(&slope1, &slope2)) < EPSILON);
        
        // We now have two lines of the form a + bt and c + dt.  Intersection point
        // is the center of the box.
        
        Vector3 aMinusC;
        Vector3 dMinusB;
        
        Sub3(&midPoint1, &midPoint2, &aMinusC);
        Sub3(&slope2, &slope1, &dMinusB);
        
        float t = 0;
        
        for (int i = 0; i < 3; i++)
        {
            if ((abs(aMinusC.mVector[i]) < EPSILON) && (abs(dMinusB.mVector[i]) < EPSILON))
            {
                continue;
            }
            
            // About to divide by zero.  We have an inconsistent bounding box
            assert(abs(dMinusB.mVector[i]) > EPSILON);
            
            t = aMinusC.mVector[i] / dMinusB.mVector[i];
            break;
        }
        
        Mul3(t, &slope1);
        Add3(&midPoint1, &slope1, outCenter);
    }
}

void FaceExtents(Face* inFace, float* outLeft, float* outRight, float* outTop, float* outBottom)
{
    *outLeft = *outRight = inFace->mVertices[0].mVector[x];
    *outTop = *outBottom = inFace->mVertices[0].mVector[z];
    
    for (int i = 1; i <= 3; i++)
    {
        float vx = inFace->mVertices[i].mVector[x];
        float vz = inFace->mVertices[i].mVector[z];
        
        if (vx < *outLeft)
        {
            *outLeft = vx;
        }
        
        if (vx > *outRight)
        {
            *outRight = vx;
        }
        
        if (vz < *outTop)
        {
            *outTop = vz;
        }
        
        if (vz > *outBottom)
        {
            *outBottom = vz;
        }
    }

}

void LoadFromRowMajorArrayOfArrays(Matrix44* inMatrix, float inData[][4])
{
    LoadFromColMajorArrayOfArrays(inMatrix, inData);
    Transpose(inMatrix);
}

void LoadFromColMajorArrayOfArrays(Matrix44* inMatrix, float inData[][4])
{
    for (int row = 0; row < 4; row++)
    {
        memcpy(&inMatrix->mMatrix[4 * row], &inData[row][0], sizeof(float) * 4);
    }
}

void LoadMatrixFromVector4(Vector4* inRowOne, Vector4* inRowTwo, Vector4* inRowThree, Vector4* inRowFour, Matrix44* outMatrix)
{
    Vector4* rows[4] = { inRowOne, inRowTwo, inRowThree, inRowFour };
    
    for (int col = 0; col < 4; col++)
    {
        for (int row = 0; row < 4; row++)
        {
            outMatrix->mMatrix[(col * 4) + row] = rows[row]->mVector[col];
        }
    }
}

void LoadMatrixFromColMajorString(Matrix44* inMatrix, char* inString)
{
    char* strBase = inString;
    
    for (int i = 0; i < 16; i++)
    {
        int charsRead = sscanf(strBase, "%f", &inMatrix->mMatrix[i]);
        assert(charsRead == 1);
        
        while (*strBase != ' ')
        {
            strBase++;
        }
        
        strBase++;
    }
}

void LoadMatrixFromRowMajorString(Matrix44* inMatrix, char* inString)
{
    char* strBase = inString;
    
    for (int i = 0; i < 16; i++)
    {
        int row = i / 4;
        int col = i % 4;
        
        int charsRead = sscanf(strBase, "%f", &inMatrix->mMatrix[(col * 4) + row]);
        assert(charsRead == 1);
        
        while (*strBase != ' ')
        {
            strBase++;
        }
        
        strBase++;
    }
}

void TransformVector4x3(Matrix44* inTransformationMatrix, Vector3* inSourceVector, Vector4* outDestVector)
{
    Vector4 tempSource;
    
    tempSource.mVector[x] = inSourceVector->mVector[x];
    tempSource.mVector[y] = inSourceVector->mVector[y];
    tempSource.mVector[z] = inSourceVector->mVector[z];
    tempSource.mVector[w] = 1.0f;
    
    TransformVector4x4(inTransformationMatrix, &tempSource, outDestVector);
}

void TransformVector4x4(Matrix44* inTransformationMatrix, Vector4* inSourceVector, Vector4* outDestVector)
{
    for (int row = 0; row < 4; row++)
    {
        float sum = 0;
        
        for (int elem = 0; elem < 4; elem++)
        {
            sum += inTransformationMatrix->mMatrix[row + (elem * 4)] * inSourceVector->mVector[elem];
        }
        
        outDestVector->mVector[row] = sum;
    }
}

void ClonePlane(Plane* inSrcPlane, Plane* inDestPlane)
{
    memcpy(inDestPlane, inSrcPlane, sizeof(Plane));
}

void PlaneFromRect3D(Rect3D* inRect, Plane* outPlane)
{
	CloneVec3(&inRect->mVectors[0], &outPlane->mPoint);
	
	Vector3 vecOne, vecTwo;
	Sub3(&inRect->mTopRight, &inRect->mTopLeft, &vecOne);
	Sub3(&inRect->mTopRight, &inRect->mBottomRight, &vecTwo);
	
	Cross3(&vecTwo, &vecOne, &outPlane->mNormal);
	Normalize3(&outPlane->mNormal);
	
	// Ax + By + Cz + D = 0
	// A, B and C are normal
	// substitute any point for x, y and z
	// D = -Ax - By - Cz
	
	outPlane->mDistance =	(-outPlane->mNormal.mVector[x] * inRect->mTopRight.mVector[x]) -
							( outPlane->mNormal.mVector[y] * inRect->mTopRight.mVector[y]) -
							( outPlane->mNormal.mVector[z] * inRect->mTopRight.mVector[z]);
}

void RayIntersectionWithPlane(Vector3* inPoint, Vector3* inDirection, Plane* inPlane, Vector3* outIntersection, float* outT)
{
	float A = inPlane->mNormal.mVector[x];
	float B = inPlane->mNormal.mVector[y];
	float C = inPlane->mNormal.mVector[z];
	float D = inPlane->mDistance;
	
	float x0 = inPoint->mVector[x];
	float y0 = inPoint->mVector[y];
	float z0 = inPoint->mVector[z];
	
	float xd = inDirection->mVector[x];
	float yd = inDirection->mVector[y];
	float zd = inDirection->mVector[z];
	
	*outT = -(A*x0 + B*y0 + C*z0 + D) / (A*xd + B*yd + C*zd);
	
	// Intersection point is inPoint + (inDirection) * t
	
	Vector3 scaledDirectionVector;
	CloneVec3(inDirection, &scaledDirectionVector);
	Scale3(&scaledDirectionVector, *outT);
	
	Add3(inPoint, &scaledDirectionVector, outIntersection);
}

void DistanceFromPointNormal(Plane* inPlane)
{
    inPlane->mDistance = - Dot3(&inPlane->mNormal, &inPlane->mPoint);
}

#ifdef __cplusplus
}
#endif