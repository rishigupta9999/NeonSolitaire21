//
//  PrimitiveLibrary.m
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "PrimitiveLibrary.h"

#define CONE_MESH_NUM_CIRCLE_POINTS (36)
#define CONE_MESH_NUM_VERTICES      (37)

// Number of triangles is the number of points on the circle minus 1.
// Eg: If the circle had two points, that would be one triangle.
// Every incremental point adds an additional triangle.
#define CONE_MESH_NUM_LINES           (CONE_MESH_NUM_CIRCLE_POINTS)
#define CONE_MESH_NUM_INDICES         (CONE_MESH_NUM_LINES * 2)

@implementation ConeMesh

-(ConeMesh*)Init
{
    mNumVertices = 0;
    mNumIndices = 0;
    
    return self;
}

-(void)dealloc
{
    free(mVertexArray);
    free(mIndexArray);
    
    [super dealloc];
}

@end

@implementation PrimitiveLibrary

+(void)InitDefaultConeMeshParams:(ConeMeshInputParams*)inParams
{
    Set(&inParams->mTip, 0.0, 0.0, 0.0);
    Set(&inParams->mDirection, 0.0, 0.0, 1.0);
    inParams->mLength = 1.0;
    inParams->mConeAngleDegrees = 20.0f;
}

+(ConeMesh*)BuildConeMeshWithParams:(ConeMeshInputParams*)inParams
{
    // Construct a plane representing the endpoint (wider end) of the cone.  It is on this plane we will
    // "trace" out a circle that makes up one end of the cone.
    
    // Construct the vector that takes us from the start point to the center of the circle that makes
    // the end of the cone.
    Vector3 scaledDirection;
    
    CloneVec3(&inParams->mDirection, &scaledDirection);
    Normalize3(&scaledDirection);
    Scale3(&scaledDirection, inParams->mLength);
    
    Vector3 endPoint;
    Add3(&inParams->mTip, &scaledDirection, &endPoint);
    
    // Now store the end point and normal in the Plane structure
    Plane endPlane;
    
    CloneVec3(&endPoint, &endPlane.mPoint);
    CloneVec3(&inParams->mDirection, &endPlane.mNormal);
    
    // mDirection points from the tip to the end point.  We want the normal in the opposite direction
    // (pointing away from the plane towards the tip)
    Scale3(&endPlane.mNormal, -1.0f);
    Normalize3(&endPlane.mNormal);
    
    // Radius depends on cone angle and length
    float radius = inParams->mLength * tanf(DegreesToRadians(inParams->mConeAngleDegrees) / 2.0f);
    
    // Choose any normal to the direction vector.  This added to endPoint, will be the circle.
    Vector3 radiusNormal = { -inParams->mDirection.mVector[z], 0.0f, inParams->mDirection.mVector[x] };
    
    Normalize3(&radiusNormal);
    Scale3(&radiusNormal, radius);
    
    Vector3 circlePoint;
    Add3(&endPoint, &radiusNormal, &circlePoint);
    
    ConeMesh* coneMesh = [(ConeMesh*)[ConeMesh alloc] Init];
    [coneMesh autorelease];
    
    coneMesh->mNumVertices = CONE_MESH_NUM_VERTICES;
    coneMesh->mNumIndices = CONE_MESH_NUM_INDICES;
    coneMesh->mVertexArray = (float*)malloc(sizeof(float) * 3 * CONE_MESH_NUM_VERTICES);
    coneMesh->mIndexArray = (u16*)malloc(sizeof(u16) * CONE_MESH_NUM_INDICES);
    
    int degrees = 0;
    
    Matrix44 transformationMatrix;
    
    // Put the tip in the zero-th vertex
    memcpy(&coneMesh->mVertexArray[0], &inParams->mTip, sizeof(float) * 3);
    
    // Copy circle vertices into successive vertex positions
    for (int vert = 1; vert < CONE_MESH_NUM_VERTICES; vert++)
    {
        GenerateRotationAroundLine(degrees, &inParams->mTip, &endPlane.mNormal, &transformationMatrix);
        
        Vector4 newCirclePoint;
        TransformVector4x3(&transformationMatrix, &circlePoint, &newCirclePoint);
        
        memcpy(&coneMesh->mVertexArray[3 * vert], &newCirclePoint, sizeof(float) * 3);
        
        degrees += 10;
    }
    
    for (int line = 0; line < CONE_MESH_NUM_LINES; line++)
    {
        coneMesh->mIndexArray[(line * 2) + 0] = 0;
        coneMesh->mIndexArray[(line * 2) + 1] = line + 1;
    }
    
    return coneMesh;
}

@end