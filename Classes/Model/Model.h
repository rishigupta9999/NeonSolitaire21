//
//  Model.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "Texture.h"
#import "NeonMath.h"
#import "Skeleton.h"

@class GameObject;

typedef struct
{
    float   u;
    float   v;
    
}   TexCoord;

typedef struct
{
    float   coords[3];
    u8      normalIndex;
    
}   IndexedVertex;

typedef struct
{
    Vector4 mColor;
} ModelRenderState;

@interface Model : NSObject
{
    @public
        BOOL        mAutoloadTextures;
        Texture*    mTexture;
        BoundingBox mBoundingBox;
        Skeleton*   mSkeleton;
        GameObject* mOwnerObject;
        
        BOOL        mGlowEnabled;
        float       mGlowAmount;
    
        ModelRenderState     mRenderStateOverride;
        BOOL                 mUseOverride;
    
        // The clip plane is in object space.  That means the modelview transform will be applied to it before clipping occurs.
        // So for world space clip planes, we'll either need an additional flag, or pre-multiply mClipPlane by the inverse modelview matrix
        Plane       mClipPlane;
        BOOL        mClipPlaneEnabled;
}

-(void)Init;
+(void)InitDefaultRenderState:(ModelRenderState*)outRenderState;

-(void)SetAutoloadTextures:(BOOL)inAutoloadTextures;
-(BOOL)GetAutoloadTextures;

-(void)SetTexture:(Texture*)inTexture;
-(void)Remove;
-(void)dealloc;

-(void)Draw;
-(void)Update:(u32)inFrameTime;
-(void)GetBoundingBox:(BoundingBox*)outBoundingBox;

-(void)BindSkeleton:(Skeleton*)inSkeleton;
-(void)BindSkeletonWithFilename:(NSString*)inFilename;
-(Skeleton*)GetSkeleton;

-(void)SetGlowEnabled:(BOOL)inEnabled;

-(void)SetRenderStateOverride:(ModelRenderState*)renderState;
-(void)ClearRenderStateOverride;

-(void)SetClipPlaneEnabled:(BOOL)inEnabled;
-(void)SetClipPlane:(Plane*)inPlane;

@end