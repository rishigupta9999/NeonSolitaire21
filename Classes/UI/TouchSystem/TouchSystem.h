//
//  TouchSystem.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

typedef enum
{
    TOUCHES_BEGAN,
    TOUCHES_ENDED,
    TOUCHES_MOVED,
    TOUCHES_CANCELLED,
    PAN_EVENT,
    TOUCHES_MAX
} TouchEvent;

// Lower numbers (first in the enumeration list) are higher priority.
typedef enum
{
    TOUCHSYSTEM_PRIORITY_FIRST,
    TOUCHSYSTEM_PRIORITY_STINGER = TOUCHSYSTEM_PRIORITY_FIRST,
    TOUCHSYSTEM_PRIORITY_UI,
    TOUCHSYSTEM_PRIORITY_DEFAULT = TOUCHSYSTEM_PRIORITY_UI,
    TOUCHSYSTEM_PRIORITY_SCREEN,
    TOUCHSYSTEM_PRIORITY_MAX
} TouchSystemPriority;

typedef enum
{
    TOUCHSYSTEM_CONSUME_NONE,       // The touch event will be delivered to all other listeners
    TOUCHSYSTEM_CONSUME_PROJECTED,  // The touch event will be delivered only to non-projected listeners
    TOUCHSYSTEM_CONSUME_ALL,        // The touch event will not be delivered to any other listeners
} TouchSystemConsumeType;

@interface TouchData : NSObject
{
    @public
        TouchEvent  mTouchType;
        CGPoint     mTouchLocation;
        u32         mNumTouches;
        
		Vector4		mRayWorldSpaceLocation;
        
/* WARNING: When adding new fields, be sure to update InitWithTouchData */
}

-(TouchData*)InitWithTouchData:(TouchData*)inTouchData;

@end

@protocol TouchListenerProtocol

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData;

@end


@interface TouchListenerNode : NSObject
{
    @public
        NSObject<TouchListenerProtocol>*    mListener;
        TouchSystemPriority                 mPriority;
        BOOL                                mPendingDelete;
}

@end

typedef enum
{
    TOUCH_STATE_IDLE,
    TOUCH_STATE_UPDATING_LISTENERS,
    TOUCH_STATE_INVALID
} TouchState;

@interface TouchSystem : NSObject
{
    NSMutableArray*         mTouchQueue;
    NSMutableArray*         mTouchListeners;
    
    TouchState              mTouchState;
    
    UIView*                 mAppView;
    UIPanGestureRecognizer* mPanGestureRecognizer;
    
    BOOL                    mGesturesEnabled;
    
    u32                     mLastMousePickFrameNumber;
    Vector4                 mCachedMousePickRay;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(TouchSystem*)GetInstance;

-(TouchSystem*)Init;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)RegisterEvent:(TouchEvent)inEvent WithData:(NSSet*)inTouches;

-(void)AddListener:(NSObject<TouchListenerProtocol>*)inListener;
-(void)AddListener:(NSObject<TouchListenerProtocol>*)inListener withPriority:(TouchSystemPriority)inPriority;
-(void)RemoveListener:(NSObject*)inListener;	// Call this.

// Gestures should be disabled, unless they're needed in a specific circumstance.  They can make the UI less responsive.
-(void)SetGesturesEnabled:(BOOL)inEnabled;

-(void)SetAppView:(UIView*)inAppView;
-(void)CreateGestureRecognizers;
-(void)HandlePanGesture:(UIGestureRecognizer*)inGestureRecognizer;

-(UIPanGestureRecognizer*)GetPanGestureRecognizer;

-(void)ComputeRayFromTouchLocation:(CGPoint*)inPoint worldSpaceLocation:(Vector4*)outWorldSpaceRay;

@end