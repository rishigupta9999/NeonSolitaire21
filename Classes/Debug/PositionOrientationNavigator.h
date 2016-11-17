//
//  PositionOrientationNavigator.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "Button.h"

typedef enum
{
    POSITION_ORIENTATION_NAVIGATOR_POS_FORWARD,
    POSITION_ORIENTATION_NAVIGATOR_POS_BACKWARD,
    POSITION_ORIENTATION_NAVIGATOR_POS_LEFT,
    POSITION_ORIENTATION_NAVIGATOR_POS_RIGHT,
    POSITION_ORIENTATION_NAVIGATOR_POS_UP,
    POSITION_ORIENTATION_NAVIGATOR_POS_DOWN,
    POSITION_ORIENTATION_NAVIGATOR_ORI_PLUS_X,
    POSITION_ORIENTATION_NAVIGATOR_ORI_MINUS_X,
    POSITION_ORIENTATION_NAVIGATOR_ORI_PLUS_Y,
    POSITION_ORIENTATION_NAVIGATOR_ORI_MINUS_Y,
    POSITION_ORIENTATION_NAVIGATOR_ORI_PLUS_Z,
    POSITION_ORIENTATION_NAVIGATOR_ORI_MINUS_Z,
    POSITION_ORIENTATION_NAVIGATOR_NUM_BUTTONS,
    POSITION_ORIENTATION_NAVIGATOR_INVALID_INDEX = POSITION_ORIENTATION_NAVIGATOR_NUM_BUTTONS
} DebugCameraButtons;

@protocol PositionOrientationNavigatorCallback

-(void)PositionModified:(Vector3*)inPosition;
-(void)OrientationModified:(Vector3*)inLookAt;

@end

typedef struct
{
    Vector2                                     mBaseButtonPosition;
    Vector3*                                    mTargetPosition;
    Vector3*                                    mTargetOrientation;
    NSObject<PositionOrientationNavigatorCallback>*  mCallback;
} PositionOrientationNavigatorParams;

@interface PositionOrientationNavigator : NSObject<ButtonListenerProtocol>
{
    Button* mButtons[POSITION_ORIENTATION_NAVIGATOR_NUM_BUTTONS];
    s32     mActiveButtonIndex;
    
    PositionOrientationNavigatorParams  mParams;
}

-(PositionOrientationNavigator*)InitWithParams:(PositionOrientationNavigatorParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(PositionOrientationNavigatorParams*)outParams;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;

-(s32)GetButtonIndex:(Button*)inButton;

@end