//
//  Run21CelebrationCamera.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//


#import "CameraStateMgr.h"
#import "Run21CelebrationCamera.h"

#import "CameraUVN.h"
#import "GameObjectManager.h"
#import "MiniGameTableEntity.h"
#import "CompanionManager.h"

#import "PlayerHand.h"

#import "GameStateMgr.h"

#import "Run21DuringPlayCamera.h"
#import "Event.h"

#define CELEBRATION_FRAME_DELAY (5)

#define RUN21_CELEBRATION_CAMERA_OFFSET (6.0f)
#define RUN21_CELEBRATION_CAMERA_OFFSET_PHASE_TWO (RUN21_CELEBRATION_CAMERA_OFFSET * 2.2f)
#define RUN21_CELEBRATION_CAMERA_YOFFSET (2.0f)
#define RUN21_CELEBRATION_CAMERA_YOFFSET_PHASE_TWO (2.25f)

#define CELEBRATION_FRAME_DELAY (5)
#define CELEBRATION_TIME        (1.0f)
#define CAMERA_FADE_TIME        (1.0f)

@implementation Run21CelebrationCamera

-(void)Startup
{
    // Create a basic UVN camera
    mCamera = [(CameraUVN*)[CameraUVN alloc] Init];
                
    Vector3 lastPosition;
    Vector3 lastLookAt;
    float   lastHFov;
    
    [[CameraStateMgr GetInstance] GetPosition:&lastPosition];
    [[CameraStateMgr GetInstance] GetLookAt:&lastLookAt];
    [[CameraStateMgr GetInstance] GetHFov:&lastHFov];
    
    for (int i = 0; i < 3; i++)
    {
        mPositionPath[i] = [(Path*)[Path alloc] Init];
    }
    
    mLookAtPath = [(Path*)[Path alloc] Init];
    mFovPath = [(Path*)[Path alloc] Init];
    
    // Starting point is where the camera last was
    [self AddPositionToPath:&lastPosition cp1:&lastPosition cp2:&lastPosition cp1Time:0.0 cp2Time:(CELEBRATION_TIME / 2.0f) atTime:0.0];
        
    // Ending point is just in front of the Polly
    Companion* player = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_PLAYER];
        
    CompanionEntity* playerEntity = player->mEntity;
    Skeleton* playerSkeleton = [[playerEntity GetPuppet] GetSkeleton];
    Joint* playerNeckJoint = [playerSkeleton GetJointAtIndex:JOINT_NECK];
    
    Vector3 playerNeckLocalPosition;
    [playerNeckJoint GetLocalSpacePosition:&playerNeckLocalPosition];
    
    Vector3 playerNeckWorldPosition;
    [playerEntity TransformLocalToWorld:&playerNeckLocalPosition result:&playerNeckWorldPosition];
    
    playerNeckWorldPosition.mVector[y] += RUN21_CELEBRATION_CAMERA_YOFFSET;
    playerNeckWorldPosition.mVector[z] -= RUN21_CELEBRATION_CAMERA_OFFSET;
    
    // Control points will be some distance to the side of the line connecting dealerNeckWorldPosition and lastPosition.
    // We go 1/3rd and 2/3rd of the way along this line.  Then move laterally by a constant amount.
    
    Vector3 cp[2];
    
    // 1) Generate a vector pointing from lastPosition to dealerNeckWorldPosition
    Sub3(&playerNeckWorldPosition, &lastPosition, &cp[0]);
    CloneVec3(&cp[0], &cp[1]);
    
    // 2) Scale the vectors by 1/3rd and 2/3rd
    Scale3(&cp[0], 1.0f / 3.0f);
    Scale3(&cp[1], 2.0f / 3.0f);
    
    // 3) Add these to lastPosition and laterally translate
    for (int i = 0; i < 2; i++)
    {
        float direction = (2.0f * ((float)(arc4random_uniform(2)))) - 1.0f;
        float lateralTranslateAmount = direction * RandFloat(5.0f, 15.0f);
        
        Vector3 lateralTranslate = { { lateralTranslateAmount, 0.0, 0.0 } };
        
        Add3(&lastPosition, &cp[i], &cp[i]);
        Add3(&lateralTranslate, &cp[i], &cp[i]);
    }
    
    [self AddPositionToPath:&playerNeckWorldPosition cp1:&cp[0] cp2:&cp[1]
            cp1Time:(CELEBRATION_TIME / 3.0f) cp2Time:((2.0 * CELEBRATION_TIME) / 3.0) atTime:1.0];
                        
    [self AddPositionToPath:&playerNeckWorldPosition cp1:&playerNeckWorldPosition cp2:&playerNeckWorldPosition
            cp1Time:CELEBRATION_TIME cp2Time:CELEBRATION_TIME atTime:CELEBRATION_TIME];
            
    [self AddPositionToPath:&playerNeckWorldPosition cp1:&playerNeckWorldPosition cp2:&playerNeckWorldPosition
            cp1Time:CELEBRATION_TIME * 2.0f cp2Time:CELEBRATION_TIME * 2.0f atTime:2.0];
    
    // After pause, move back behind Polly's head
    playerNeckWorldPosition.mVector[z] += RUN21_CELEBRATION_CAMERA_OFFSET_PHASE_TWO;
    [self AddPositionToPath:&playerNeckWorldPosition cp1:&cp[0] cp2:&cp[1]
            cp1Time:CELEBRATION_TIME * 3.0f cp2Time:CELEBRATION_TIME * 3.0f atTime:3.0];
    
    [playerEntity TransformLocalToWorld:&playerNeckLocalPosition result:&playerNeckWorldPosition];

    // Starting look-at is where the camera was last looking
    [mLookAtPath AddNodeVec3:&lastLookAt atTime:0.0];
    [mLookAtPath AddNodeVec3:&playerNeckWorldPosition atTime:CELEBRATION_TIME];
    [mLookAtPath AddNodeVec3:&playerNeckWorldPosition atTime:(CELEBRATION_TIME * 2.0f)];
    
    playerNeckWorldPosition.mVector[y] += RUN21_CELEBRATION_CAMERA_YOFFSET_PHASE_TWO;

    [mLookAtPath AddNodeVec3:&playerNeckWorldPosition atTime:CELEBRATION_TIME * 3.0f];
    
    float destHFov;
    [mCamera GetHFov:&destHFov];
    
    [mFovPath AddNodeScalar:lastHFov atTime:0.0f];
    [mFovPath AddNodeScalar:destHFov atTime:1.0f];

    mFrameDelay = CELEBRATION_FRAME_DELAY;
    
    [[[GameStateMgr GetInstance] GetMessageChannel] AddListener:self];
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_BEGIN_CELEBRATION_CAMERA withData:NULL];
}

