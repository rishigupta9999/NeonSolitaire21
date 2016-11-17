//
//  MultiStateButton.h
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "Button.h"

typedef struct
{
    NSMutableArray*	mButtonTextureFilenames;
	BOOL			mBoundingBoxCollision;
    UIGroup*        mUIGroup;
	
	// TODO @does not support mUISoundID
} MultiStateButtonParams;

@interface MultiStateButton : Button
{
	NSMutableArray*			mTextures;
	u32						mActiveIndex;
	
	MultiStateButtonParams	mParams;
}

-(MultiStateButton*)InitWithParams:(MultiStateButtonParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(MultiStateButtonParams*)outParams;

-(void)StatusChanged:(UIObjectState)inState;

-(void)SetActiveIndex:(u32)inActiveIndex;
-(u32)GetActiveIndex;

-(BOOL)HitTestWithPoint:(CGPoint*)inPoint;
-(BOOL)ProjectedHitTestWithRay:(Vector4*)inWorldSpaceRay;

@end