//
//  Run21IntroCamera.h
//  Neon21
//
//  Copyright Neon Games 201. All rights reserved.
//

#import "CameraState.h"
#import "CameraUVN.h"
#import "Path.h"

@interface Run21IntroCamera :  CameraState<MessageChannelListener>
{
    CameraUVN*  mCamera;
    Path*       mPositionPath;
	Path*       mLookAtPath;
    Path*       mFovPath;
}

-(void)Startup;
-(void)Resume;

-(void)Suspend;
-(void)Shutdown;

-(void)dealloc;

-(CameraUVN*)GetActiveCamera;

-(void)ProcessMessage:(Message*)inMsg;

@end