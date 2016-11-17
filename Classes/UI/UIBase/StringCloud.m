//
//  StringCloud.m
//  Neon21
//
//  Copyright Neon Games 2014. All rights reserved.

#import "StringCloud.h"
#import "TextTextureBuilder.h"
#import "UIGroup.h"

static const char STRING_CLOUD_IDENTIFIER[] = "StringCloud_Texture";

@interface StringCloudEntry : NSObject
{
    @public
        Path*       mColorPath;
        Path*       mPositionPath;
}

@property(retain) Texture*  Texture;

-(StringCloudEntry*)init;
-(void)dealloc;

@end

@implementation StringCloudEntry : NSObject

@synthesize Texture = mTexture;

-(StringCloudEntry*)init
{
    mTexture = NULL;
    mColorPath = [[Path alloc] Init];
    mPositionPath = [[Path alloc] Init];
    
    [mPositionPath SetPeriodic:TRUE];
    [mColorPath SetPeriodic:TRUE];
    
    return self;
}

-(void)dealloc
{
    [mTexture release];
    [mColorPath release];
    [mPositionPath release];
    
    [super dealloc];
}

@end

@implementation StringCloudParams

-(StringCloudParams*)init
{
    mUIGroup = NULL;
    mStrings = [[NSMutableArray alloc] init];
    mFontSize = 12;
    mFontType = NEON_FONT_NORMAL;
    
    return self;
}

-(void)dealloc
{
    [mStrings release];
    
    [super dealloc];
}

@end

static const float STRING_CLOUD_DURATION = 4.0f;

@implementation StringCloud

-(StringCloud*)initWithParams:(StringCloudParams*)inParams
{
    NSAssert(inParams->mUIGroup != NULL, @"A UIGroup / GameObjectBatch is required for StringClouds");
    
    [super InitWithUIGroup:inParams->mUIGroup];
    
    int numStrings = [inParams->mStrings count];
    
    mScaleFactor = GetTextScaleFactor();
    
    mStringCloudEntries = [[NSMutableArray alloc] initWithCapacity:numStrings];
    
    for (int i = 0; i < numStrings; i++)
    {
        TextTextureParams textParams;
        [TextTextureBuilder InitDefaultParams:&textParams];
        
        textParams.mTextureAtlas = (inParams->mUIGroup == NULL) ? (NULL) : ([inParams->mUIGroup GetTextureAtlas]);
        textParams.mPointSize = inParams->mFontSize * mScaleFactor;
        textParams.mFontType = inParams->mFontType;
        textParams.mString = [inParams->mStrings objectAtIndex:i];
        textParams.mStrokeSize = 12.0;
        textParams.mStrokeColor = 0xFF;
        
        if (inParams->mUIGroup != NULL)
        {
            textParams.mPremultipliedAlpha = TRUE;
        }
        
        Texture* curTexture = [[TextTextureBuilder GetInstance] GenerateTextureWithParams:&textParams];
        [curTexture SetScaleFactor:mScaleFactor];
        
        StringCloudEntry* entry = [[StringCloudEntry alloc] init];
        
        entry.Texture = curTexture;
        
        float totalDistance = numStrings * inParams->mFontSize;
        [entry->mPositionPath AddNodeX:0.0 y:totalDistance z:0.0 atTime:0.0];
        [entry->mPositionPath AddNodeX:0.0 y:0.0 z:0.0 atTime:STRING_CLOUD_DURATION];
        
        float speed = totalDistance / STRING_CLOUD_DURATION;
        float entryDistance = i * inParams->mFontSize;
        float entryTime = (entryDistance / speed);
        
        [entry->mPositionPath SetTime:entryTime];
        
        [entry->mColorPath AddNodeScalar:0.0 atTime:0.0];
        [entry->mColorPath AddNodeScalar:1.0 atTime:(STRING_CLOUD_DURATION / 2.0)];
        [entry->mColorPath AddNodeScalar:0.0 atTime:STRING_CLOUD_DURATION];
        
        [entry->mColorPath SetTime:entryTime];

        [mStringCloudEntries addObject:entry];
        [entry release];
        
        [self RegisterTexture:curTexture];
    }

    return self;
}

-(void)dealloc
{
    [mStringCloudEntries release];
    [super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    for (StringCloudEntry* curEntry in mStringCloudEntries)
    {
        [curEntry->mPositionPath Update:inTimeStep];
        [curEntry->mColorPath Update:inTimeStep];
    }
    
    [super Update:inTimeStep];
}

-(void)DrawOrtho
{
    for (StringCloudEntry* curEntry in mStringCloudEntries)
    {
        QuadParams  quadParams;
        
        [UIObject InitQuadParams:&quadParams];
        
        quadParams.mColorMultiplyEnabled = TRUE;
        quadParams.mBlendEnabled = TRUE;
        quadParams.mTexture = curEntry.Texture;
        
        Vector3 position;
        [curEntry->mPositionPath GetValueVec3:&position];
        
        quadParams.mTranslation.mVector[x] = position.mVector[x];
        quadParams.mTranslation.mVector[y] = position.mVector[y];
        
        float color;
        [curEntry->mColorPath GetValueScalar:&color];
        
        quadParams.mColorMultiplyEnabled = TRUE;
        
        for (int i = 0; i < 4; i++)
        {
            SetColorFloat(&quadParams.mColor[i], 1.0, 1.0, 1.0, color * mAlpha);
        }
        
        [self DrawQuad:&quadParams withIdentifier:[[NSString stringWithFormat:@"%s_%p", STRING_CLOUD_IDENTIFIER, curEntry] UTF8String]];
    }

}

@end