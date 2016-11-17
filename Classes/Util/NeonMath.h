//
//  NeonMath.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#pragma once

#include <stdbool.h>

extern const float EPSILON;
extern const float SMALL_EPSILON;

typedef struct
{
    float mStart;
    float mLength;
} Range;

enum
{
    x = 0,
    y,
    z,
    w
};

typedef struct
{
    float   mVector[2];
} Vector2;

typedef struct
{
    float   mVector[3];
} Vector3;

typedef struct
{
    float   mVector[4];
} Vector4;

typedef struct
{
    float mXMin;
    float mXMax;
    float mYMin;
    float mYMax;
} Rect2D;

typedef struct
{
	union
	{
		struct
		{
			Vector3 mTopLeft;
			Vector3 mTopRight;
			Vector3 mBottomLeft;
			Vector3 mBottomRight;
		};
		
		Vector3	mVectors[4];
	};
} Rect3D;

typedef struct
{
    Vector3 mPoint;
    Vector3 mNormal;
	float	mDistance;	// D in the "Ax + By + Cz + D = 0" form of the equation
} Plane;

typedef struct
{
    float   mMinX;
    float   mMaxX;
    float   mMinY;
    float   mMaxY;
    float   mMinZ;
    float   mMaxZ;
} BoundingBox;

// Stick to a common convention for Boxes.  Let's say:
// The first 4 vertices are the one face of the box in a clockwise orientation.
// The second 4 vertices are the face on the opposite side of the box, also in a clockwise orientation.
//
// Note, clockwise is in the same sense for both faces.  So if we're looking at a box from the side, this is how the vertices
// should be specified (excuse the poor ASCII art).  1 2 3 4 is the "top" and 5 6 7 8 is the "bottom".
//
//      1
//                  2
//
//      4 
//                  3
//
//
//
//
//      5
//                  6
//
//
//      8
//                  7
//
//      It is up to the user of the class to ensure the vertices actually form a box (eg: 1 2 is parallel to 3 4 and
//      is perpendicular to 1 5, etc).

typedef struct
{
    Vector3     mVertices[8];
} Box;

typedef struct
{
    Vector3     mVertices[4];
} Face;


// Note: Despite the somewhat confusing nature of it, our matrices will be stored in column major order
// to match OpenGL.  That is to say:
//
// | a b c d |
// | e f g h |
// | i j k l |
// | m n o p |
//
// will be represented in mMatrix as [a, e, i, m, b, f, j, n, c, g, k, o, d, h, l p]

typedef struct
{
    float   mMatrix[16];
} Matrix44;

