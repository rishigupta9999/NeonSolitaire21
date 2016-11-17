//
//  DebugCameraState.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

@class CameraUVN;
@class PositionLookAtNavigator;

@interface DebugCamera : NSObject
{
    CameraUVN*                  mCamera;
    PositionLookAtNavigator*    mCameraNavigator;
}

-(DebugCamera*)InitWithCamera:(CameraUVN*)inCamera;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;

@end