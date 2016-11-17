//
//  TextBox.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.

#import "TextBox.h"
#import "TextureManager.h"
#import "TextTextureBuilder.h"
#import "CharMap.h"

#import "UIGroup.h"

static const char TEXT_BOX_IDENTIFIER[] = "TextBox_Texture";

@implementation TextBox

+(void)InitDefaultParams:(TextBoxParams*)outParams
{
    outParams->mString = NULL;
    outParams->mFontType = NEON_FONT_NORMAL;
    outParams->mFontSize = 12;
    outParams->mWidth = 0;
    SetColor(&outParams->mColor, 0xFF, 0xFF, 0, 0xFF);
    
    outParams->mMaxWidth = 0;
    outParams->mMaxHeight = 0;
    outParams->mMutable = FALSE;
    
    outParams->mStrokeSize = 0;
    SetColor(&outParams->mStrokeColor, 0xFF, 0xFF, 0, 0xFF);

    outParams->mUIGroup = NULL;
    
    outParams->mHorizontalPadding = 0;
    
    outParams->mCharMap = NULL;
    outParams->mCharMapSpacing = 1.0f;
    
    outParams->mAlignment = TEXTBOX_ALIGNMENT_LEFT;
}

-(void)InitFromExistingParams:(TextBoxParams*)outParams
{
    memcpy(outParams, &mParams, sizeof(TextBoxParams));
}

-(TextBox*)InitWithParams:(TextBoxParams*)inParams
{
    mState = TEXTBOX_UNINITIALIZED;
    
    [super InitWithUIGroup:inParams->mUIGroup];		
    
    memset(&mParams, 0, sizeof(TextBoxParams));
    mTexture = NULL;
    
    mHAlignOffset = 0;
    mVAlignOffset = 0;
    
    [self EvaluateParams:inParams];
    
    mOrtho = TRUE;
    
    mState = TEXTBOX_INITIALIZED;
        
    return self;
}

-(void)dealloc
{
    [mTexture release];
    [mParams.mString release];
    [mParams.mCharMap release];

    [super dealloc];
}

#define IDENTIFIER_LENGTH   (128)

-(void)DrawOrtho
{
    if (mParams.mCharMap)
    {
        QuadParams  quadParams;
        
        [UIObject InitQuadParams:&quadParams];
        
        quadParams.mColorMultiplyEnabled = TRUE;
        quadParams.mBlendEnabled = TRUE;
        
        for (int i = 0; i < 4; i++)
        {
            SetColorFloat(&quadParams.mColor[i], 1.0, 1.0, 1.0, mAlpha);
        }

        int stringLength = [mParams.mString length];
        
        static char identifier[IDENTIFIER_LENGTH];
        
        for (int i = 0; i < stringLength; i++)
        {
            CharMapEntryType type;
            Texture* data = [mParams.mCharMap GetDataForGlyphWithString:[mParams.mString substringWithRange:NSMakeRange(i, 1)] type:&type];
            
            NSAssert(data != NULL, @"Glyph not found in char map");
            NSAssert(type == CHARMAP_ENTRY_TEXTURE, @"Unexpected CharMap data type");
            
            quadParams.mTexture = data;
            
            SetVec2(&quadParams.mTranslation, mParams.mCharMapSpacing * i, 0);

            snprintf(identifier, IDENTIFIER_LENGTH, "%s_%d", TEXT_BOX_IDENTIFIER, i);
            [self DrawQuad:&quadParams withIdentifier:identifier];
        }
    }
    else
    {
        if ((mTexture != NULL) && ([mParams.mString length] != 0))
        {
            QuadParams  quadParams;
            
            [UIObject InitQuadParams:&quadParams];
            
            quadParams.mColorMultiplyEnabled = TRUE;
            quadParams.mBlendEnabled = TRUE;
            quadParams.mTexture = mTexture;
            
            for (int i = 0; i < 4; i++)
            {
                SetColorFloat(&quadParams.mColor[i], 1.0, 1.0, 1.0, mAlpha);
            }
            
            quadParams.mTranslation.mVector[x] -= mHAlignOffset;
            quadParams.mTranslation.mVector[y] -= mVAlignOffset;

            [self DrawQuad:&quadParams withIdentifier:TEXT_BOX_IDENTIFIER];
        }
    }
}

