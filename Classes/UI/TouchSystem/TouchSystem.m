//
//  TouchSystem.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "Neon21AppDelegate.h"
#import "UIKit/UIApplication.h"

#import "TouchSystem.h"
#import "CameraStateMgr.h"

static TouchSystem* sInstance = NULL;

#define TOUCH_QUEUE_DEFAULT_SIZE (5)
#define TOUCH_LISTENERS_DEFAULT_SIZE (5)

#define TOUCH_EXPECTED_SIZE (36)

@implementation TouchData

-(TouchData*)InitWithTouchData:(TouchData*)inTouchData
{
    mTouchType = inTouchData->mTouchType;
    mTouchLocation = inTouchData->mTouchLocation;
    mNumTouches = inTouchData->mNumTouches;
	
	CloneVec4(&inTouchData->mRayWorldSpaceLocation, &mRayWorldSpaceLocation);
    
    return self;
}

@end


@implementation TouchListenerNode
@end

@implementation TouchSystem

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"TouchSystem instance already exists\n");
    sInstance = [((TouchSystem*)[TouchSystem alloc]) Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"There is no TouchSystem to delete\n");
    [sInstance release];
    
    sInstance = NULL;
}

+(TouchSystem*)GetInstance
{
    return sInstance;
}

-(TouchSystem*)Init
{
    mTouchQueue = [[NSMutableArray alloc] initWithCapacity:TOUCH_QUEUE_DEFAULT_SIZE];
    mTouchListeners = [[NSMutableArray alloc] initWithCapacity:TOUCH_LISTENERS_DEFAULT_SIZE];
    
    mTouchState = TOUCH_STATE_IDLE;
    
    mAppView = NULL;
    mPanGestureRecognizer = NULL;
    mGesturesEnabled = TRUE;
    
    mLastMousePickFrameNumber = 0xFFFFFFFF;
    
    SetVec4(&mCachedMousePickRay, 0.0f, 0.0f, 0.0f, 0.0f);
    
    return self;
}

