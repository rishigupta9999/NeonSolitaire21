//
//  Run21CelebrationCamera.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "CameraState.h"
#import "CameraUVN.h"
#import "MessageChannel.h"

#import "Path.h"

@interface Run21CelebrationCamera :  CameraState<MessageChannelListener>
{
    CameraUVN*   mCamera;
    
    Path*        mPositionPath[3];
    Path*        mLookAtPath;
    Path*        mFovPath;
    
    u32          mFrameDelay;
}

-(void)Startup;
-(void)Resume;

-(void)Suspend;
-(void)Shutdown;

-(void)dealloc;

-(CameraUVN*)GetActiveCamera;

-(void)ProcessMessage:(Message*)inMsg;

-(void)AddPositionToPath:(Vector3*)inPosition cp1:(Vector3*)inControlPointOne cp2:(Vector3*)inControlPointTwo
                            cp1Time:(float)inCp1Time cp2Time:(float)inCp2Time atTime:(float)inTime;

-(void)GetPositionFromPath:(Vector3*)outPosition;

@end