//
//  PrimitiveLibrary.h
//
//  Copyright Neon Games 2011. All rights reserved.
//

typedef struct
{
    Vector3     mTip;
    Vector3     mDirection;
    float       mLength;
    float       mConeAngleDegrees;
} ConeMeshInputParams;

@interface ConeMesh : NSObject
{
    @public
        float*  mVertexArray;
        u16*    mIndexArray;
        
        u32     mNumVertices;
        u32     mNumIndices;
}

-(ConeMesh*)Init;
-(void)dealloc;

@end


@interface PrimitiveLibrary : NSObject
{
}

+(void)InitDefaultConeMeshParams:(ConeMeshInputParams*)inParams;
+(ConeMesh*)BuildConeMeshWithParams:(ConeMeshInputParams*)inParams;

@end