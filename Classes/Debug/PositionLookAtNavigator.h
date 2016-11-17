//
//  PositionLookAtNavigator.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "Button.h"

typedef enum
{
    POSITION_LOOKAT_NAVIGATOR_POS_FORWARD,
    POSITION_LOOKAT_NAVIGATOR_POS_BACKWARD,
    POSITION_LOOKAT_NAVIGATOR_POS_LEFT,
    POSITION_LOOKAT_NAVIGATOR_POS_RIGHT,
    POSITION_LOOKAT_NAVIGATOR_POS_UP,
    POSITION_LOOKAT_NAVIGATOR_POS_DOWN,
    POSITION_LOOKAT_NAVIGATOR_LA_FORWARD,
    POSITION_LOOKAT_NAVIGATOR_LA_BACKWARD,
    POSITION_LOOKAT_NAVIGATOR_LA_LEFT,
    POSITION_LOOKAT_NAVIGATOR_LA_RIGHT,
    POSITION_LOOKAT_NAVIGATOR_LA_UP,
    POSITION_LOOKAT_NAVIGATOR_LA_DOWN,
    POSITION_LOOKAT_NAVIGATOR_FOV_PLUS,
    POSITION_LOOKAT_NAVIGATOR_FOV_MINUS,
    POSITION_LOOKAT_NAVIGATOR_NUM_BUTTONS,
    POSITION_LOOKAT_NAVIGATOR_INVALID_INDEX = POSITION_LOOKAT_NAVIGATOR_NUM_BUTTONS
} DebugCameraButtons;

@protocol PositionLookAtNavigatorCallback

-(void)PositionModified:(Vector3*)inPosition;
-(void)LookAtModified:(Vector3*)inLookAt;

@end

typedef struct
{
    Vector2                                     mBaseButtonPosition;
    Vector3*                                    mTargetPosition;
    Vector3*                                    mTargetLookAt;
    float*                                      mTargetFovDegrees;
    NSObject<PositionLookAtNavigatorCallback>*  mCallback;
} PositionLookAtNavigatorParams;

@interface PositionLookAtNavigator : NSObject<ButtonListenerProtocol>
{
    Button* mButtons[POSITION_LOOKAT_NAVIGATOR_NUM_BUTTONS];
    s32     mActiveButtonIndex;
    
    PositionLookAtNavigatorParams  mParams;
}

-(PositionLookAtNavigator*)InitWithParams:(PositionLookAtNavigatorParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(PositionLookAtNavigatorParams*)outParams;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;

-(s32)GetButtonIndex:(Button*)inButton;

@end