-(void)dealloc
{
    [mTouchQueue release];
    [mTouchListeners release];
    
    [mPanGestureRecognizer release];
    
    [super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    int numListeners = [mTouchListeners count];
    int numEvents = [mTouchQueue count];
    
    mTouchState = TOUCH_STATE_UPDATING_LISTENERS;
    
    // If we have any pending events, then inform the listeners of them
        
    for (int curEvent = 0; curEvent < numEvents; curEvent++)
    {
        TouchData* curTouchData = [mTouchQueue objectAtIndex:curEvent];

        TouchSystemConsumeType maxConsumeType = TOUCHSYSTEM_CONSUME_NONE;

        for (int curListener = 0; curListener < numListeners; curListener++)
        {
            TouchListenerNode* curNode = [mTouchListeners objectAtIndex:curListener];
                        
            if (!curNode->mPendingDelete)
            {
                BOOL deliverEvent = TRUE;
                
                // Check and see if this is a projected GameObject.  If we're currently not delivering events to projected UI,
                // then don't deliver this touch event.
                
                if ([[curNode->mListener class] isSubclassOfClass:[GameObject class]])
                {
                    if ([(GameObject*)(curNode->mListener) GetProjected] && (maxConsumeType >= TOUCHSYSTEM_CONSUME_PROJECTED))
                    {
                        deliverEvent = FALSE;
                    }
                }
                
                if (deliverEvent)
                {
                    TouchSystemConsumeType consumeType = [curNode->mListener TouchEventWithData:curTouchData];
                    
                    if (consumeType > maxConsumeType)
                    {
                        maxConsumeType = consumeType;
                    }
                }
            }
            
            // If the event shouldn't be delivered to anymore listeners, early exit the loop
            if (maxConsumeType == TOUCHSYSTEM_CONSUME_ALL)
            {
                break;
            }
        }
    }
    
    mTouchState = TOUCH_STATE_IDLE;
    
    [mTouchQueue removeAllObjects];
    
    // If we have any listeners pending removal, then we can get rid of them now.
    for (int i = 0; i < numListeners; i++)
    {
        TouchListenerNode* curNode = [mTouchListeners objectAtIndex:i];

        if (curNode->mPendingDelete)
        {
            [curNode->mListener release];
            [mTouchListeners removeObject:curNode];
            
            numListeners--;
            i--;
        }
    }
}

-(void)RegisterEvent:(TouchEvent)inEvent WithData:(NSSet*)inTouches
{
    TouchData* newData = [TouchData alloc];
    
    UITouch* touchEvent = [inTouches anyObject];
    
    newData->mTouchType = inEvent;
    newData->mNumTouches = touchEvent.tapCount;
    
    if (inTouches != NULL)
    {
        newData->mTouchLocation = [touchEvent locationInView:gAppView];
      
#if LANDSCAPE_MODE
        if (GetDevicePad())
        {
            // Want the interior 640 x 960 region on the iPad (for UI) to correspond to the iPhone coordinate system
            
            int screenWidth = GetScreenAbsoluteWidth();
            int screenHeight = GetScreenAbsoluteHeight();
            int renderWidth = GetBaseWidth() * GetContentScaleFactor();
            int renderHeight = GetBaseHeight() * GetContentScaleFactor();
            
            int xOffset = (screenWidth - renderWidth) / 2;
            int yOffset = (screenHeight - renderHeight) / 2;
            
            CGPoint scaledTouchLocation = newData->mTouchLocation;
                                    
            scaledTouchLocation.x = scaledTouchLocation.x / ((float)GetScreenAbsoluteHeight() / (float)GetBaseHeight());
            scaledTouchLocation.y = scaledTouchLocation.y / ((float)GetScreenAbsoluteWidth() / (float)GetBaseWidth());
            
            [self ComputeRayFromTouchLocation:&scaledTouchLocation worldSpaceLocation:&newData->mRayWorldSpaceLocation];

            float temp = newData->mTouchLocation.y;
            newData->mTouchLocation.y = GetBaseHeight() - ((newData->mTouchLocation.x - yOffset) / GetContentScaleFactor());
            newData->mTouchLocation.x = (temp - xOffset) / GetContentScaleFactor();
        }
        else if (GetDeviceiPhoneTall())
        {
            // Want the interior 640 x 960 region on the iPad (for UI) to correspond to the iPhone coordinate system
            
            int screenWidth = GetScreenAbsoluteWidth();
            int screenHeight = GetScreenAbsoluteHeight();
            int renderWidth = GetBaseWidth();
            int renderHeight = GetBaseHeight();
            
            int xOffset = (screenWidth - renderWidth) / 2;
            int yOffset = (screenHeight - renderHeight) / 2;
            
            CGPoint scaledTouchLocation = newData->mTouchLocation;
                                    
            scaledTouchLocation.x = scaledTouchLocation.x / ((float)GetScreenAbsoluteHeight() / (float)GetBaseHeight());
            scaledTouchLocation.y = scaledTouchLocation.y / ((float)GetScreenAbsoluteWidth() / (float)GetBaseWidth());
            
            [self ComputeRayFromTouchLocation:&scaledTouchLocation worldSpaceLocation:&newData->mRayWorldSpaceLocation];

            float temp = newData->mTouchLocation.y;
            newData->mTouchLocation.y = GetBaseHeight() - (newData->mTouchLocation.x - yOffset);
            newData->mTouchLocation.x = (temp - xOffset);
        }
        else
        {
            [self ComputeRayFromTouchLocation:&newData->mTouchLocation worldSpaceLocation:&newData->mRayWorldSpaceLocation];

            float temp = newData->mTouchLocation.y;
            newData->mTouchLocation.y = GetBaseHeight() - newData->mTouchLocation.x;
            newData->mTouchLocation.x = temp;
        }
#endif
    }
    else
    {
        newData->mTouchLocation = CGPointMake(0.0f, 0.0f);
    }
    
    [mTouchQueue addObject:newData];
    [newData release];
}

-(void)AddListener:(NSObject<TouchListenerProtocol>*)inListener
{
    [self AddListener:inListener withPriority:TOUCHSYSTEM_PRIORITY_DEFAULT];
}

-(void)AddListener:(NSObject<TouchListenerProtocol>*)inListener withPriority:(TouchSystemPriority)inPriority
{
    TouchListenerNode* touchListenerNode = [TouchListenerNode alloc];
    
    touchListenerNode->mListener = inListener;
    touchListenerNode->mPendingDelete = FALSE;
    touchListenerNode->mPriority = inPriority;
    
    [inListener retain];
    
    int numListeners = [mTouchListeners count];
    
    if (numListeners == 0)
    {
        [mTouchListeners addObject:touchListenerNode];
    }
    else
    {
        BOOL success = FALSE;
        
        for (int curListenerIndex = 0; curListenerIndex < numListeners; curListenerIndex++)
        {
            TouchListenerNode* curListener = [mTouchListeners objectAtIndex:curListenerIndex];
            
            if (inPriority < curListener->mPriority)
            {
                [mTouchListeners insertObject:touchListenerNode atIndex:curListenerIndex];
                success = TRUE;
                break;
            }
        }
        
        if (!success)
        {
            [mTouchListeners addObject:touchListenerNode];
        }
    }
    
    [touchListenerNode release];
}

-(void)RemoveListener:(NSObject*)inListener
{
    int numListeners = [mTouchListeners count];
    
    for (int i = 0; i < numListeners; i++)
    {
        TouchListenerNode* curNode = [mTouchListeners objectAtIndex:i];
        
        if (curNode->mListener == inListener)
        {
            if (mTouchState == TOUCH_STATE_IDLE)
            {
                [curNode->mListener release];
                [mTouchListeners removeObject:curNode];
            }
            else
            {
                curNode->mPendingDelete = TRUE;
            }
            
            break;
        }
    }
}

-(void)SetAppView:(UIView*)inAppView
{
    NSAssert(mAppView == NULL, @"Attempting to set app view a second time.  This is currently unsupported");
    mAppView = inAppView;
    
    [self CreateGestureRecognizers];
}

-(void)CreateGestureRecognizers
{
    mPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(HandlePanGesture:)];
    
    mPanGestureRecognizer.minimumNumberOfTouches = 1;
    mPanGestureRecognizer.maximumNumberOfTouches = 1;
}

