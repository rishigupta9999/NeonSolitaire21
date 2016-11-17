//
//  RenderGroup.h
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "Color.h"

@class Framebuffer;
@class CameraStateMachine;
@class GameObjectCollection;
@class GameState;
@class RenderGroup;

@protocol RenderGroupCallback

-(void)RenderGroupDrawComplete:(RenderGroup*)inRenderGroup;
-(void)RenderGroupUpdateComplete:(RenderGroup*)inRenderGroup timeStep:(CFTimeInterval)inTimeStep;

@end

typedef struct
{
	Framebuffer*                    mFramebuffer;
	CameraStateMachine*             mCameraStateMachine;
	GameObjectCollection*           mGameObjectCollection;
    NSObject<RenderGroupCallback>*  mListener;
    Color                           mClearColor;
} RenderGroupParams;

@interface RenderGroup : NSObject
{
	RenderGroupParams	mParams;
    GameState*          mOwningState;
    
    BOOL                mDebugCaptureEnabled;
    NSString*           mDebugName;
    int                 mDebugCounter;
    
    Vector2             mScale;
    
}

-(RenderGroup*)InitWithParams:(RenderGroupParams*)inParams;
-(void)dealloc;

+(void)InitDefaultParams:(RenderGroupParams*)outParams;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Draw;

-(Framebuffer*)GetFramebuffer;
-(CameraStateMachine*)GetCameraStateMachine;
-(GameObjectCollection*)GetGameObjectCollection;

-(GameState*)GetOwningState;

-(BOOL)ShouldUpdate;
-(BOOL)ShouldDraw;

-(void)SetDebugCaptureEnabled:(BOOL)inEnabled;
-(void)SetDebugName:(const NSString*)inString;

-(void)SetScaleX:(float)inX y:(float)inY;

@end