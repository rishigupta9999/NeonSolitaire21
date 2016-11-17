//
//  NeonLightShaft.m
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "NeonLightShaft.h"
#import "TextureManager.h"
#import "MeshBuilder.h"

static const char* LIGHT_SHAFT_TEXTURE = "LightShaft.png";
static const float LIGHT_SHAFT_LENGTH = 0.1;
static const float LIGHT_SHAFT_VARIANCE = 0.1;

static const float LIGHT_SHAFT_MIN_TRANSITION_TIME = 0.7;
static const float LIGHT_SHAFT_MAX_TRANSITION_TIME = 1.2;
static const float LIGHT_SHAFT_MIN_MAINTAIN_TIME = 0.5;
static const float LIGHT_SHAFT_MAX_MAINTAIN_TIME = 1.0;

static const float LIGHT_SHAFT_WHITE_COLOR_BIAS = 2.0;
static const float LIGHT_SHAFT_ALPHA_BIAS = 0.1;

static const float LIGHT_SHAFT_TILT_DISPLACEMENT = 2.0;
static const float LIGHT_SHAFT_HEIGHT = 1.5;

@interface LightShaft : NSObject
{
    @public
        Vector3     mBottomCorner;
        Vector3     mTopCorner;
    
        float       mXOffset;
        float       mZOffset;
    
        Path*       mColorPath;
    
        BOOL        mInitialized;
        NSString*   mIdentifier;
}

@property LightShaftOrientation orientation;

-(LightShaft*)init;
-(void)dealloc;

-(void)createLightShaftColorTransition;

-(float)GetRandomColor;
-(float)GetRandomAlpha;

@end


@implementation LightShaft

@synthesize orientation = mOrientation;

-(LightShaft*)init
{
    mOrientation = LIGHTSHAFT_ORIENTATION_WIDTH;
    Set(&mBottomCorner, 0.0, 0.0, 0.0);
    Set(&mTopCorner, 0.0, 0.0, 0.0);
    
    mXOffset = 0.0;
    mZOffset = 0.0;
    
    mColorPath = [[Path alloc] Init];
    
    mInitialized = FALSE;
    
    mIdentifier = [[NSString alloc] initWithFormat:@"%p", self];
    
    return self;
}

-(void)dealloc
{
    [mColorPath release];
    [mIdentifier release];
    
    [super dealloc];
}

-(void)createLightShaftColorTransition
{
    float maintainColor = 0.0;
    float maintainAlpha = 0.0;
    
    if (!mInitialized)
    {
        maintainColor = [self GetRandomColor];
        maintainAlpha = [self GetRandomAlpha];
    }
    else
    {
        Vector3 colorAlphaPair;
        [mColorPath GetValueVec3:&colorAlphaPair];
        
        maintainColor = colorAlphaPair.mVector[x];
        maintainAlpha = colorAlphaPair.mVector[y];
        
        [mColorPath Reset];
    }
    
    float transitionColor = [self GetRandomColor];
    float transitionAlpha = [self GetRandomAlpha];
    
    float maintainTime = RandFloat(LIGHT_SHAFT_MIN_MAINTAIN_TIME, LIGHT_SHAFT_MAX_MAINTAIN_TIME);
    float transitionTime = RandFloat(LIGHT_SHAFT_MIN_TRANSITION_TIME, LIGHT_SHAFT_MAX_TRANSITION_TIME);
    
    [mColorPath AddNodeX:maintainColor y:maintainAlpha z:0.0 atTime:0.0];
    [mColorPath AddNodeX:maintainColor y:maintainAlpha z:0.0 atTime:maintainTime];
    [mColorPath AddNodeX:transitionColor y:transitionAlpha z:0.0 atTime:(maintainTime + transitionTime)];
}

-(float)GetRandomColor
{
    return 1.0;
}

-(float)GetRandomAlpha
{
    float randomAlpha = RandFloat(0.0, 1.0 + LIGHT_SHAFT_ALPHA_BIAS);
    
    if (randomAlpha > 1.0)
    {
        randomAlpha = 1.0;
    }
    
    return randomAlpha;
}