-(void)SetGesturesEnabled:(BOOL)inEnabled
{
    mGesturesEnabled = inEnabled;
    
    if (inEnabled)
    {
        [mAppView addGestureRecognizer:mPanGestureRecognizer];
    }
    else
    {
        [mAppView removeGestureRecognizer:mPanGestureRecognizer];
    }
}

-(void)HandlePanGesture:(UIGestureRecognizer*)inGestureRecognizer
{
    [[TouchSystem GetInstance] RegisterEvent:PAN_EVENT WithData:NULL];
}

-(UIPanGestureRecognizer*)GetPanGestureRecognizer
{
    return mPanGestureRecognizer;
}

-(void)ComputeRayFromTouchLocation:(CGPoint*)inPoint worldSpaceLocation:(Vector4*)outWorldSpaceRay
{
    u32 curFrameNumber = [(Neon21AppDelegate*)[[UIApplication sharedApplication] delegate] GetFrameNumber];
    
    if (curFrameNumber != mLastMousePickFrameNumber)
    {
        Vector4 ndc;
        
        ndc.mVector[x] = ((2 * inPoint->x) / 320.0f) - 1.0f;
        ndc.mVector[y] = 1.0f - ((2 * inPoint->y) / 480.0f);
        ndc.mVector[z] = -1.0f;
        ndc.mVector[w] = 1.0f;
        
        // We now have Normalized Device Coordinates, also the same as Clip Coordinates for these purposes, as per the paper.
        // Now we translate these view / camera space by multiplying by inverse projection
        
        Matrix44 inverseProjection;
        [[CameraStateMgr GetInstance] GetInverseProjectionMatrix:&inverseProjection];
        
        Vector4 eyeSpaceCoords;
        TransformVector4x4(&inverseProjection, &ndc, &eyeSpaceCoords);
        
        eyeSpaceCoords.mVector[w] = 0.0f;
        
        Matrix44 screenRotation;
        [[CameraStateMgr GetInstance] GetInverseScreenRotationMatrix:&screenRotation];

        Vector4 rotatedCoords;
        TransformVector4x4(&screenRotation, &eyeSpaceCoords, &rotatedCoords);
        
        Matrix44 inverseView;
        [[CameraStateMgr GetInstance] GetInverseViewMatrix:&inverseView];
        
        TransformVector4x4(&inverseView, &rotatedCoords, &mCachedMousePickRay);
        
        mLastMousePickFrameNumber = curFrameNumber;
        
#if !NEON_PRODUCTION
        [[DebugManager GetInstance] SpawnPickRay:&mCachedMousePickRay];
#endif
    }
	
	CloneVec4(&mCachedMousePickRay, outWorldSpaceRay);
}

@end