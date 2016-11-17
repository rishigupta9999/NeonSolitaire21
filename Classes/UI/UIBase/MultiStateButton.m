//
//  MultiStateButton.m
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "MultiStateButton.h"
#import "CameraStateMgr.h"
#import "SplitTestingSystem.h"

static const char MULTISTATEBUTTON_TEXTURE_IDENTIFIER[] = "MultiStateButton_Texture_Identifier";

@implementation MultiStateButton

-(MultiStateButton*)InitWithParams:(MultiStateButtonParams*)inParams
{
	[super InitWithUIGroup:inParams->mUIGroup];
	
	memcpy(&mParams, inParams, sizeof(MultiStateButtonParams));
		
	UIObjectTextureLoadParams textureLoadParams;
    [UIObject InitDefaultTextureLoadParams:&textureLoadParams];

	textureLoadParams.mTexDataLifetime = TEX_DATA_RETAIN;

	int numFilenames = [inParams->mButtonTextureFilenames count];
	
	mTextures = [[NSMutableArray alloc] initWithCapacity:numFilenames];
	
	for (int i = 0; i < numFilenames; i++)
	{
		textureLoadParams.mTextureName = [inParams->mButtonTextureFilenames objectAtIndex:i];
		
		Texture* newTexture = [self LoadTextureWithParams:&textureLoadParams];
		[mTextures addObject:newTexture];
	}
	
	return self;
}

-(void)dealloc
{
	[mTextures release];
	
	[super dealloc];
}

+(void)InitDefaultParams:(MultiStateButtonParams*)outParams
{
	outParams->mButtonTextureFilenames = NULL;
	outParams->mBoundingBoxCollision = FALSE;
	outParams->mUIGroup = NULL;
}

-(void)SetActiveIndex:(u32)inActiveIndex
{
	NSAssert((inActiveIndex >= 0) && (inActiveIndex < [mTextures count]), @"Index is out of range");
	
	mActiveIndex = inActiveIndex;
}

-(u32)GetActiveIndex
{
	return mActiveIndex;
}

-(void)StatusChanged:(UIObjectState)inState
{
    // Filter out Inactive events for multi state buttons.  We don't want the runners in Run 21 tutorials fading out while they're inactive.
    if ((inState != UI_OBJECT_STATE_INACTIVE) || (mProjected == FALSE))
    {
        [super StatusChanged:inState];
    }
}

-(void)DrawOrtho
{
    QuadParams quadParams;
    
    [UIObject InitQuadParams:&quadParams];
    
    quadParams.mColorMultiplyEnabled = TRUE;
    quadParams.mBlendEnabled = TRUE;
        
    for (int i = 0; i < 4; i++)
    {
        SetColorFloat(&quadParams.mColor[i], 1.0, 1.0, 1.0, mAlpha);
    }
        
	quadParams.mTexture = [mTextures objectAtIndex:mActiveIndex];
	[self DrawQuad:&quadParams withIdentifier:MULTISTATEBUTTON_TEXTURE_IDENTIFIER];
}

-(BOOL)HitTestWithPoint:(CGPoint*)inPoint
{
    Texture* useTexture = [mTextures objectAtIndex:mActiveIndex];
    BOOL buttonTouched = FALSE;
        
    if ((inPoint->x >= 0) && (inPoint->y >= 0) && (inPoint->x < [useTexture GetEffectiveWidth]) && (inPoint->y < [useTexture GetEffectiveHeight]))
    {
		if (mParams.mBoundingBoxCollision)
		{
			buttonTouched = TRUE;
		}
		else
		{
			// If we're inside the bounding box, let's get the texel associated with this point
			
			u32 texel = [useTexture GetTexel:inPoint];
			// Only a touch if we hit a part of the button with non-zero alpha.  Otherwise we clicked a transparent part.
			if ((texel & 0xFF) != 0)
			{
				buttonTouched = TRUE;
			}
		}
    }

    return buttonTouched;
}

-(BOOL)ProjectedHitTestWithRay:(Vector4*)inWorldSpaceRay
{
	// non-Bounding box collisions would involve calculating a texture coordinate and sampling it.
	// Not a big deal, just additional work.  We don't support that yet.
	NSAssert(mParams.mBoundingBoxCollision, @"We don't support non-bounding box collision yet.");
	
	Texture* useTexture = [mTextures objectAtIndex:mActiveIndex];
	Rect3D	projectedCoords;
	
	[self GetProjectedCoordsForTexture:useTexture coords:&projectedCoords];
	
	Vector3 cameraPosition;
	[[CameraStateMgr GetInstance] GetPosition:&cameraPosition];
	
	Vector3 directionVector;
	SetVec3From4(&directionVector, inWorldSpaceRay);
	
	BOOL pointInRect = RayIntersectsRect3D(&cameraPosition, &directionVector, &projectedCoords);
	
	return pointInRect;
}

@end