//
//  CompanionSelectCamera.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "CameraState.h"
#import "CameraUVN.h"
#import "Path.h"

@interface CompanionSelectCamera :  CameraState<MessageChannelListener>
{
    CameraUVN*  mCamera;
    Path*       mPositionPath;
    Path*       mLookAtPath;
    
    CFTimeInterval  mStateTime;
    BOOL            mPlayerHidden;
}

-(void)Startup;
-(void)Resume;

-(void)Suspend;
-(void)Shutdown;

-(CameraUVN*)GetActiveCamera;

-(void)ProcessMessage:(Message*)inMsg;
-(void)Update:(CFAbsoluteTime)inTimeStep;

@end