@end


@implementation NeonLightShaft

@synthesize params = mParams;

-(NeonLightShaft*)initWithParams:(NeonLightShaftParams*)inParams
{
    [super Init];
    
    TextureParams textureParams;
    [Texture InitDefaultParams:&textureParams];
    
    textureParams.mTexDataLifetime = TEX_DATA_DISPOSE;
    
    mLightShaftTexture = [[TextureManager GetInstance] TextureWithName:[NSString stringWithUTF8String:LIGHT_SHAFT_TEXTURE] textureParams:&textureParams];
    [mLightShaftTexture retain];
    
    memcpy(&mParams, inParams, sizeof(NeonLightShaftParams));
    
    [self SetupLightShafts];
    
    mMeshBuilder = [[MeshBuilder alloc] Init];
    
    return self;
}

-(void)dealloc
{
    [mLightShaftTexture release];
    [mLightShaftEntries release];
    
    [mMeshBuilder release];
    
    [super dealloc];
}

+(void)InitDefaultParams:(NeonLightShaftParams*)outParams
{
    outParams->mWidth = 1.0f;
    outParams->mDepth = 1.0f;
    outParams->mHeight = LIGHT_SHAFT_HEIGHT;
}

-(void)SetupLightShafts
{
    mLightShaftEntries = [[NSMutableArray alloc] init];
    
    [self SetupLightShaftsWithOrientation:LIGHTSHAFT_ORIENTATION_WIDTH x:0.0 z:-mParams.mDepth  length:mParams.mWidth];
    [self SetupLightShaftsWithOrientation:LIGHTSHAFT_ORIENTATION_WIDTH x:0.0 z:0.0              length:mParams.mWidth];
    
    [self SetupLightShaftsWithOrientation:LIGHTSHAFT_ORIENTATION_DEPTH x:0.0            z:0.0   length:mParams.mDepth];
    [self SetupLightShaftsWithOrientation:LIGHTSHAFT_ORIENTATION_DEPTH x:mParams.mWidth z:0.0   length:mParams.mDepth];
}

