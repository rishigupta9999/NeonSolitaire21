//
//  CompanionRenderManager.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "CompanionManager.h"
#import "NeonMath.h"
#import "Flow.h"

typedef struct
{
    CompanionID     mCompanionID;
    const char*     mModelFilename;
    const char*     mSkeletonFilename;
    const char*     mTextureFilename;
    float           mScale;
    bool            mClockwiseWinding;
} CompanionRenderInfo;

typedef struct
{
    Vector3             mPositions[COMPANION_POSITION_MAX];
    Vector3             mOrientations[COMPANION_POSITION_MAX];
} CompanionPositionInfo;

@interface CompanionRenderManager : NSObject
{
}

-(CompanionRenderManager*)init;
-(void)dealloc;

+(void)CreateInstance;
+(void)DestroyInstance;
+(CompanionRenderManager*)GetInstance;

-(CompanionRenderInfo*)getCompanionRenderInfo:(CompanionID)inCompanionID;
-(void)getCompanionPlacement:(CompanionPosition)inPosition forId:(CompanionID)inCompanionId position:(Vector3*)outPosition orientation:(Vector3*)outOrientation;

#if defined(NEON_RUN_21)
-(void)getCompanionClipPlane:(Plane*)outPlane forId:(CompanionID)inCompanionId;
#endif

@end