//
//  RenderGroupManager.mm
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "RenderGroupManager.h"
#import "RenderGroup.h"
#import "ModelManager.h"
#import "GameStateMgr.h"

#define RENDERGROUP_INITIAL_CAPACITY	(5)

static RenderGroupManager* sInstance = NULL;

@implementation RenderGroupManager

+(void)CreateInstance
{
	NSAssert(sInstance == NULL, @"Attempting to double-create RenderGroupManager");
	sInstance = [(RenderGroupManager*)[RenderGroupManager alloc] Init];
}

+(void)DestroyInstance
{
	NSAssert(sInstance != NULL, @"Attempting to delete RenderGroupManager when it does not exist");
	
	[sInstance release];
	sInstance = NULL;
}

+(RenderGroupManager*)GetInstance
{
	return sInstance;
}

-(RenderGroupManager*)Init
{
	mRenderGroups = [[NSMutableArray alloc] initWithCapacity:RENDERGROUP_INITIAL_CAPACITY];
	
	return self;
}

-(void)dealloc
{
	[mRenderGroups release];
	
	[super dealloc];
}

-(void)AddRenderGroup:(RenderGroup*)inRenderGroup
{
	[mRenderGroups addObject:inRenderGroup];
}

-(void)RemoveRenderGroup:(RenderGroup*)inRenderGroup
{
	[mRenderGroups removeObject:inRenderGroup];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	for (RenderGroup* curRenderGroup in mRenderGroups)
    {
        if ([curRenderGroup ShouldUpdate])
        {
            [curRenderGroup Update:inTimeStep];
        }
	}
}

-(void)Draw
{    
	for (RenderGroup* curRenderGroup in mRenderGroups)
	{
        if ([curRenderGroup ShouldDraw])
        {
            [curRenderGroup Draw];
        }
	}
}

@end