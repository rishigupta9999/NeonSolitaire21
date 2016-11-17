//
//  PositionDirectionNavigator.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "Button.h"

typedef enum
{
    POSITION_DIRECTION_NAVIGATOR_POS_FORWARD,
    POSITION_DIRECTION_NAVIGATOR_POS_BACKWARD,
    POSITION_DIRECTION_NAVIGATOR_POS_LEFT,
    POSITION_DIRECTION_NAVIGATOR_POS_RIGHT,
    POSITION_DIRECTION_NAVIGATOR_POS_UP,
    POSITION_DIRECTION_NAVIGATOR_POS_DOWN,
    POSITION_DIRECTION_NAVIGATOR_DIR_PLUS_X,
    POSITION_DIRECTION_NAVIGATOR_DIR_MINUS_X,
    POSITION_DIRECTION_NAVIGATOR_DIR_PLUS_Y,
    POSITION_DIRECTION_NAVIGATOR_DIR_MINUS_Y,
    POSITION_DIRECTION_NAVIGATOR_DIR_PLUS_Z,
    POSITION_DIRECTION_NAVIGATOR_DIR_MINUS_Z,
    POSITION_DIRECTION_NAVIGATOR_NUM_BUTTONS,
    POSITION_DIRECTION_NAVIGATOR_INVALID_INDEX = POSITION_DIRECTION_NAVIGATOR_NUM_BUTTONS
} DebugCameraButtons;

@protocol PositionDirectionNavigatorCallback

-(void)PositionModified:(Vector3*)inPosition;
-(void)DirectionModified:(Vector3*)inDirection;

@end

typedef struct
{
    Vector2                                         mBaseButtonPosition;
    Vector3*                                        mTargetPosition;
    Vector3*                                        mTargetDirection;
    NSObject<PositionDirectionNavigatorCallback>*   mCallback;
} PositionDirectionNavigatorParams;

@interface PositionDirectionNavigator : NSObject<ButtonListenerProtocol>
{
    Button* mButtons[POSITION_DIRECTION_NAVIGATOR_NUM_BUTTONS];
    s32     mActiveButtonIndex;
    
    PositionDirectionNavigatorParams  mParams;
    Vector3 mShadowDirection;
}

-(PositionDirectionNavigator*)InitWithParams:(PositionDirectionNavigatorParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(PositionDirectionNavigatorParams*)outParams;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;

-(void)Resync;

-(s32)GetButtonIndex:(Button*)inButton;

@end