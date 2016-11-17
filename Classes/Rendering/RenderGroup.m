//
//  RenderGroup.m
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "RenderGroup.h"
#import "GameObject.h"
#import "Framebuffer.h"
#import "CameraStateMachine.h"
#import "GameObjectCollection.h"
#import "ModelManager.h"
#import "GameStateMgr.h"

@implementation RenderGroup

-(RenderGroup*)InitWithParams:(RenderGroupParams*)inParams
{
	memcpy(&mParams, inParams, sizeof(RenderGroupParams));
	
	[mParams.mFramebuffer retain];
	[mParams.mCameraStateMachine retain];
	[mParams.mGameObjectCollection retain];
    
    mOwningState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];
    
    mDebugName = NULL;
    mDebugCounter = 0;
    mDebugCaptureEnabled = FALSE;
    
    SetVec2(&mScale, 1.0, 1.0);
	
	return self;
}

-(void)dealloc
{
	[mParams.mFramebuffer release];
	[mParams.mCameraStateMachine release];
	[mParams.mGameObjectCollection release];
    
    [mDebugName release];
	
	[super dealloc];
}

+(void)InitDefaultParams:(RenderGroupParams*)outParams
{
	outParams->mFramebuffer = NULL;
	outParams->mCameraStateMachine = NULL;
    outParams->mGameObjectCollection = NULL;
    outParams->mListener = NULL;
    SetColorFloat(&outParams->mClearColor, 1.0f, 0.0f, 0.0f, 1.0f);
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	[mParams.mCameraStateMachine Update:inTimeStep];
	[mParams.mGameObjectCollection Update:inTimeStep];
    
    [mParams.mListener RenderGroupUpdateComplete:self timeStep:inTimeStep];
}

-(void)Draw
{	
	GLint viewport[4];
    NeonGLGetIntegerv(GL_VIEWPORT, viewport);

	NeonGLViewport(0, 0, [mParams.mFramebuffer GetWidth], [mParams.mFramebuffer GetHeight]);

	GLint oldFb;
	NeonGLGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &oldFb);
	
	[mParams.mFramebuffer Bind];
		
	NeonGLMatrixMode(GL_PROJECTION);
    glPushMatrix();
    
	Matrix44 projectionMatrix;
	[mParams.mCameraStateMachine GetProjectionMatrix:&projectionMatrix];
	
	glLoadMatrixf(projectionMatrix.mMatrix);
	
	NeonGLDisable(GL_DEPTH_TEST);
	NeonGLClearColor(GetRedFloat(&mParams.mClearColor), GetGreenFloat(&mParams.mClearColor), GetBlueFloat(&mParams.mClearColor), GetAlphaFloat(&mParams.mClearColor));
	glClear(GL_COLOR_BUFFER_BIT);
    
    NeonGLMatrixMode(GL_MODELVIEW);
    glPushMatrix();
	{
		Matrix44 viewMatrix;
		[mParams.mCameraStateMachine GetViewMatrix:&viewMatrix];
		
        Matrix44 scaleMatrix;
        GenerateScaleMatrix(mScale.mVector[0], mScale.mVector[1], 1.0, &scaleMatrix);
        
		glLoadMatrixf(viewMatrix.mMatrix);
        glMultMatrixf(scaleMatrix.mMatrix);
		
		int size = [mParams.mGameObjectCollection GetSize];

		for (int i = 0; i < size; i++)
		{        
			GameObject*  curObject = (GameObject*)([mParams.mGameObjectCollection GetObject:i]);
            
            NSAssert((curObject->mOrtho == TRUE), @"Only ortho objects are supported in RenderGroups at the moment");

			[[ModelManager GetInstance] DrawObject:curObject];
		}
	}
	glPopMatrix();
    
    if (mDebugCaptureEnabled)
    {
        mDebugCounter++;
        
        if (mDebugCounter <= 20)
        {
            if (mDebugName != NULL)
            {
                SaveScreen([NSString stringWithFormat:@"Offscreen_%@_%d.png", mDebugName, mDebugCounter]);
            }
            else
            {
                SaveScreen([NSString stringWithFormat:@"Offscreen_%p_%d.png", self, mDebugCounter]);
            }
        }
    }

	NeonGLEnable(GL_DEPTH_TEST);
	
    NeonGLMatrixMode(GL_PROJECTION);
    glPopMatrix();
	
	NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, oldFb);
	
	NeonGLViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
    
    [mParams.mListener RenderGroupDrawComplete:self];
}

-(Framebuffer*)GetFramebuffer
{
	return mParams.mFramebuffer;
}

-(CameraStateMachine*)GetCameraStateMachine
{
	return mParams.mCameraStateMachine;
}

-(GameObjectCollection*)GetGameObjectCollection
{
	return mParams.mGameObjectCollection;
}

-(GameState*)GetOwningState
{
    return mOwningState;
}

-(BOOL)ShouldUpdate
{
    return [self ShouldDraw];
}

-(BOOL)ShouldDraw
{
    GameState* currentState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];

    BOOL drawState = (mOwningState == currentState) &&
                            ([[ModelManager GetInstance] GetDrawingMode] == ModelManagerDrawingMode_ActiveGameState);
                            
    drawState |= [[ModelManager GetInstance] GetDrawingMode] != ModelManagerDrawingMode_ActiveGameState;
    
    return drawState;
}

-(void)SetDebugName:(const NSString*)inString
{
    mDebugName = [[NSString alloc] initWithString:(NSString*)inString];
}

-(void)SetDebugCaptureEnabled:(BOOL)inEnabled
{
    mDebugCaptureEnabled = inEnabled;
    mDebugCounter = 0;
}

-(void)SetScaleX:(float)inX y:(float)inY
{
    mScale.mVector[x] = inX;
    mScale.mVector[y] = inY;
}

@end