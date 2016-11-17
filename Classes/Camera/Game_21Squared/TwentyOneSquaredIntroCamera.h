//
//  TwentyOneSquaredIntroCamera.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "CameraState.h"
#import "CameraUVN.h"
#import "Path.h"

@interface TwentyOneSquaredIntroCamera :  CameraState
{
    CameraUVN*  mCamera;
    Path*       mPositionPath;
}

-(void)Startup;
-(void)Resume;

-(void)Suspend;
-(void)Shutdown;

-(CameraUVN*)GetActiveCamera;

@end