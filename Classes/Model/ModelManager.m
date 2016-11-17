//
//  ModelManager.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "ModelManager.h"
#import "ResourceManager.h"
#import "GameObjectManager.h"
#import "GameStateMgr.h"

#import "ReflectiveModel.h"
#import "LightManager.h"

#import "CameraStateMgr.h"

#import "UIGroup.h"
#import "AnimationDebugState.h"
#import "EAGLView.h"

static ModelManager*    sInstance = NULL;

static RenderBin sRenderBins[RENDERBIN_NUM] = {  {-2, FALSE },                          // UI Displayed underneath everything
                                                 {-1, FALSE },                          // Reflective Objects
                                                 { RENDERBIN_DEFAULT_PRIORITY, FALSE }, // Default
                                                 { 1, FALSE },                          // Cards
                                                 { 3, FALSE },                          // X-Ray Card
                                                 { 2, FALSE },                          // Companions
                                                 { 3, FALSE },                          // High priority UI
                                                 { 4, FALSE },                          // The x-ray light shaft effect
												 { 5, FALSE }};                         // Things that must appear above the fader, special high priority bin

static const char* sShowBoundingBoxes = "Show Bounding Boxes";
static const char* sAnimationDebugger = "Animation Debugger";

@implementation ModelManager

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"ModelManager should not be created at this point");
    
    sInstance = [ModelManager alloc];
    [sInstance Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Trying to destroy ModelManager but none has been created");
    
    [sInstance release];
    sInstance = NULL;
}

+(ModelManager*)GetInstance
{
    return sInstance;
}

+(void)InitDefaultParams:(ModelParams*)outParams
{
    outParams->mFilename = NULL;
    outParams->mOwnerObject = NULL;
    outParams->mReflective = FALSE;
}

+(void)InitDefaultDrawParams:(ModelManagerDrawParams*)outParams
{
    outParams->mGameObjectManager = NULL;
    outParams->mPriority = 0;
    outParams->mCondition = 0;
    outParams->mOrtho = FALSE;
    outParams->mProjected = FALSE;
}

-(void)Init
{
    [[DebugManager GetInstance] RegisterDebugMenuItem:[NSString stringWithUTF8String:sShowBoundingBoxes] WithCallback:self];
    [[DebugManager GetInstance] RegisterDebugMenuItem:[NSString stringWithUTF8String:sAnimationDebugger] WithCallback:self];
    
    mShowBoundingBoxes = FALSE;
    mDrawingEnabled = TRUE;
    mDrawingMode = ModelManagerDrawingMode_All;
}

-(void)dealloc
{
    [[DebugManager GetInstance] UnregisterDebugMenuItem:[NSString stringWithUTF8String:sShowBoundingBoxes]];
    [[DebugManager GetInstance] UnregisterDebugMenuItem:[NSString stringWithUTF8String:sAnimationDebugger]];
    [super dealloc];
}

-(void)DebugMenuItemPressed:(NSString*)inName
{
    if ([inName compare:[NSString stringWithUTF8String:sShowBoundingBoxes]] == NSOrderedSame)
    {
        mShowBoundingBoxes = !mShowBoundingBoxes;
    }
    else if ([inName compare:[NSString stringWithUTF8String:sAnimationDebugger]] == NSOrderedSame)
    {
        [[DebugManager GetInstance] ToggleDebugGameState:[AnimationDebugState class]];
    }
}

-(Model*)ModelWithParams:(ModelParams*)inParams
{
    NSNumber*   resourceHandle = [[ResourceManager GetInstance] LoadAssetWithName:inParams->mFilename];
    NSData*     modelData = [[ResourceManager GetInstance] GetDataForHandle:resourceHandle];
    Model*      retModel = NULL;
    
    if ([[inParams->mFilename pathExtension] caseInsensitiveCompare:@"STM"] == NSOrderedSame)
    {
        if (inParams->mReflective)
        {
            retModel = [(ReflectiveModel*)[ReflectiveModel alloc] InitWithData:modelData];
            
            // Reflective objects need to be rendered first, so if we want a GameObject rendered later, we have a problem
            NSAssert(inParams->mOwnerObject->mRenderBinId == RENDERBIN_BASE, @"Reflective objects must be using the base render bin");
            
            inParams->mOwnerObject->mRenderBinId = RENDERBIN_REFLECTIVE;
        }
        else
        {
            retModel = [(SimpleModel*)[SimpleModel alloc] InitWithData:modelData];
        }
    }
    else
    {
        NSAssert(FALSE, @"Unknown model/params type\n");
    }
    
    [retModel autorelease];
    
    [[ResourceManager GetInstance] UnloadAssetWithHandle:resourceHandle];
    
    retModel->mOwnerObject = inParams->mOwnerObject;
    
    return retModel;
}

