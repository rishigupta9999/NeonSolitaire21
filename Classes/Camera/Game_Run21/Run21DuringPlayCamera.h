//
//  Run21DuringPlayCamera.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "CameraState.h"
#import "CameraUVN.h"
#import "MessageChannel.h"

#import "Path.h"

@interface Run21DuringPlayCameraParams : NSObject
{
}
@property BOOL InterpolateFromPrevious;

-(Run21DuringPlayCameraParams*)init;

@end

@interface Run21DuringPlayCamera :  CameraState<MessageChannelListener>
{
    CameraUVN*  mCamera;
    Path*       mPositionPath;
    Path*       mLookAtPath;
    Path*       mFovPath;
    
    int         mCameraIndex;
}

-(void)Startup;
-(void)Resume;

-(void)Suspend;
-(void)Shutdown;

-(void)dealloc;

-(CameraUVN*)GetActiveCamera;

-(void)ProcessMessage:(Message*)inMsg;

+(void)CalculateCameraPosition:(Vector3*)outPosition lookAt:(Vector3*)outLookAt fov:(float*)outFov;

@end