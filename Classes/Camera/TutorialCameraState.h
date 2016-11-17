//
//  TutorialCameraState.m
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "CameraState.h"

@class CameraUVN;
@class Path;

@interface TutorialCameraStateParams : NSObject
{
    @public
        BOOL    mInterpolateIn;
        Vector3 mPosition;
        Vector3 mLookAt;
        float   mFov;
}

-(TutorialCameraStateParams*)Init;

@end

@interface TutorialCameraState : CameraState
{
    CameraUVN*  mCamera;
    Path*       mPositionPath;
    Path*       mLookAtPath;
    Path*       mFovPath;
}

-(void)Startup;
-(void)Resume;

-(void)Shutdown;
-(void)Suspend;

-(void)SetPosition:(Vector3*)inPosition time:(float)inTime;
-(void)SetLookAt:(Vector3*)inLookAt time:(float)inTime;
-(void)SetFov:(float)inFov time:(float)inTime;

-(Camera*)GetActiveCamera;

-(BOOL)GetFinished;

@end