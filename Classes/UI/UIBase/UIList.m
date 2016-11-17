//
//  UIList.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "UIList.h"
#import "UIObject.h"

#define UI_LIST_INITIAL_CAPACITY    (16)
#define MOVE_DISTANCE_MINIMUM       (4)

@implementation UIList

-(UIList*)InitWithParams:(UIListParams*)inParams
{
    [super Init];
    
    mOrtho = TRUE;
    mUsesLighting = FALSE;
    
    memcpy(&mParams, inParams, sizeof(UIListParams));
    
    if (mParams.mBoundingDims.mVector[x] == 0)
    {
        mAutoWidth = TRUE;
    }
    else
    {
        mAutoWidth = FALSE;
    }
    
    if (mParams.mBoundingDims.mVector[y] == 0)
    {
        mAutoHeight = TRUE;
    }
    else
    {
        mAutoHeight = FALSE;
    }
    
    mUIObjects = [[NSMutableArray alloc] initWithCapacity:UI_LIST_INITIAL_CAPACITY];
    
    [[TouchSystem GetInstance] AddListener:self];
    mTouchState = TOUCH_STATE_NONE;
    
    mOffsetYTotal = 0;
    mOffsetYCurrent = 0;
    
    return self;
}

-(void)dealloc
{
    for (UIObject* curObject in mUIObjects)
    {
        [curObject Remove];
    }
    
    [mUIObjects release];
    
    [super dealloc];
}

-(GameObject*)Remove
{
    [[TouchSystem GetInstance] RemoveListener:self];
    
    [super Remove];
    
    return self;
}

+(void)InitDefaultParams:(UIListParams*)outParams
{
    outParams->mBoundingDims.mVector[x] = 0;
    outParams->mBoundingDims.mVector[y] = 0;
}

-(void)AddObject:(UIObject*)inObject
{
    NSAssert([inObject GetGameObjectBatch] == NULL, @"UIList cannot contain objects that belong to a GameObjectBatch.");
    [mUIObjects addObject:inObject];
    
    // UIObjects that are part of a UIList should not be registered with the TouchSystem, we will dispatch
    // events to them ourselves (since we need to filter them based on the size of this list, etc).
    
    [[TouchSystem GetInstance] RemoveListener:inObject];
}

-(UIObject*)GetObjectAtIndex:(u32)inIndex
{
    return [mUIObjects objectAtIndex:inIndex];
}

-(u32)GetNumObjects
{
    return [mUIObjects count];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    int totalY = 0;
    int maxWidth = 0;
    
    if (mTouchState == TOUCH_STATE_DOWN_SCROLL)
    {
        mOffsetYCurrent = mTouchPositionCurrent.mVector[y] - mTouchPositionScrollInitial.mVector[y];
    }
    
    int count = 0;
    
    for (UIObject* curObject in mUIObjects)
    {
        [curObject Update:inTimeStep];
        [curObject SetPositionX:0.0 Y:(int)((float)totalY + mOffsetYCurrent + mOffsetYTotal) Z:0.0];
                
        totalY += [curObject GetHeight];
        
        int width = [curObject GetWidth];
        
        if (width > maxWidth)
        {
            maxWidth = width;
        }
        
        count++;
    }
    
    if (mAutoHeight)
    {
        mParams.mBoundingDims.mVector[y] = ClampInt(totalY, 0, GetScreenVirtualHeight());
    }
    
    if (mAutoWidth)
    {
        mParams.mBoundingDims.mVector[x] = ClampInt(maxWidth, 0, GetScreenVirtualWidth());
    }
}

-(void)DrawOrtho
{
    Rect2D virtualRect;
    Rect2D screenRect;
    
    virtualRect.mXMin = mPosition.mVector[x];
    virtualRect.mXMax = mPosition.mVector[x] + mParams.mBoundingDims.mVector[x];
    
    virtualRect.mYMin = mPosition.mVector[y];
    virtualRect.mYMax = mPosition.mVector[y] + mParams.mBoundingDims.mVector[y];
    
    VirtualToScreenRect(&virtualRect, &screenRect);
    
    glEnable(GL_SCISSOR_TEST);

    glScissor(  screenRect.mXMin,
                GetScreenAbsoluteHeight() - screenRect.mYMax,
                screenRect.mXMax - screenRect.mXMin,
                screenRect.mYMax - screenRect.mYMin );
    
    for (UIObject* curObject in mUIObjects)
    { 
        if ([curObject GetVisible])
        {
            glPushMatrix();
            
            Matrix44 ltwTransform;
            [curObject GetLocalToWorldTransform:&ltwTransform];
            
            glMultMatrixf(ltwTransform.mMatrix);
            [curObject DrawOrtho];
            
            glPopMatrix();
        }
    }
    
    glDisable(GL_SCISSOR_TEST);
}

