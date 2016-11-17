//
//  DebugCameraState.m
//  Neon21
//
//  Copyright Neon Games 2010 All rights reserved.
//

#import "DebugCamera.h"
#import "CameraUVN.h"

#import "DebugManager.h"

#import "TextureButton.h"
#import "GameObjectManager.h"

#import "PositionLookAtNavigator.h"
                                                                
@implementation DebugCamera

-(DebugCamera*)InitWithCamera:(CameraUVN*)inCamera
{
    mCamera = inCamera;
    [mCamera retain];
    
    PositionLookAtNavigatorParams params;
    [PositionLookAtNavigator InitDefaultParams:&params];
    
    params.mTargetPosition = &inCamera->mPosition;
    params.mTargetLookAt = &inCamera->mLookAt;
    params.mTargetFovDegrees = &inCamera->mFov;
    
    mCameraNavigator = [(PositionLookAtNavigator*)[PositionLookAtNavigator alloc] InitWithParams:&params];
    
    [mCamera SetDebugCameraAttached:self];
     
    return self;
}

-(void)dealloc
{
    [mCameraNavigator release];
    [mCamera release];
    
    [mCamera SetDebugCameraAttached:NULL];
    
    [super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [mCameraNavigator Update:inTimeStep];
}

-(void)DrawOrtho
{
    [mCameraNavigator DrawOrtho];
}

@end