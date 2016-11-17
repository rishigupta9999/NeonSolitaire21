//
//  PositionDirectionNavigator.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "PositionDirectionNavigator.h"
#import "GameObjectManager.h"
#import "TextureButton.h"

#import "DebugManager.h"

static const char*  sButtonNames[POSITION_DIRECTION_NAVIGATOR_NUM_BUTTONS] = { "Pos F", "Pos B", "Pos L", "Pos R", "Pos U", "Pos D",
                                                                               "Dir +X", "Dir -X", "Dir +Y", "Dir -Y", "Dir +Z", "Dir -Z" };

static Vector2      sButtonCoords[POSITION_DIRECTION_NAVIGATOR_NUM_BUTTONS] = { { 40.0f, 240.0f },
                                                                                { 40.0f, 270.0f },
                                                                                { 110.0f, 240.0f },
                                                                                { 110.0f, 270.0f },
                                                                                { 180.0f, 240.0f },
                                                                                { 180.0f, 270.0f },
                                                                                { 250.0f, 240.0f },
                                                                                { 250.0f, 270.0f },
                                                                                { 320.0f, 240.0f },
                                                                                { 320.0f, 270.0f },
                                                                                { 390.0f, 240.0f },
                                                                                { 390.0f, 270.0f } };
                                                                                    
static const float  MOVE_AMOUNT = 0.1f;

@implementation PositionDirectionNavigator

