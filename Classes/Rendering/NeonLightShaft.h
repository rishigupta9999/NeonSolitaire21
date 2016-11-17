//
//  NeonLightShaft.h
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "GameObject.h"
#import "MeshBuilder.h"

typedef struct
{
    float mWidth;
    float mDepth;
    float mHeight;
} NeonLightShaftParams;

typedef enum
{
    LIGHTSHAFT_ORIENTATION_WIDTH,
    LIGHTSHAFT_ORIENTATION_DEPTH
} LightShaftOrientation;

@interface NeonLightShaft : GameObject
{
    Texture*        mLightShaftTexture;
    NSMutableArray* mLightShaftEntries;
    MeshBuilder*    mMeshBuilder;
}

@property NeonLightShaftParams params;

-(NeonLightShaft*)initWithParams:(NeonLightShaftParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(NeonLightShaftParams*)outParams;

-(void)SetupLightShafts;
-(void)SetupLightShaftsWithOrientation:(LightShaftOrientation)inOrientation x:(float)inX z:(float)inZ length:(float)inLength;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Draw;

@end