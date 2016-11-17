//
//  Button.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.

#import "UIObject.h"
#import "Texture.h"
#import "TouchSystem.h"

typedef enum
{
    BUTTON_EVENT_DOWN,
    BUTTON_EVENT_UP,
    BUTTON_EVENT_CANCELLED,
    BUTTON_EVENT_RESUMED
} ButtonEvent;

@class Button;

@protocol ButtonListenerProtocol

-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end


@interface Button : UIObject <TouchListenerProtocol>
{        
    NSObject<ButtonListenerProtocol>*   mListenerObj;
    BOOL                                mInitialTouch;
	TouchSystemConsumeType				mTouchEventConsumeType;
    
    CGPoint                             mCachedTouchLocation;
    BOOL                                mCachedTouchLocationValid;
    
    // Proxy Buttons are buttons which should never be rendered, they function solely has hit test regions
    BOOL                                mProxy;
}

-(Button*)InitWithUIGroup:(UIGroup*)inUIGroup;

-(void)dealloc;
-(Button*)Remove;

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData;
-(void)SetListener:(NSObject<ButtonListenerProtocol>*)inListenerObj;

-(BOOL)HitTestWithPoint:(CGPoint*)inPoint;
-(BOOL)ProjectedHitTestWithRay:(Vector4*)inWorldSpaceCoord;

-(void)StatusChanged:(UIObjectState)inState;

-(void)DispatchEvent:(ButtonEvent)inEvent;
-(void)SetUsage:(BOOL)inUse;
-(void)UnregisterTouchEvents;

-(void)SetConsumesTouchEvents:(TouchSystemConsumeType)inConsumeType;
-(TouchSystemConsumeType)GetConsumeType;

-(void)SetProxy:(BOOL)inProxy;
-(void)SetVisible:(BOOL)inVisible;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)CalculateTextPlacement;

@end

extern NSString* ButtonDownNotification;
extern NSString* ButtonUpNotification;