-(PositionDirectionNavigator*)InitWithParams:(PositionDirectionNavigatorParams*)inParams
{
    TextureButtonParams    params;
    
    // Get the default values set up for the parameters.
    [TextureButton InitDefaultParams:&params];
        
    params.mFontSize = 14;
    params.mFontColor = 0xFF000000;
    params.mButtonTexBaseName = @"editorbutton.png";
    params.mButtonTexHighlightedName = @"editorbutton_lit.png";
    
    SetRelativePlacement(&params.mTextPlacement, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
    
    for (int i = 0; i < POSITION_DIRECTION_NAVIGATOR_NUM_BUTTONS; i++)
    {
        params.mButtonText = [NSString stringWithUTF8String:sButtonNames[i]];
        
        mButtons[i] = [(TextureButton*)[TextureButton alloc] InitWithParams:&params];
        [mButtons[i] SetListener:self];
        
        [[GameObjectManager GetInstance] Add:mButtons[i]];
        
        [mButtons[i] SetPositionX:sButtonCoords[i].mVector[x] Y:sButtonCoords[i].mVector[y] Z:0.0f];
    }
    
    mActiveButtonIndex = POSITION_DIRECTION_NAVIGATOR_INVALID_INDEX;
    
    memcpy(&mParams, inParams, sizeof(PositionDirectionNavigatorParams));
    
    CloneVec3(mParams.mTargetDirection, &mShadowDirection);

    return self;
}

-(void)dealloc
{
    for (int i = 0; i < POSITION_DIRECTION_NAVIGATOR_NUM_BUTTONS; i++)
    {
        [mButtons[i] Remove];
        [[GameObjectManager GetInstance] Remove:mButtons[i]];
    }
    
    [super dealloc];
}

+(void)InitDefaultParams:(PositionDirectionNavigatorParams*)outParams
{
    SetVec2(&outParams->mBaseButtonPosition, 0.0f, 0.0f);
    outParams->mTargetPosition = NULL;
    outParams->mTargetDirection = NULL;
    outParams->mCallback = NULL;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    switch(mActiveButtonIndex)
    {
        case POSITION_DIRECTION_NAVIGATOR_POS_FORWARD:
        {
            mParams.mTargetPosition->mVector[z] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_DIRECTION_NAVIGATOR_POS_BACKWARD:
        {
            mParams.mTargetPosition->mVector[z] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_DIRECTION_NAVIGATOR_POS_LEFT:
        {
            mParams.mTargetPosition->mVector[x] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_DIRECTION_NAVIGATOR_POS_RIGHT:
        {
            mParams.mTargetPosition->mVector[x] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_DIRECTION_NAVIGATOR_POS_DOWN:
        {
            mParams.mTargetPosition->mVector[y] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_DIRECTION_NAVIGATOR_POS_UP:
        {
            mParams.mTargetPosition->mVector[y] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_DIRECTION_NAVIGATOR_DIR_PLUS_X:
        {
            mShadowDirection.mVector[x] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_DIRECTION_NAVIGATOR_DIR_MINUS_X:
        {
            mShadowDirection.mVector[x] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_DIRECTION_NAVIGATOR_DIR_PLUS_Y:
        {
            mShadowDirection.mVector[y] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_DIRECTION_NAVIGATOR_DIR_MINUS_Y:
        {
            mShadowDirection.mVector[y] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_DIRECTION_NAVIGATOR_DIR_PLUS_Z:
        {
            mShadowDirection.mVector[z] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_DIRECTION_NAVIGATOR_DIR_MINUS_Z:
        {
            mShadowDirection.mVector[z] -= MOVE_AMOUNT;
            break;
        }

        case POSITION_DIRECTION_NAVIGATOR_INVALID_INDEX:
        {
            // Don't do anything here.
            break;
        }
    }
    
    // Clamp all components to [-1..1]
    mShadowDirection.mVector[x] = ClampFloat(mShadowDirection.mVector[x], -1.0f, 1.0f);
    mShadowDirection.mVector[y] = ClampFloat(mShadowDirection.mVector[y], -1.0f, 1.0f);
    mShadowDirection.mVector[z] = ClampFloat(mShadowDirection.mVector[z], -1.0f, 1.0f);
    
    // Copy and normalize
    CloneVec3(&mShadowDirection, mParams.mTargetDirection);
    Normalize3(mParams.mTargetDirection);
                
    
    // If a callback object was provided, then inform it if there were any changes
    if (mParams.mCallback != NULL)
    {
        if (mActiveButtonIndex != POSITION_DIRECTION_NAVIGATOR_INVALID_INDEX)
        {
            if ((mActiveButtonIndex >= POSITION_DIRECTION_NAVIGATOR_POS_FORWARD) && (mActiveButtonIndex <= POSITION_DIRECTION_NAVIGATOR_POS_DOWN))
            {
                [mParams.mCallback PositionModified:mParams.mTargetPosition];
            }
            else if ((mActiveButtonIndex >= POSITION_DIRECTION_NAVIGATOR_DIR_PLUS_X) && (mActiveButtonIndex <= POSITION_DIRECTION_NAVIGATOR_DIR_MINUS_Z))
            {
                [mParams.mCallback DirectionModified:mParams.mTargetDirection];
            }
        }
    }
}

-(void)DrawOrtho
{
    [[DebugManager GetInstance] DrawString:[NSString    stringWithFormat:@"Position: %f, %f, %f",
                                                        mParams.mTargetPosition->mVector[x],
                                                        mParams.mTargetPosition->mVector[y],
                                                        mParams.mTargetPosition->mVector[z]]
                                                        locX:10 locY:150];
                                                        
    [[DebugManager GetInstance] DrawString:[NSString    stringWithFormat:@"Unnormalized Direction:\n%f, %f, %f",
                                                        mShadowDirection.mVector[x],
                                                        mShadowDirection.mVector[y],
                                                        mShadowDirection.mVector[z]]
                                                        locX:10 locY:170];
}

-(void)Resync
{
    CloneVec3(mParams.mTargetDirection, &mShadowDirection);
}

-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if ((inEvent == BUTTON_EVENT_DOWN) || (inEvent == BUTTON_EVENT_RESUMED))
    {
        mActiveButtonIndex = [self GetButtonIndex:inButton];
    }
    else if ((inEvent == BUTTON_EVENT_UP) || (inEvent == BUTTON_EVENT_CANCELLED))
    {
        mActiveButtonIndex = POSITION_DIRECTION_NAVIGATOR_INVALID_INDEX;
    }
    
    return TRUE;
}

-(s32)GetButtonIndex:(Button*)inButton
{
    s32 retVal = POSITION_DIRECTION_NAVIGATOR_INVALID_INDEX;
    
    for (int i = 0; i < POSITION_DIRECTION_NAVIGATOR_NUM_BUTTONS; i++)
    {
        if (inButton == mButtons[i])
        {
            retVal = i;
            break;
        }
    }
    
    return retVal;
}

@end