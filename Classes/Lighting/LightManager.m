//
//  LightManager.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "LightManager.h"

#import "GameStateMgr.h"
#import "LightingEditorState.h"

static LightManager* sInstance = NULL;

static const char* LIGHTING_EDITOR_STRING = "Lighting Editor";

@implementation LightManager

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"LightManager is non-NULL but CreateInstance was called");
    
    sInstance = [(LightManager*)[LightManager alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"LightManager is NULL and DestroyInstance was called");
    
    [sInstance release];
    sInstance = NULL;
}

+(LightManager*)GetInstance
{
    return sInstance;
}

-(LightManager*)Init
{
    mLights = [[NSMutableArray alloc] initWithCapacity:NUM_OPENGL_LIGHTS];
    
    mMinGLIdentifier = GL_LIGHT0;
    mMaxGLIdentifier = GL_LIGHT7;
    
    [[DebugManager GetInstance] RegisterDebugMenuItem:[NSString stringWithUTF8String:LIGHTING_EDITOR_STRING] WithCallback:self];
    
    return self;
}

-(void)dealloc
{
    for (Light* curLight in mLights)
    {
        [curLight release];
    }
    
    [mLights release];
    
    [super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    
}

-(void)UpdateLights
{
    int numLights = [mLights count];
    
    for (int i = 0; i < numLights; i++)
    {
        Light*  curLight = [mLights objectAtIndex:i];
        
        [curLight ApplyParams];
    }
}

-(Light*)CreateLight
{
    Light* newLight = NULL;
    
    int numLights = [mLights count];
    
    BOOL* useArray = malloc(sizeof(BOOL) * (mMaxGLIdentifier - mMinGLIdentifier + 1));
    memset(useArray, 0, sizeof(BOOL) * (mMaxGLIdentifier - mMinGLIdentifier + 1));
    
    for (int i = 0; i < numLights; i++)
    {
        Light* curLight = [mLights objectAtIndex:i];
        
        useArray[curLight->mGLIdentifier - mMinGLIdentifier] = TRUE;
    }
    
    BOOL success = FALSE;
    
    for (int i = 0; i < (mMaxGLIdentifier - mMinGLIdentifier + 1); i++)
    {
        if (useArray[i] == FALSE)
        {
            int newIdentifier = i + mMinGLIdentifier;
            newLight = [[Light alloc] InitWithIdentifier:newIdentifier];
            
            [mLights addObject:newLight];
            [newLight release];
            
            success = TRUE;
            
            break;
        }
    }
    
    NSAssert(success, @"Unable to assign light.  Either ran out of lights, or we're leaking a light object somewhere");
    
    free(useArray);
    
    NSAssert(newLight != NULL, @"Null light created");
    return newLight;
}

-(void)RemoveLight:(Light*)inLight
{
    [inLight SetLightActive:FALSE];
    
    u32 index = [mLights indexOfObject:inLight];
    NSAssert(index != NSNotFound, @"Could not find light in the light array - was this light already removed before?");
    index = index;
    
    [mLights removeObject:inLight];

    Message msg;
    
    msg.mId = EVENT_LIGHT_REMOVED;
    msg.mData = inLight;
    
    [GetGlobalMessageChannel() BroadcastMessageSync:&msg];
}

-(int)GetNumLights
{
    return [mLights count];
}

-(Light*)GetLight:(int)inLightIndex
{
    return [mLights objectAtIndex:inLightIndex];
}

-(void)DebugMenuItemPressed:(NSString*)inName
{
    if ([inName compare:[NSString stringWithUTF8String:LIGHTING_EDITOR_STRING]] == NSOrderedSame)
    {
        [[DebugManager GetInstance] ToggleDebugGameState:[LightingEditorState class]];
    }
}

-(void)EnableAllLights
{
    for (Light* curLight in mLights)
    {
        [curLight SetLightActive:TRUE];
    }
}

-(void)EnableLights:(NSArray*)inLights
{
    for (Light* curLight in mLights)
    {
        [curLight SetLightActive:FALSE];
    }
    
    for (Light* curLight in inLights)
    {
        [curLight SetLightActive:TRUE];
    }
}

@end
