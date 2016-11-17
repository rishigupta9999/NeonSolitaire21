//
//  OverlayState.h
//  Neon21
//
//  Copyright Neon Games 2014. All rights reserved.
//

#import "GameState.h"
#import "Button.h"

typedef enum
{
    OVERLAY_ID_LEVEL_SELECT,
    OVERLAY_ID_NUM,
    OVERLAY_ID_INVALID = OVERLAY_ID_NUM
} OverlayId;

@class TextureButton;
@class UIGroup;

@interface OverlayStateParams : NSObject
{
}

@property OverlayId OverlayId;

-(OverlayStateParams*)init;

@end

@interface OverlayState : GameState<ButtonListenerProtocol>
{
    TextureButton*  mBackground;
    UIGroup*        mUIGroup;
    TextureButton*  mOKButton;
    
    NSMutableArray* mOverlayEntries;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)SetupBackground;
-(void)AnalyzeOverlayEntries;

-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end