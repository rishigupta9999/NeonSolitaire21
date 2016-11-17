//
//  TwentyOneSquaredDuringPlayCamera.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "CameraState.h"
#import "CameraUVN.h"
#import "MessageChannel.h"

#import "Path.h"

@interface TwentyOneSquaredDuringPlayCamera :  CameraState<MessageChannelListener>
{
    CameraUVN*  mCamera;
    Path*       mPositionPath;
    Path*       mLookAtPath;
}

-(void)Startup;
-(void)Resume;

-(void)Suspend;
-(void)Shutdown;

-(void)dealloc;

-(CameraUVN*)GetActiveCamera;

-(void)ProcessMessage:(Message*)inMsg;

+(void)CalculateCameraPosition:(Vector3*)outPosition lookAt:(Vector3*)outLookAt;

@end