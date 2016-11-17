//
//  TextureButton.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "TextureButton.h"
#import "TextureManager.h"
#import "TextTextureBuilder.h"
#import "UIGroup.h"
#import "CameraStateMgr.h"

static const char BUTTON_GRAPHIC_IDENTIFIER[] = "ButtonGraphic_Identifier";
static const char BUTTON_TEXT_IDENTIFIER[] = "ButtonText_Identifier";
static const char BUTTON_COLOR_IDENTIFIER[] = "ButtonColor_Identifier";

@implementation TextureButton

-(TextureButton*)InitWithParams:(TextureButtonParams*)inParams
{
    [super InitWithUIGroup:inParams->mUIGroup];
    
    memcpy(&mParams, inParams, sizeof(TextureButtonParams));
    
    UIObjectTextureLoadParams textureLoadParams;
    
    [UIObject InitDefaultTextureLoadParams:&textureLoadParams];
    
    NSAssert( (((!mParams.mBoundingBoxCollision) && ( (mParams.mBoundingBoxBorderSize.mVector[x] == 0.0f) && (mParams.mBoundingBoxBorderSize.mVector[y] == 0.0f) )) ||
               (mParams.mBoundingBoxCollision)), @"Can only specify a bounding box border size if we're using bounding box collisions" );
    
    NSAssert( (mParams.mBoundingBoxBorderSize.mVector[0] == 0.0f) && (mParams.mBoundingBoxBorderSize.mVector[1] == 0.0f), @"Bounding box border size is currently unsupported" );
    
    if (inParams->mButtonTexBaseName != NULL)
    {
        mParams.mButtonTexBaseName = [[NSString alloc] initWithString:inParams->mButtonTexBaseName];
        
        textureLoadParams.mTexDataLifetime = TEX_DATA_RETAIN;
        textureLoadParams.mTextureName = mParams.mButtonTexBaseName;
        
        mBaseTexture = [self LoadTextureWithParams:&textureLoadParams];
        [mBaseTexture retain];
    }
    else
    {
        mParams.mButtonTexBaseName = NULL;
        mBaseTexture = NULL;
    }
    
    if (inParams->mButtonTexHighlightedName != NULL)
    {
        mParams.mButtonTexHighlightedName = [[NSString alloc] initWithString:inParams->mButtonTexHighlightedName];
        
        textureLoadParams.mTexDataLifetime = TEX_DATA_DISPOSE;
        textureLoadParams.mTextureName = mParams.mButtonTexHighlightedName;
        
        mHighlightedTexture = [self LoadTextureWithParams:&textureLoadParams];
        [mHighlightedTexture retain];
    }
    else
    {
        mParams.mButtonTexHighlightedName = NULL;
        mHighlightedTexture = NULL;
    }
	
	if (inParams->mButtonTexDisabledName != NULL)
    {
        mParams.mButtonTexDisabledName = [[NSString alloc] initWithString:inParams->mButtonTexDisabledName];
        
        textureLoadParams.mTexDataLifetime = TEX_DATA_DISPOSE;
        textureLoadParams.mTextureName = mParams.mButtonTexDisabledName;
        
        mDisabledTexture = [self LoadTextureWithParams:&textureLoadParams];
        [mDisabledTexture retain];
    }
    else
    {
        mParams.mButtonTexDisabledName = NULL;
        mDisabledTexture = mBaseTexture;
        [mDisabledTexture retain];
    }
	

    if (inParams->mButtonText != NULL)
    {
        [inParams->mButtonText retain];
        mParams.mButtonText = inParams->mButtonText;
        
        TextTextureParams params;
        [TextTextureBuilder InitDefaultParams:&params];
        
        params.mFontName = [NSString stringWithString:[[LocalizationManager GetInstance] GetFontForType:inParams->mFontType]];
        params.mPointSize = inParams->mFontSize;
        params.mString = inParams->mButtonText;
        params.mColor = inParams->mFontColor;
        params.mStrokeColor = inParams->mFontStrokeColor;
        params.mStrokeSize = inParams->mFontStrokeSize;
        
        params.mTextureAtlas = (inParams->mUIGroup == NULL) ? (NULL) : ([inParams->mUIGroup GetTextureAtlas]);
        params.mPremultipliedAlpha = TRUE;
        
        mTextTexture = [[TextTextureBuilder GetInstance] GenerateTextureWithParams:&params];
        [self RegisterTexture:mTextTexture];
        
        mTextStartX = params.mStartX;
        mTextStartY = params.mStartY;
        mTextEndX = params.mEndX;
        mTextEndY = params.mEndY;
        
        [mTextTexture retain];
    }
    else
    {
        mTextTexture = NULL;
        
        mTextStartX = 0;
        mTextStartY = 0;
        mTextEndX = 0;
        mTextEndY = 0;
    }
    
    return self;
}