#ifdef __cplusplus
extern "C"
{
#endif

#pragma mark Scalar

float DegreesToRadians(float inDegrees);
float RadiansToDegrees(float inRadians);

float ClampFloat(float inValue, float inLower, float inUpper);
int   ClampInt(int inValue, int inLower, int inUpper);
unsigned int ClampUInt(unsigned int inValue, unsigned int inLower, unsigned int inUpper);
float LClampFloat(float inValue, float inLower);
int   LClampInt(float inValue, float inLower);

float FloorToMultipleFloat(float inValue, float inMultiplier);

bool RangesIntersect(Range* inLeft, Range* inRight);

int  RoundUpPOT(int inValue);
int  RoundDownPOT(int inValue);

float RandFloat(float inLower, float inUpper);

double Sinc(double x);
double Bessel0(double x);
double Kaiser(double alpha, double half_width, double x);

float LerpFloat(float inLeft, float inRight, float inBlend);
float ApproximateCubicBezierParameter(float atX, float P0_X, float C0_X, float C1_X, float P1_X );

float Min3(float inX, float inY, float inZ);
float Min3WithComponent(float inX, float inY, float inZ, unsigned int* outComponent);

void DistributeItemsOverRange(float inRangeWidth, float inNumItems, float inItemWidth, float* outStart, float* outStep);

#pragma mark Vector
void Set(Vector3* inVector, float inX, float inY, float inZ);
void SetVec2(Vector2* inVector, float inX, float inY);
void SetVec4(Vector4* inVector, float inX, float inY, float inZ, float inW);
Vector4* SetVec4From3(Vector4* inVector, Vector3* inVector3, float inW);
Vector3* SetVec3From4(Vector3* inVector, Vector4* inVector4);

void ZeroVec3(Vector3* inVector);
void ZeroVec4(Vector4* inVector);

void CloneVec2(Vector2* inSource, Vector2* inDest);
void CloneVec3(Vector3* inSource, Vector3* inDest);
void CloneVec4(Vector4* inSource, Vector4* inDest);

void Add3(Vector3* inFirst, Vector3* inSecond, Vector3* outResult);
void Add4(Vector4* inFirst, Vector4* inSecond, Vector4* outResult);

void Sub2(Vector2* inFirst, Vector2* inSecond, Vector2* outResult);
void Sub3(Vector3* inFirst, Vector3* inSecond, Vector3* outResult);
void Sub4(Vector4* inFirst, Vector4* inSecond, Vector4* outResult);

void Scale3(Vector3* inVec, float inScale);
void Scale4(Vector4* inVec, float inScale);

float Length2(Vector2* inVector);

void Mul3(float inMultiplier, Vector3* inOutVector);

void Normalize3(Vector3* inOutVector);
void Cross3(Vector3* inFirst, Vector3* inSecond, Vector3* outResult);
float Dot3(Vector3* inFirst, Vector3* inSecond);
float Length3(Vector3* inVector);
bool Equal(Vector3* inLeft, Vector3* inRight);

void Normalize4(Vector4* inOutVector);
float Length4(Vector4* inVector);

void MidPointVec3(Vector3* inFirst, Vector3* inSecond, Vector3* outMidPoint);

void LerpVec3(Vector3* inLeft, Vector3* inRight, float inBlend, Vector3* outResult);
void PerpVec3(Vector3* inSource, Vector3* inDest);

#pragma mark Matrix
void PrintMatrix44(Matrix44* inMatrix, int inNumTabs);

void LoadFromRowMajorArrayOfArrays(Matrix44* inMatrix, float inData[][4]);
void LoadFromColMajorArrayOfArrays(Matrix44* inMatrix, float inData[][4]);

void LoadMatrixFromVector4(Vector4* inRowOne, Vector4* inRowTwo, Vector4* inRowThree, Vector4* inRowFour, Matrix44* outMatrix);
void LoadMatrixFromColMajorString(Matrix44* inMatrix, char* inString);
void LoadMatrixFromRowMajorString(Matrix44* inMatrix, char* inString);

void TransformVector4x3(Matrix44* inTransformationMatrix, Vector3* inSourceVector, Vector4* outDestVector);
void TransformVector4x4(Matrix44* inTransformationMatrix, Vector4* inSourceVector, Vector4* outDestVector);

void CloneMatrix44(Matrix44* inSrc, Matrix44* inDest);

void SetIdentity(Matrix44* inMatrix);
void Transpose(Matrix44* inMatrix);

void DivideRow(Matrix44* inMatrix, int inRow, float inDivisor);
void SubtractRow(Matrix44* inMatrix, int inLeftRow, int inRightRow, float inRightRowScale, int inDestRow);

bool Inverse(Matrix44* inMatrix, Matrix44* outInverse);
void InverseTranspose(Matrix44* inMatrix, Matrix44* outInverseTranspose);
void InverseView(Matrix44* inMatrix, Matrix44* outInverse);
void InverseProjection(Matrix44* inMatrix, Matrix44* outInverse);

void MatrixMultiply(Matrix44* inLeft, Matrix44* inRight, Matrix44* outResult);

void FlipMatrixY(Matrix44* inOutMatrix);
void FlipMatrixZ(Matrix44* inOutMatrix);

void GenerateRotationMatrix(float inAngle, float inX, float inY, float inZ, Matrix44* outMatrix);

// Generates a Matrix which performs a rotation about a line (as opposed to GenerateRotationMatrix() which generates a rotation about
// a vector, which is basically a line passing through the origin).  inPoint is any point on the line, inDirection is the direction
// vector of the line.
void GenerateRotationAroundLine(float inAngle, Vector3* inPoint, Vector3* inDirection, Matrix44* outMatrix);

void GenerateTranslationMatrix(float inTranslateX, float inTranslateY, float inTranslateZ, Matrix44* outMatrix);
void GenerateTranslationMatrixFromVector(Vector3* inTranslationVector, Matrix44* outMatrix);
void GenerateScaleMatrix(float inScaleX, float inScaleY, float inScaleZ, Matrix44* outMatrix);

void GenerateVectorToVectorTransform(Vector3* inOrig, Vector3* inDest, Matrix44* outTransform);

#pragma mark Rect
void NeonUnionRect(Rect2D* inBase, Rect2D* inAdd);
bool PointInRect3D(Vector3* inPoint, Rect3D* inRect);
bool RayIntersectsRect3D(Vector3* inPoint, Vector3* inDirection, Rect3D* inRect);
bool VerifyRectWinding(Rect3D* inRect);

#pragma mark BoundingBox
void ZeroBoundingBox(BoundingBox* inOutBox);
void CopyBoundingBox(BoundingBox* inSource, BoundingBox* outDest);

void BoxFromBoundingBox(BoundingBox* inBoundingBox, Box* outBox);
void CloneBox(Box* inSource, Box* outDest);

void GetTopCenterForBox(Box* inBoundingBox, Vector3* outTopCenter);
void GetTopFaceForBox(Box* inBoundingBox, Face* outFace);

void FaceCenter(Vector3* inPoints, Vector3* outCenter);
void FaceExtents(Face* inFace, float* outLeft, float* outRight, float* outTop, float* outBottom);

#pragma mark Plane
void ClonePlane(Plane* inSrcPlane, Plane* inDestPlane);
void PlaneFromRect3D(Rect3D* inRect, Plane* outPlane);
void RayIntersectionWithPlane(Vector3* inPoint, Vector3* inDirection, Plane* inPlane, Vector3* outIntersection, float* outT);
void DistanceFromPointNormal(Plane* inPlane);

#ifdef __cplusplus
}
#endif

#define max(x, y)   ( (x > y) ? (x) : (y) )
#define min(x, y)   ( (x < y) ? (x) : (y) )
