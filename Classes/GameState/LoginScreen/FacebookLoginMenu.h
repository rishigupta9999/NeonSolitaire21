//
//  FacebookLoginMenu.h
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

#import "Button.h"
#import "GameState.h"
#import "UIGroup.h"
#import "GameStateMgr.h"
#import "GlobalUI.h"
#import "Fader.h"

typedef struct
{
    NSString*   texName;
    NSString*   toggleTexName;
    NSString*   glowName;
    UISoundId   soundID;
    Vector3     location;
} FacebookButton;

typedef enum
{
    FACEBOOK_LOGIN_MENU_NORMAL,
    FACEBOOK_LOGIN_MENU_ADVANCE,
    FACEBOOK_LOGIN_MENU_RETRY
} FacebookLoginMenuType;

@interface FacebookLoginMenuParams : NSObject
{
    FacebookLoginMenuType   mType;
}

-(FacebookLoginMenuParams*)InitWithType:(FacebookLoginMenuType)inType;
-(FacebookLoginMenuType)GetType;

@end

typedef enum
{
    FACEBOOKID_LOGIN,
    FACEBOOKID_GUEST,
    FACEBOOKID_NUM
} EFACEBOOKID;

@interface FacebookLoginMenu : GameState <ButtonListenerProtocol, UIAlertViewDelegate, FaderCallback>
{
    @protected
        NSString*       mBackground;
        UIGroup*        mUIObjects;
        NeonButton*     mButtons[FACEBOOKID_NUM];
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Update:(CFTimeInterval)inTimeStep;
//-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

//menu-wide
-(void)ActivateBackgroundWithUIGroup:(UIGroup*)inUIGroup;
-(void)ActivateButtons;
-(void)ExitMenu;

-(void)FadeComplete:(NSObject*)inObject;

@end
