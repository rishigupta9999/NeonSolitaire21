//
//  UIList.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "GameObject.h"
#import "NeonMath.h"
#import "TouchSystem.h"

@class UIObject;

typedef struct
{
    Vector2 mBoundingDims;
} UIListParams;

typedef enum
{
    TOUCH_STATE_NONE,
    TOUCH_STATE_DOWN_SELECT,
    TOUCH_STATE_DOWN_SCROLL
} UIListTouchState;

@interface UIList : GameObject<TouchListenerProtocol>
{
    UIListParams        mParams;
    NSMutableArray*     mUIObjects;
        
    BOOL                mAutoHeight;
    BOOL                mAutoWidth;
    
    Vector2             mTouchPositionInitial;
    Vector2             mTouchPositionScrollInitial;
    Vector2             mTouchPositionCurrent;
    UIListTouchState    mTouchState;
    
    float               mOffsetYTotal;
    float               mOffsetYCurrent;
}

-(UIList*)InitWithParams:(UIListParams*)inParams;
-(void)dealloc;
-(GameObject*)Remove;

+(void)InitDefaultParams:(UIListParams*)outParams;

-(void)AddObject:(UIObject*)inObject;
-(UIObject*)GetObjectAtIndex:(u32)inIndex;
-(u32)GetNumObjects;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;

-(void)SetVisible:(BOOL)inVisible;
-(void)Enable;
-(void)Disable;

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData;
-(BOOL)HitTestWithPoint:(Vector2*)inPoint;

-(void)EvaluateTouchMoved;

@end