-(Model*)ModelWithName:(NSString*)inName owner:(GameObject*)inOwner
{
    ModelParams modelParams;
    [ModelManager InitDefaultParams:&modelParams];
    
    modelParams.mFilename = inName;
    modelParams.mOwnerObject = inOwner;
    
    return [self ModelWithParams:&modelParams];
}

-(void)SetupWorldCamera
{    
    Matrix44 projMatrix;
    
    NeonGLMatrixMode(GL_PROJECTION);
    glPushMatrix();
    
    [[CameraStateMgr GetInstance] GetProjectionMatrix:&projMatrix];
    glLoadMatrixf(projMatrix.mMatrix);
    
    NeonGLMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
	
	Matrix44 modelViewMatrix;
	[self GetModelManagerViewMatrix:&modelViewMatrix];
	glLoadMatrixf(modelViewMatrix.mMatrix);
    
    NeonGLError();
}

-(void)TeardownWorldCamera
{
    NeonGLMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    
    NeonGLMatrixMode(GL_PROJECTION);
    glPopMatrix();
}

-(void)SetupUICamera
{
    [self SetupViewport:MODELMANAGER_VIEWPORT_UI];
    
	float halfBaseWidth = (float)GetBaseWidth() / 2.0f;
	float halfBaseHeight = (float)GetBaseHeight() / 2.0f;
		
    NeonGLMatrixMode(GL_PROJECTION);
    glPushMatrix();
    
    glLoadIdentity();
        
	glOrthof(   -halfBaseHeight, halfBaseHeight,
                -halfBaseWidth, halfBaseWidth,
                -1.0f, 1.0f );
    
    NeonGLMatrixMode(GL_MODELVIEW);
	glPushMatrix();
    glLoadIdentity();
    
    NeonGLError();

#if LANDSCAPE_MODE    
    glRotatef(-90, 0.0f, 0.0f, 1.0f);
#endif

#if LANDSCAPE_MODE
	glTranslatef(-halfBaseWidth, halfBaseHeight, 0.0f);
#else
    glTranslatef(-halfBaseHeight, halfBaseWidth, 0.0f);
#endif
	glScalef(1.0, -1.0, 1.0);
}

-(void)TeardownUICamera
{
    NeonGLMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    
    NeonGLMatrixMode(GL_PROJECTION);
    glPopMatrix();
    
    if (GetDevicePad())
    {
        NeonGLViewport(0, 0, [GetEAGLView() GetBackingWidth], [GetEAGLView() GetBackingHeight]);
    }
}

-(void)SetupOrthoCamera
{
    int screenWidth = GetBaseWidth();
    int screenHeight = GetBaseHeight();
    
    [self SetupViewport:MODELMANAGER_VIEWPORT_ORTHO];
    
	float halfBaseWidth = (float)screenWidth / 2.0f;
	float halfBaseHeight = (float)screenHeight / 2.0f;
		
    NeonGLMatrixMode(GL_PROJECTION);
    glPushMatrix();
    
    glLoadIdentity();
        
	glOrthof(   -halfBaseHeight, halfBaseHeight,
                -halfBaseWidth, halfBaseWidth,
                -1.0f, 1.0f );
    
    NeonGLMatrixMode(GL_MODELVIEW);
	glPushMatrix();
    glLoadIdentity();
    
    NeonGLError();

#if LANDSCAPE_MODE    
    glRotatef(-90, 0.0f, 0.0f, 1.0f);
#endif

#if LANDSCAPE_MODE
	glTranslatef(-halfBaseWidth, halfBaseHeight, 0.0f);
#else
    glTranslatef(-halfBaseHeight, halfBaseWidth, 0.0f);
#endif
	glScalef(1.0, -1.0, 1.0);
}

-(void)TeardownOrthoCamera
{
    NeonGLMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    
    NeonGLMatrixMode(GL_PROJECTION);
    glPopMatrix();
    
    if (GetDevicePad())
    {
        NeonGLViewport(0, 0, [GetEAGLView() GetBackingWidth], [GetEAGLView() GetBackingHeight]);
    }
}