-(void)SetVisible:(BOOL)inVisible
{
    [super SetVisible:inVisible];
    
    for (UIObject* curObject in mUIObjects)
    {
        [curObject SetVisible:inVisible];
    }
}
    
-(void)Enable
{
    for (UIObject* curObject in mUIObjects)
    {
        [curObject Enable];
    }
}

-(void)Disable
{
    for (UIObject* curObject in mUIObjects)
    {
        [curObject Disable];
    }
}

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData
{
    Vector2 touchPoint;
    
    touchPoint.mVector[x] = inData->mTouchLocation.x;
    touchPoint.mVector[y] = inData->mTouchLocation.y;
    
    BOOL touchEvent = [self HitTestWithPoint:&touchPoint];
    
    switch(inData->mTouchType)
    {
        case TOUCHES_BEGAN:
        {
            // If we touched inside the boundaries of the list, then update our state
            // and save the touch position.
            if (touchEvent)
            {
                mTouchState = TOUCH_STATE_DOWN_SELECT;
                CloneVec2(&touchPoint, &mTouchPositionInitial);
            }
            
            // Objects think they are at the origin.  So we have to muck with the coordinates accordingly.
            TouchData* offsetTouchData = [[TouchData alloc] InitWithTouchData:inData];
            offsetTouchData->mTouchLocation.x -= mPosition.mVector[x];
            offsetTouchData->mTouchLocation.y -= mPosition.mVector[y];
            
            for (UIObject* curObject in mUIObjects)
            {
                if ([curObject conformsToProtocol:@protocol(TouchListenerProtocol)])
                {
                    UIObject<TouchListenerProtocol>* touchObject = (UIObject<TouchListenerProtocol>*)curObject;
                    [touchObject TouchEventWithData:offsetTouchData];
                }
            }
            
            [offsetTouchData release];
            
            break;
        }
        
        case TOUCHES_ENDED:
        {
            for (UIObject* curObject in mUIObjects)
            {
                if ([curObject conformsToProtocol:@protocol(TouchListenerProtocol)])
                {
                    UIObject<TouchListenerProtocol>* touchObject = (UIObject<TouchListenerProtocol>*)curObject;
                    [touchObject TouchEventWithData:inData];
                }
            }

            mTouchState = TOUCH_STATE_NONE;
            
            mOffsetYTotal += mOffsetYCurrent;
            mOffsetYCurrent = 0;

            break;
        }
        
        case TOUCHES_MOVED:
        {
            for (UIObject* curObject in mUIObjects)
            {
                if ([curObject conformsToProtocol:@protocol(TouchListenerProtocol)])
                {
                    UIObject<TouchListenerProtocol>* touchObject = (UIObject<TouchListenerProtocol>*)curObject;
                    [touchObject TouchEventWithData:inData];
                }
            }
            
            CloneVec2(&touchPoint, &mTouchPositionCurrent);
            
            [self EvaluateTouchMoved];
            
            break;
        }
    }
    
    return TOUCHSYSTEM_CONSUME_NONE;
}

-(BOOL)HitTestWithPoint:(Vector2*)inPoint
{
    BOOL hit = FALSE;
    
    if ((inPoint->mVector[x] >= mPosition.mVector[x]) &&
        (inPoint->mVector[y] >= mPosition.mVector[y]) &&
        (inPoint->mVector[x] <= (mPosition.mVector[x] + mParams.mBoundingDims.mVector[x])) &&
        (inPoint->mVector[y] <= (mPosition.mVector[y] + mParams.mBoundingDims.mVector[y])))
    {
        hit = TRUE;
    }
    
    return hit;
}

-(void)EvaluateTouchMoved
{
    Vector2 diff;
    Sub2(&mTouchPositionCurrent, &mTouchPositionInitial, &diff);
    
    if ((Length2(&diff) > MOVE_DISTANCE_MINIMUM) && (mTouchState == TOUCH_STATE_DOWN_SELECT))
    {
        mTouchState = TOUCH_STATE_DOWN_SCROLL;
        CloneVec2(&mTouchPositionCurrent, &mTouchPositionScrollInitial);
        
        TouchData* cancelledEvent = [TouchData alloc];
        
        cancelledEvent->mTouchType = TOUCHES_CANCELLED;
        cancelledEvent->mTouchLocation = CGPointMake(0.0f, 0.0f);
        
        for (UIObject* curObject in mUIObjects)
        {
            if ([curObject conformsToProtocol:@protocol(TouchListenerProtocol)])
            {
                NSObject<TouchListenerProtocol>* touchObject = (NSObject<TouchListenerProtocol>*)curObject;
                [touchObject TouchEventWithData:cancelledEvent];
            }
        }
        
        [cancelledEvent release];
    }
}

@end