-(void)dealloc
{
    [mParams.mButtonText release];
    
    [mBaseTexture release];
    [mHighlightedTexture release];
	[mDisabledTexture release];
    [mTextTexture release];
    
    [mParams.mButtonTexBaseName release];
    [mParams.mButtonTexHighlightedName release];
	[mParams.mButtonTexDisabledName release];
    
    [super dealloc];
}

+(void)InitDefaultParams:(TextureButtonParams*)inParams;
{
    inParams->mButtonTexBaseName = NULL;
    inParams->mButtonTexHighlightedName = NULL;
    inParams->mButtonText = NULL;
	inParams->mButtonTexDisabledName = NULL;

    inParams->mBoundingBoxCollision = FALSE;
    SetVec2(&inParams->mBoundingBoxBorderSize, 0.0f, 0.0f);

    
    inParams->mFontSize = 24;
    inParams->mFontType = NEON_FONT_STYLISH;
    inParams->mFontColor = 0;
    inParams->mFontStrokeColor = 0;
    inParams->mFontStrokeSize = 0;
    
    inParams->mUIGroup = NULL;
    
    SetColorFloat(&inParams->mColor, 1.0f, 1.0f, 1.0f, 1.0f);
    SetAbsolutePlacement(&inParams->mTextPlacement, 0, 0);
    
    inParams->mUISoundId = SFX_MISC_UNIMPLEMENTED;
}

-(void)SetText:(NSString*)inString
{
    [mTextTexture release];
    
    mTextTexture = [[TextTextureBuilder GetInstance] GenerateTextureWithFont:[NSString stringWithString:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_STYLISH]] PointSize:mParams.mFontSize String:inString Color:mParams.mFontColor];
    [mTextTexture retain];
}

-(void)DrawOrtho
{
    QuadParams quadParams;
    
    [UIObject InitQuadParams:&quadParams];
    
    quadParams.mColorMultiplyEnabled = TRUE;
    quadParams.mBlendEnabled = TRUE;
        
    for (int i = 0; i < 4; i++)
    {
        SetColorFloat(&quadParams.mColor[i], GetRedFloat(&mParams.mColor), GetGreenFloat(&mParams.mColor), GetBlueFloat(&mParams.mColor), GetAlphaFloat(&mParams.mColor) * mAlpha);
    }
    
    BOOL drawn = FALSE;
        
    if (mBaseTexture != NULL) 
    {
        Texture* drawTexture = NULL;
        
        switch([self GetState])
        {
            case UI_OBJECT_STATE_ENABLED:
            {
                drawTexture = mBaseTexture;
                break;
            }
            
            case UI_OBJECT_STATE_HIGHLIGHTED:
            {
                drawTexture = mHighlightedTexture;
                break;
            }
            
            case UI_OBJECT_STATE_DISABLED:
            case UI_OBJECT_STATE_INACTIVE:
            {
                drawTexture = mDisabledTexture;
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown UIObject state");
                break;
            }
        }
        
        if (drawTexture == NULL)
        {
            drawTexture = mBaseTexture;
        }
        
        quadParams.mTexture = drawTexture;
        
        [self DrawQuad:&quadParams withIdentifier:BUTTON_GRAPHIC_IDENTIFIER];
        drawn = TRUE;
    }
    
    if (mTextTexture != NULL)
    {
        s32 hAlign = GetHAlignPixels(&mParams.mTextPlacement);
        s32 vAlign = GetVAlignPixels(&mParams.mTextPlacement);
        
        SetVec2(&quadParams.mTranslation, (float)hAlign, (float)vAlign);
        quadParams.mTexture = mTextTexture;
        
        [self DrawQuad:&quadParams withIdentifier:BUTTON_TEXT_IDENTIFIER];
        drawn = TRUE;
    }
    
    if (!drawn)
    {
        quadParams.mBlendEnabled = TRUE;
        [self DrawQuad:&quadParams withIdentifier:BUTTON_COLOR_IDENTIFIER];
    }
}