-(void)SetupViewport:(ModelManagerViewport)inViewportType
{
    switch(inViewportType)
    {
        case MODELMANAGER_VIEWPORT_ORTHO:
        {
            if (GetDevicePad() || GetDeviceiPhoneTall())
            {
                int screenWidth = GetScreenAbsoluteWidth() * GetScreenScaleFactor();
                int screenHeight = GetScreenAbsoluteHeight() * GetScreenScaleFactor();
                
                NeonGLViewport(0, 0, screenHeight, screenWidth);
            }

            break;
        }
        
        case MODELMANAGER_VIEWPORT_UI:
        {
            if (GetDevicePad() || GetDeviceiPhoneTall())
            {
                // We're only rendering to an interior 640 x 960 region on the iPad (for UI)
                
                int screenWidth = GetScreenAbsoluteWidth() * GetScreenScaleFactor();
                int screenHeight = GetScreenAbsoluteHeight() * GetScreenScaleFactor();
                
                int renderWidth = GetBaseWidth() * GetContentScaleFactor() * GetScreenScaleFactor();
                int renderHeight = GetBaseHeight() * GetContentScaleFactor() * GetScreenScaleFactor();
                
                if (GetDeviceiPhoneTall())
                {
                    renderWidth = GetBaseWidth() * GetContentScaleFactor();
                    renderHeight = GetBaseHeight() * GetContentScaleFactor();
                }
                
                NeonGLViewport( ((screenHeight - renderHeight) / 2),
                            ((screenWidth - renderWidth) / 2),
                            renderHeight, renderWidth   );
            }

            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unsupported viewport configuration");
            break;
        }
    }
}

-(void)TeardownViewport:(ModelManagerViewport)inViewportType
{
    switch(inViewportType)
    {
        case MODELMANAGER_VIEWPORT_ORTHO:
        {
            NeonGLMatrixMode(GL_MODELVIEW);
            glPopMatrix();
            
            NeonGLMatrixMode(GL_PROJECTION);
            glPopMatrix();
            
            if (GetDevicePad())
            {
                NeonGLViewport(0, 0, [GetEAGLView() GetBackingWidth], [GetEAGLView() GetBackingHeight]);
            }

            break;
        }
        
        case MODELMANAGER_VIEWPORT_UI:
        {
            NeonGLMatrixMode(GL_MODELVIEW);
            glPopMatrix();
            
            NeonGLMatrixMode(GL_PROJECTION);
            glPopMatrix();
            
            if (GetDevicePad())
            {
                NeonGLViewport(0, 0, [GetEAGLView() GetBackingWidth], [GetEAGLView() GetBackingHeight]);
            }

            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unsupported viewport configuration");
            break;
        }
    }
}

-(void)Draw
{    
    [self DrawWithParams:NULL];
}

-(void)DrawWithParams:(ModelManagerDrawParams*)inParams
{
    if (!mDrawingEnabled)
    {
        return;
    }

    if (inParams->mOrtho)
    {
        [self SetupUICamera];
        
        NeonGLDisable(GL_DEPTH_TEST);
    }
    else
    {
        if (inParams->mProjected)
        {
            glDepthMask(GL_FALSE);
        }
        
        [self SetupWorldCamera];
        [[LightManager GetInstance] UpdateLights];
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    }
            
    int size = [[GameObjectManager GetInstance] GetSize];
    
    for (int i = 0; i < size; i++)
    {
        GameObject* curObject = (GameObject*)([[GameObjectManager GetInstance] GetObject:i]);
        
        if (inParams != NULL)
        {
            if (![self ShouldDrawObject:curObject withParams:inParams])
            {
                continue;
            }
        }
        
        [self DrawObject:curObject];
    }
    
    if (inParams->mOrtho)
    {
        NeonGLEnable(GL_DEPTH_TEST);
	
        [self TeardownUICamera];
    }
    else
    {
        if (inParams->mProjected)
        {
        	glDepthMask(GL_TRUE);
        }
        
        [self TeardownWorldCamera];
    }
    
    NeonGLError(); 
}

-(void)DrawObject:(GameObject*)inObject
{
    if ([inObject isKindOfClass:[GameObjectBatch class]])
    {
        if ((inObject->mOrtho) || ([inObject GetProjected]))
        {
            [inObject DrawOrtho];
        }
        else
        {
            [inObject Draw];
        }
        
        return;
    }
    
    RenderStateParams renderStateParams;
    [GameObject InitDefaultRenderStateParams:&renderStateParams];

    [inObject SetupRenderState:&renderStateParams];
    
    NeonGLMatrixMode(GL_MODELVIEW);
    glPushMatrix();

    Matrix44 ltwTransform;
    
    [inObject GetLocalToWorldTransform:&ltwTransform];
    
    glMultMatrixf(ltwTransform.mMatrix);
    
    if ((inObject->mOrtho) || ([inObject GetProjected]))
    {
        [inObject DrawOrtho];
    }
    else
    {
        [inObject Draw];
    }
    
    NeonGLError();
            
    if (mShowBoundingBoxes)
    {
        [inObject DrawBoundingBox];
    }
    
    [inObject TeardownRenderState:&renderStateParams];
    
    NeonGLMatrixMode(GL_MODELVIEW);
    glPopMatrix();
}