-(void)SetupLightShaftsWithOrientation:(LightShaftOrientation)inOrientation x:(float)inX z:(float)inZ length:(float)inLength
{
    int numShafts = inLength / LIGHT_SHAFT_LENGTH;
    
    float curX = inX;
    float curZ = inZ;
    
    float xOffset = 0.0, zOffset = 0.0;
    
    switch(inOrientation)
    {
        case LIGHTSHAFT_ORIENTATION_WIDTH:
        {
            if (inZ == 0.0)
            {
                zOffset = LIGHT_SHAFT_TILT_DISPLACEMENT;
            }
            else
            {
                zOffset = -LIGHT_SHAFT_TILT_DISPLACEMENT;
            }
            
            break;
        }
        
        case LIGHTSHAFT_ORIENTATION_DEPTH:
        {
            if (inX == 0.0)
            {
                xOffset = -LIGHT_SHAFT_TILT_DISPLACEMENT;
            }
            else
            {
                xOffset = LIGHT_SHAFT_TILT_DISPLACEMENT;
            }
            
            break;
        }
    }
    
    for (int i = 0; i < numShafts; i++)
    {
        LightShaft* lightShaft = [[LightShaft alloc] init];
        
        lightShaft.orientation = inOrientation;
        Set(&lightShaft->mBottomCorner, curX, 0.0, curZ);
        
        switch(inOrientation)
        {
            case LIGHTSHAFT_ORIENTATION_WIDTH:
            {
                curX += LIGHT_SHAFT_LENGTH;
                break;
            }
            
            case LIGHTSHAFT_ORIENTATION_DEPTH:
            {
                curZ -= LIGHT_SHAFT_LENGTH;
                break;
            }
        }
        
        float height = RandFloat(mParams.mHeight - LIGHT_SHAFT_VARIANCE, mParams.mHeight + LIGHT_SHAFT_VARIANCE);
        
        Set(&lightShaft->mTopCorner, curX, height, curZ);
        
        lightShaft->mXOffset = xOffset;
        lightShaft->mZOffset = zOffset;
        
        [lightShaft createLightShaftColorTransition];
        
        lightShaft->mInitialized = TRUE;
        
        [mLightShaftEntries addObject:lightShaft];
        [lightShaft release];
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    for (LightShaft* curLightShaft in mLightShaftEntries)
    {
        [curLightShaft->mColorPath Update:inTimeStep];
        
        if ([curLightShaft->mColorPath Finished])
        {
            [curLightShaft createLightShaftColorTransition];
        }
    }
    
    [super Update:inTimeStep];
}

-(void)Draw
{
    GLState glState;
    
    SaveGLState(&glState);
    
    NeonGLDisable(GL_DEPTH_TEST);
    
    float regularVertex[12];
    float color[16];
    
    float texCoord[8] = {   0.0, 1.0,
                            0.0, 0.0,
                            1.0, 1.0,
                            1.0, 0.0 };
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    for (LightShaft* curLightShaft in mLightShaftEntries)
    {
        Vector3 colorAlphaPair;
        [curLightShaft->mColorPath GetValueVec3:&colorAlphaPair];
        
        for (int i = 0; i < 4; i++)
        {
            color[i*4]     = colorAlphaPair.mVector[x];
            color[i*4 +1]  = colorAlphaPair.mVector[x];
            color[i*4 +2]  = colorAlphaPair.mVector[x];
            color[i*4 +3]  = colorAlphaPair.mVector[y] * mAlpha;
        }

        regularVertex[0] = curLightShaft->mBottomCorner.mVector[x];
        regularVertex[1] = 0.0;
        regularVertex[2] = curLightShaft->mBottomCorner.mVector[z];
        
        regularVertex[3] = curLightShaft->mBottomCorner.mVector[x];
        regularVertex[4] = curLightShaft->mTopCorner.mVector[y];
        regularVertex[5] = curLightShaft->mBottomCorner.mVector[z];
        
        regularVertex[6] = curLightShaft->mTopCorner.mVector[x];
        regularVertex[7] = 0.0;
        regularVertex[8] = curLightShaft->mTopCorner.mVector[z];
        
        regularVertex[9]  = curLightShaft->mTopCorner.mVector[x];
        regularVertex[10] = curLightShaft->mTopCorner.mVector[y];
        regularVertex[11] = curLightShaft->mTopCorner.mVector[z];
        
        switch(curLightShaft.orientation)
        {
            case LIGHTSHAFT_ORIENTATION_WIDTH:
            {
                regularVertex[5] += curLightShaft->mZOffset;
                regularVertex[11] += curLightShaft->mZOffset;
                break;
            }
            
            case LIGHTSHAFT_ORIENTATION_DEPTH:
            {
                regularVertex[3] += curLightShaft->mXOffset;
                regularVertex[9] += curLightShaft->mXOffset;
                break;
            }
        }
        
        [mMeshBuilder StartMeshWithOwner:self identifier:[curLightShaft->mIdentifier UTF8String]];
        
        [mMeshBuilder SetTexture:mLightShaftTexture];
        [mMeshBuilder SetPositionPointer:(u8*)regularVertex numComponents:3 numVertices:4 copyData:TRUE];
        [mMeshBuilder SetTexcoordPointer:(u8*)texCoord numComponents:2 numVertices:4 copyData:TRUE];
        [mMeshBuilder SetColorPointer:(u8*)color numComponents:4 numVertices:4 copyData:TRUE];
        [mMeshBuilder SetNumVertices:4];
        [mMeshBuilder SetPrimitiveType:GL_TRIANGLE_STRIP];
        
        [mMeshBuilder EndMesh];
    }
    
    [mMeshBuilder FinishPass];
    
    RestoreGLState(&glState);
}

@end