-(void)Resume
{
}

-(void)Suspend
{
}

-(void)Shutdown
{
    [[[GameStateMgr GetInstance] GetMessageChannel] RemoveListener:self];
}

-(void)dealloc
{
    [mCamera release];
    
    for (int i = 0; i < 3; i++)
    {
        [mPositionPath[i] release];
    }

    [mLookAtPath release];
    [mFovPath release];
    
    [super dealloc];
}

-(CameraUVN*)GetActiveCamera
{
    return mCamera;
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_RUN21_SCORING_COMPLETE:
        {
            [[CameraStateMgr GetInstance] Pop];
            break;
        }
    }
}

-(void)Update:(CFAbsoluteTime)inTimeStep
{
    Vector3 curPosition;
    
    [self GetPositionFromPath:&curPosition];
    CloneVec3(&curPosition, &mCamera->mPosition);
    
    Vector3 curLookAt;
    
    [mLookAtPath GetValueVec3:&curLookAt];
    CloneVec3(&curLookAt, &mCamera->mLookAt);
    
    [mFovPath GetValueScalar:&mCamera->mFov];
    
    if (mFrameDelay > 0)
    {
        mFrameDelay--;
        return;
    }

    for (int i = 0; i < 3; i++)
    {
        [mPositionPath[i] Update:inTimeStep];
    }
    
    [mLookAtPath Update:inTimeStep];
}

-(void)AddPositionToPath:(Vector3*)inPosition cp1:(Vector3*)inControlPointOne cp2:(Vector3*)inControlPointTwo
                            cp1Time:(float)inCp1Time cp2Time:(float)inCp2Time atTime:(float)inTime
{
    for (int i = 0; i < 3; i++)
    {
        PathNodeParams pathNodeParams;
        [Path InitPathNodeParams:&pathNodeParams];
        
        pathNodeParams.mInterpolationMethod = PATH_INTERPOLATION_BEZIER;
        pathNodeParams.mTime = inTime;
        
        pathNodeParams.mPathTypeSpecificData.mBezierData.mInTangent.mVector[x] = inTime - 0.5;
        pathNodeParams.mPathTypeSpecificData.mBezierData.mInTangent.mVector[y] = inControlPointOne->mVector[i];
        
        pathNodeParams.mPathTypeSpecificData.mBezierData.mOutTangent.mVector[x] = inTime + 0.5;
        pathNodeParams.mPathTypeSpecificData.mBezierData.mOutTangent.mVector[y] = inControlPointTwo->mVector[i];
        
        [mPositionPath[i] AddNodeScalar:inPosition->mVector[i] withParams:&pathNodeParams];
    }
}

-(void)GetPositionFromPath:(Vector3*)outPosition
{
    for (int i = 0; i < 3; i++)
    {
        [mPositionPath[i] GetValueScalar:&outPosition->mVector[i]];
    }
}

@end