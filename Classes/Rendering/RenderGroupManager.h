//
//  RenderGroupManager.h
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

@class RenderGroup;

@interface RenderGroupManager : NSObject
{
	NSMutableArray*                 mRenderGroups;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(RenderGroupManager*)GetInstance;

-(RenderGroupManager*)Init;
-(void)dealloc;

-(void)AddRenderGroup:(RenderGroup*)inRenderGroup;
-(void)RemoveRenderGroup:(RenderGroup*)inRenderGroup;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Draw;

@end