-(void)EvaluateParams:(TextBoxParams*)inParams
{
    NSAssert((mState == TEXTBOX_UNINITIALIZED) || (inParams->mUIGroup == mGameObjectBatch), @"You can't change a UIObject's group association after it's been created");
    
    // If no UI group was specified, than that is automatically valid
    BOOL paramsValid = FALSE;
    
    if (inParams->mUIGroup == NULL)
    {
        paramsValid = TRUE;
    }
    else
    {
        // If a UI group is specified, but the TextBox is immutable (ie: we promise not to change it), then that is valid.
        if (!inParams->mMutable)
        {
            if (mState == TEXTBOX_UNINITIALIZED)
            {
                paramsValid = TRUE;
            }
        }
        else
        {
            // Otherwise, the caller needs to specify the maximum dimensions that the textbox will occupy so we can
            // reserve enough texture space for changes.
            
            if ((inParams->mMaxWidth != 0) && (inParams->mMaxHeight != 0))
            {
                paramsValid = TRUE;
            }
        }
    }

    NSAssert(paramsValid, @"An invalid combination of TextBox parameters was specified, please double check the parameters.");
    
    if (mState == TEXTBOX_INITIALIZED)
    {
        if (inParams->mString != mParams.mString)
        {
            [mParams.mString release];
            mParams.mString = inParams->mString;
        }
        
        if (inParams->mFontType != mParams.mFontType)
        {
            mParams.mFontType = inParams->mFontType;
        }
    }
    
    mScaleFactor = GetTextScaleFactor();
	
	if (([self GetProjected]) || ([mGameObjectBatch GetProjected]))
	{
		mScaleFactor = 1.0f;
        
        // Force UIObject to re-evaluate the texture filtering state
        mDirtyBits |= UIOBJECT_PROJECTED_STATE_DIRTY;
	}
    
    if (inParams->mCharMap != NULL)
    {        
        if (mState == TEXTBOX_UNINITIALIZED)
        {
            mParams.mCharMap = inParams->mCharMap;
            [mParams.mCharMap retain];

            [self EvaluateCharMap];
        }
        else
        {
            NSAssert(mParams.mCharMap == inParams->mCharMap, @"We don't support changing the CharMap for an already created TextBox");
        }
    }
    
    if (inParams->mCharMap == NULL)
    {
        if (inParams->mString != NULL)
        {
            TextTextureParams params;
            
            [TextTextureBuilder InitDefaultParams:&params];
            
            params.mFontType = inParams->mFontType;
            params.mPointSize = inParams->mFontSize * mScaleFactor;
            params.mString = inParams->mString;
            params.mColor = GetRGBAU32(&inParams->mColor);
            
            // Multiply by 2 because stroke sizes were tuned for retina displays.  But it works on non-retina and iPad because stroke size is now a percentage of font size (rather than an absolute value)
            params.mWidth = inParams->mWidth * mScaleFactor;
            params.mTextureAtlas = (inParams->mUIGroup == NULL) ? (NULL) : ([inParams->mUIGroup GetTextureAtlas]);
            params.mStrokeSize = inParams->mStrokeSize * 2.0;
            params.mStrokeColor = GetRGBAU32(&inParams->mStrokeColor);
            params.mPremultipliedAlpha = TRUE;
            
            params.mLeadWidth = inParams->mHorizontalPadding * mScaleFactor;
            params.mTrailWidth = inParams->mHorizontalPadding * mScaleFactor;
            
            if (inParams->mAlignment == TEXTBOX_ALIGNMENT_CENTER)
            {
                params.mAlignment = kCTTextAlignmentCenter;
            }
            
            if (params.mTextureAtlas)
            {
                params.mTexture = mTexture;
            }
            else
            {
                // If we're not using a texture atlas, we have no use for the old texture.  So release it.
                [mTexture release];
            }
            
            // For a mutable TextBox, it's valid to initialize with an empty string.  But various part of the engine rely on
            // there being an allocated texture at this point (we don't have an allocated texture if we specify an empty string).
            // So just specify a space as the string so that we get a texture back.
            if ((inParams->mMutable) && ((inParams->mString == NULL) || ([inParams->mString length] == 0)))
            {
                params.mString = @" ";
            }
            
            mTexture = [[TextTextureBuilder GetInstance] GenerateTextureWithParams:&params];
            
            mParams.mAlignment = inParams->mAlignment;
            
            switch(mParams.mAlignment)
            {
                case TEXTBOX_ALIGNMENT_LEFT:
                {
                    mHAlignOffset = 0;
                    mVAlignOffset = 0;
                    
                    break;
                }
                
                case TEXTBOX_ALIGNMENT_CENTER:
                {
                    mHAlignOffset = [mTexture GetRealWidth] / mScaleFactor / 2;
                    mVAlignOffset = 0;
                    
                    break;
                }
            }
			
			[mTexture SetScaleFactor:mScaleFactor];
            
            if ((params.mTextureAtlas != NULL) && ([params.mTextureAtlas AtlasCreated] != 0))
            {
                [self UpdateTexture:mTexture];
            }
            else
            {
                if ((inParams->mMaxWidth != 0) && (inParams->mMaxHeight != 0))
                {
                    [mTexture SetMaxWidth:(inParams->mMaxWidth * mScaleFactor)];
                    [mTexture SetMaxHeight:(inParams->mMaxHeight * mScaleFactor)];
                }
                
                if ((inParams->mUIGroup) && ([inParams->mUIGroup GetTextureAtlas]))
                {
                    if (mTexture != NULL)
                    {
                        mTexture->mPremultipliedAlpha = TRUE;
                    }
                }
                
                if (![self TextureRegistered:mTexture])
                {
                    [self RegisterTexture:mTexture];
                    [mTexture retain];
                }
            }
        }
        else
        {        
            if ((inParams->mMaxWidth != 0) && (inParams->mMaxHeight != 0))
            {
                mTexture = [(Texture*)[Texture alloc] Init];

                [mTexture SetMaxWidth:(inParams->mMaxWidth * mScaleFactor)];
                [mTexture SetMaxHeight:(inParams->mMaxHeight * mScaleFactor)];
                
                [mTexture SetIdentifier:[NSString stringWithFormat:@"%p", self]];
                
                if ((inParams->mUIGroup) && ([inParams->mUIGroup GetTextureAtlas]))
                {
                    mTexture->mPremultipliedAlpha = TRUE;
                }
                
                if (![[inParams->mUIGroup GetTextureAtlas] AtlasCreated])
                {
                    [self RegisterTexture:mTexture];
                }
                
                [mTexture SetStatus:TEXTURE_STATUS_DECODING_COMPLETE];
            }
        }
    }
        
    memcpy(&mParams, inParams, sizeof(TextBoxParams));
    
    if (mParams.mString != NULL)
    {
        [mParams.mString retain];
    }
}

