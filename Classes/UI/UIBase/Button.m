//
//  Button.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.

#import "Button.h"
#import "GameObjectManager.h"
#import "Neon21AppDelegate.h"
#import "GameStateMgr.h"

NSString* ButtonDownNotification = @"Button Down";
NSString* ButtonUpNotification = @"Button Up";

@implementation Button

-(Button*)InitWithUIGroup:(UIGroup*)inUIGroup
{    
    NSAssert([self class] != [Button class], @"You can't create Button directly, create a subclass instead.");
    
    [super InitWithUIGroup:inUIGroup];
    
    mOrtho = TRUE;
    
    [[TouchSystem GetInstance] AddListener:self];
        
    mListenerObj = NULL;
    mInitialTouch = FALSE;
	mTouchEventConsumeType = TOUCHSYSTEM_CONSUME_NONE;
    
    mProxy = FALSE;
    
    mCachedTouchLocationValid = FALSE;
    
    return self;
}

-(void)dealloc
{   
    [super dealloc];
}

-(GameObject*)Remove
{    
    [[TouchSystem GetInstance] RemoveListener:self];
    
    [super Remove];
    
    return self;
}

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData
{
	BOOL buttonTouched = FALSE;
	
    CGPoint point = inData->mTouchLocation;

	if (!mProjected)
	{
		Vector3 position;
		[self GetPosition:&position];
			
		point.x -= position.mVector[x];
		point.y -= position.mVector[y];
        
        if ((mCachedTouchLocationValid) && (inData->mTouchType == TOUCHES_ENDED))
        {
            point = mCachedTouchLocation;
        }
		
		buttonTouched = [self HitTestWithPoint:&point];
	}
	else
	{
		buttonTouched = [self ProjectedHitTestWithRay:&inData->mRayWorldSpaceLocation];
	}
    
    mCachedTouchLocationValid = FALSE;
    
    UIObjectState curState = [self GetState];
    
	if ((curState != UI_OBJECT_STATE_DISABLED) && (curState != UI_OBJECT_STATE_INACTIVE))
	{
		switch(inData->mTouchType)
		{
			case TOUCHES_BEGAN:
			{
				// Now that we have a point in local coords of this button, do a bounding box check
				
				if (buttonTouched)
				{
                    [self SetState:UI_OBJECT_STATE_HIGHLIGHTED];
                    
                    [self StatusChanged:[self GetState]];
                    [self DispatchEvent:BUTTON_EVENT_DOWN];
                    
                    mInitialTouch = TRUE;
				}
                else
                {
                    mInitialTouch = FALSE;
                }
                
                mCachedTouchLocationValid = TRUE;
                mCachedTouchLocation = point;
				
				break;
			}
				
			case TOUCHES_ENDED:
			{
                if ([self GetState] == UI_OBJECT_STATE_HIGHLIGHTED)
                {
                    [self SetState:UI_OBJECT_STATE_ENABLED];
                    
                    [self StatusChanged:[self GetState]];
                    
                    if (buttonTouched)
                    {
                        [self DispatchEvent:BUTTON_EVENT_UP];
                    }
                }
                
                mInitialTouch = FALSE;
				
				break;
			}
            
            case TOUCHES_MOVED:
            {
                if ([self GetState] == UI_OBJECT_STATE_HIGHLIGHTED)
                {
                    if (!buttonTouched)
                    {
                        [self SetState:UI_OBJECT_STATE_ENABLED];
                        [self StatusChanged:[self GetState]];
                        
                        [self DispatchEvent:BUTTON_EVENT_CANCELLED];
                    }
                }
                else if ([self GetState] == UI_OBJECT_STATE_ENABLED)
                {
                    if ((buttonTouched) && (mInitialTouch))
                    {
                        [self SetState:UI_OBJECT_STATE_HIGHLIGHTED];
                        [self StatusChanged:[self GetState]];
                        
                        [self DispatchEvent:BUTTON_EVENT_RESUMED];
                    }
                }
                
                break;
            }
            
            case TOUCHES_CANCELLED:
            {
                [self SetState:UI_OBJECT_STATE_ENABLED];
                [self StatusChanged:[self GetState]];
                
                [self DispatchEvent:BUTTON_EVENT_CANCELLED];
                
                mInitialTouch = FALSE;
                
                break;
            }
		}
	}
    
    return (buttonTouched ? mTouchEventConsumeType : FALSE);
}

-(void)StatusChanged:(UIObjectState)inState
{
    [super StatusChanged:inState];
    
    // If the button is highlighted, and the button is being changed to disabled, then send a button up notification.
    
    if (([self GetPrevState] == UI_OBJECT_STATE_HIGHLIGHTED) && (inState == UI_OBJECT_STATE_DISABLED))
    {
        [self DispatchEvent:BUTTON_EVENT_UP];
    }
}

-(void)SetListener:(NSObject<ButtonListenerProtocol>*)inListenerObj
{
    mListenerObj = inListenerObj;
}

-(BOOL)HitTestWithPoint:(CGPoint*)inPoint
{
    NSAssert(FALSE, @"Subclasses must implement this function");

    return FALSE;
}

-(BOOL)ProjectedHitTestWithRay:(Vector4*)inWorldSpaceCoord
{
	NSAssert(FALSE, @"Subclasses must implement this function");
	
	return FALSE;
}

-(void)DispatchEvent:(ButtonEvent)inEvent
{
    BOOL success = [mListenerObj ButtonEvent:inEvent Button:self];

    if (success)
    {
        if (inEvent == BUTTON_EVENT_UP)
        {
            [[GameStateMgr GetInstance] SendEvent:EVENT_ANY_BUTTON_UP withData:self];
        }
        else if (inEvent == BUTTON_EVENT_DOWN)
        {
            [[GameStateMgr GetInstance] SendEvent:EVENT_ANY_BUTTON_DOWN withData:self];
        }
    }
    
}

-(void)SetUsage:(BOOL)inUse
{
	if ( inUse )
		[ self Enable ];
	else
		[ self Disable ];
	
	
	[ self SetVisible:inUse ];
}

-(void)UnregisterTouchEvents
{
	NSAssert(FALSE, @"Function Not Working");
}

-(void)SetConsumesTouchEvents:(TouchSystemConsumeType)inConsumeType
{
	mTouchEventConsumeType = inConsumeType;
}

-(TouchSystemConsumeType)GetConsumeType
{
	return mTouchEventConsumeType;
}

-(void)SetProxy:(BOOL)inProxy
{
    mProxy = inProxy;
    
    if (mProxy)
    {
        mVisible = FALSE;
    }
}

-(void)SetVisible:(BOOL)inVisible
{
    if (!mProxy)
    {
        [super SetVisible:inVisible];
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if (mPlacementStatus == UI_OBJECT_PLACEMENT_STATUS_UNINITIALIZED)
    {
        Texture* useTexture = [self GetUseTexture];
        
        if ([useTexture GetStatus] == TEXTURE_STATUS_DECODING_COMPLETE)
        {
            [self CalculateTextPlacement];
        }
    }
    
    [super Update:inTimeStep];
}

-(void)CalculateTextPlacement
{
}

@end