-(void)DrawModel:(Model*)inModel ownerObject:(GameObject*)inOwnerObject withTransform:(Matrix44*)inTransform renderPassType:(RenderPassType)inPassType
{
    RenderStateParams renderStateParams;
    [GameObject InitDefaultRenderStateParams:&renderStateParams];
    
    renderStateParams.mRenderPassType = inPassType;
    
    if ((!inOwnerObject->mOrtho) && ([inOwnerObject GetVisible]))
    {
        if ([inOwnerObject class] == [GameObjectBatch class])
        {
            NSAssert(FALSE, @"GameObjectBatch isn't supported here");
            return;
        }
        
        [inOwnerObject SetupRenderState:&renderStateParams];
        
        NeonGLMatrixMode(GL_MODELVIEW);
        glPushMatrix();

        Matrix44 ltwTransform;
        
        [inOwnerObject GetLocalToWorldTransform:&ltwTransform];
        
        if (inTransform != NULL)
        {
            glMultMatrixf(inTransform->mMatrix);
        }
        
        glMultMatrixf(ltwTransform.mMatrix);
                                
        NeonGLError();
        [inModel Draw];
        NeonGLError();
                
        if (mShowBoundingBoxes)
        {
            [inOwnerObject DrawBoundingBox];
        }
        
        [inOwnerObject TeardownRenderState:&renderStateParams];
        
        NeonGLMatrixMode(GL_MODELVIEW);
        glPopMatrix();  // Model transformation matrix
    }
}

-(RenderBin*)GetRenderBinWithId:(RenderBinId)inId
{
    NSAssert(inId < RENDERBIN_NUM, @"Invalid RenderBinId specified");
    
    return &sRenderBins[inId];
}

-(void)SetDrawingEnabled:(BOOL)inEnabled
{
    mDrawingEnabled = inEnabled;
}

-(void)GetModelManagerViewMatrix:(Matrix44*)outMatrix
{
	SetIdentity(outMatrix);
	
#if LANDSCAPE_MODE
    GenerateRotationMatrix(-90, 0.0f, 0.0f, 1.0f, outMatrix);
#endif
    
    Matrix44 viewMatrix;
    
    [[CameraStateMgr GetInstance] GetViewMatrix:&viewMatrix];
	
	MatrixMultiply(outMatrix, &viewMatrix, outMatrix);
}

-(void)SetDrawingMode:(ModelManagerDrawingMode)inDrawingMode
{
    mDrawingMode = inDrawingMode;
}

-(ModelManagerDrawingMode)GetDrawingMode
{
    return mDrawingMode;
}

-(BOOL)ShouldDrawObject:(GameObject*)inObject withParams:(ModelManagerDrawParams*)inParams
{
    if (![inObject GetVisible])
    {
        return FALSE;
    }
    
    if (    ([inObject GetOwningState] != (GameState*)[[GameStateMgr GetInstance] GetActiveState])
            && (mDrawingMode == ModelManagerDrawingMode_ActiveGameState)    )
    {
        return FALSE;
    }

    if (inParams->mProjected != [inObject GetProjected])
    {
        return FALSE;
    }
    
    if ((inParams->mOrtho != inObject->mOrtho) && (!inParams->mProjected))
    {
        return FALSE;
    }
    
    switch(inParams->mCondition)
    {
        case ModelManagerCondition_GreaterThan:
        {
            if (sRenderBins[inObject->mRenderBinId].mPriority <= inParams->mPriority)
            {
                return FALSE;
            }
            
            break;
        }
        
        case ModelManagerCondition_LessThanEquals:
        {
            if (sRenderBins[inObject->mRenderBinId].mPriority > inParams->mPriority)
            {
                return FALSE;
            }

            break;
        }
        
        case ModelManagerCondition_Equals:
        {
            if (sRenderBins[inObject->mRenderBinId].mPriority != inParams->mPriority)
            {
                return FALSE;
            }
            
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown condition");
            break;
        }
    }
    
    return TRUE;
}

-(int)GetPriorityForRenderBin:(RenderBinId)inRenderBinId
{
    return sRenderBins[inRenderBinId].mPriority;
}

@end