-(void)SetString:(NSString*)inString
{
    if ((inString == NULL) && (mParams.mString == NULL))
    {
        return;
    }
    
    if (![inString isEqualToString:mParams.mString])
    {
        [mParams.mString release];
        mParams.mString = inString;
        
        // Will do a retain on the above string
        [self EvaluateParams:&mParams];
    }
}

-(void)SetParams:(TextBoxParams*)inParams
{
    [self EvaluateParams:inParams];
}

-(u32)GetWidth
{
    int retWidth = 0;
    
    if (mTexture != NULL)
    {
        retWidth = [mTexture GetRealWidth] / mScaleFactor;
    }
    
    return retWidth;
}

-(u32)GetHeight
{
    int retHeight = 0;
    
    if (mTexture != NULL)
    {
        retHeight = [mTexture GetRealHeight] / mScaleFactor;
    }
    
    return retHeight;
}

-(void)EvaluateCharMap
{
    NSMutableArray* charMapArray = [mParams.mCharMap GetCharMapArray];
    
    for (CharMapEntry* curEntry in charMapArray)
    {        
        if (curEntry->mType == CHARMAP_ENTRY_STRING)
        {
            NSString* filename = (NSString*)[curEntry GetData];
            
            UIObjectTextureLoadParams textureParams;
            [UIObject InitDefaultTextureLoadParams:&textureParams];
            
            textureParams.mTextureName = filename;
            textureParams.mTexDataLifetime = TEX_DATA_DISPOSE;
            
            Texture* texture = [self LoadTextureWithParams:&textureParams];
            
            [curEntry SetData:texture type:CHARMAP_ENTRY_TEXTURE];
        }
    }
}

-(void)SetProjected:(BOOL)inProjected
{
    [super SetProjected:inProjected];
    
    [self EvaluateParams:&mParams];
}

@end