-(void)StatusChanged:(UIObjectState)inState
{
    [super StatusChanged:inState];
    
    switch(inState)
    {
        case UI_OBJECT_STATE_HIGHLIGHTED:
        {
            [UISounds PlayUISound:mParams.mUISoundId];
            break;
        }
    }
}


-(Texture*)GetUseTexture
{
    Texture* useTexture = NULL;
    
    if (mBaseTexture != NULL)
    {
        useTexture = mBaseTexture;
    }
    else if (mTextTexture != NULL)
    {
        useTexture = mTextTexture;
    }

    return useTexture;
}

-(BOOL)HitTestWithPoint:(CGPoint*)inPoint
{
    Texture* useTexture = NULL;
    BOOL buttonTouched = FALSE;
    
    if (mBaseTexture != NULL)
    {
        useTexture = mBaseTexture;
    }
    else if (mTextTexture != NULL)
    {
        useTexture = mTextTexture;
    }
    else
    {   
        useTexture = NULL;
        return FALSE;
    }
    
    if ((inPoint->x >= 0) && (inPoint->y >= 0) && (inPoint->x < [useTexture GetRealWidth]) && (inPoint->y < [useTexture GetRealHeight]))
    {
        // If we're inside the bounding box, let's get the texel associated with this point
        
        u32 texel = [useTexture GetTexel:inPoint];
        // Only a touch if we hit a part of the button with non-zero alpha.  Otherwise we clicked a transparent part.
        if (((texel & 0xFF) != 0) || (useTexture == mTextTexture))
        {
            buttonTouched = TRUE;
        }
    }

    return buttonTouched;
}

-(BOOL)ProjectedHitTestWithRay:(Vector4*)inWorldSpaceRay
{
	// non-Bounding box collisions would involve calculating a texture coordinate and sampling it.
	// Not a big deal, just additional work.  We don't support that yet.
	NSAssert(mParams.mBoundingBoxCollision, @"We don't support non-bounding box collision yet.");
	
	Texture* useTexture = [self GetUseTexture];
	Rect3D	projectedCoords;
	
	[self GetProjectedCoordsForTexture:useTexture coords:&projectedCoords];
	
	Vector3 cameraPosition;
	[[CameraStateMgr GetInstance] GetPosition:&cameraPosition];
	
	Vector3 directionVector;
	SetVec3From4(&directionVector, inWorldSpaceRay);
	
	BOOL pointInRect = RayIntersectsRect3D(&cameraPosition, &directionVector, &projectedCoords);
	
	return pointInRect;
}

-(u32)GetWidth
{
    return [mBaseTexture GetRealWidth];
}

-(u32)GetHeight
{
    return [mBaseTexture GetRealHeight];
}

-(void)CalculateTextPlacement
{
    if (mBaseTexture != NULL)
    {
        u32 outerWidth = [mBaseTexture GetRealWidth];
        u32 outerHeight = [mBaseTexture GetRealHeight];
        
        u32 innerWidth = mTextEndX - mTextStartX;
        u32 innerHeight = mTextEndY - mTextStartY;
        
        CalculatePlacement(&mParams.mTextPlacement, outerWidth, outerHeight, innerWidth, innerHeight);
    }
}


@end