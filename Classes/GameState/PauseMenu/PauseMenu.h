//
//  PauseMenu.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "GameState.h"
#import "Button.h"
#import "CardDefines.h"

@class UIGroup;

typedef enum
{
	PAUSE_SUB_MENU_MAIN,
    PAUSE_SUB_MENU_CONFIRM_EXIT,
	PAUSE_SUB_MENU_LEAVE,
	PAUSE_SUB_MENU_LEAVE_MAINMENU,
	PAUSE_SUB_MENU_LEAVE_SKIPAHEAD,
	PAUSE_SUB_MENU_LEAVE_RETRY,
    PAUSE_SUB_MENU_OPTIONS,
    PAUSE_SUB_MENU_INVALID
} PauseSubMenu;

typedef enum
{
    PAUSE_SUB_MENU_ACTION_COMPANIONS,
    PAUSE_SUB_MENU_ACTION_OPTIONS,
    PAUSE_SUB_MENU_ACTION_MAIN,
    PAUSE_SUB_MENU_RESUME_GAME,
    PAUSE_SUB_MENU_ACTION_RETURN_TO_PAUSE,
    PAUSE_SUB_MENU_ACTION_EXIT_GAME,
	PAUSE_SUB_MENU_ACTION_RESTART_GAME,
	PAUSE_SUB_MENU_ACTION_LEAVE,
	PAUSE_SUB_MENU_ACTION_LEAVE_MAINMENU,
	PAUSE_SUB_MENU_ACTION_LEAVE_SKIPAHEAD,
	PAUSE_SUB_MENU_ACTION_LEAVE_RETRY,
    PAUSE_SUB_MENU_ACTION_TOGGLE_SOUND,
    PAUSE_SUB_MENU_ACTION_TOGGLE_MUSIC,
    PAUSE_SUB_MENU_ACTION_NUM
} PauseSubMenuAction;

@interface PauseMenuRefillLivesDelegate : NSObject <UIAlertViewDelegate>

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface PauseMenu : GameState<ButtonListenerProtocol>
{
    UIGroup*        mUIGroup;
    PauseSubMenu    mActiveMenu;
    
    PauseMenuRefillLivesDelegate *mRefillLivesDelegate;
    
    u32      mNumButtons;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData;

-(void)ActivateMenu:(PauseSubMenu)inSubMenu;
-(void)LeaveMenu;
-(void)InitMenu:(PauseSubMenu)inSubMenu;
-(void)InitBackButton:(PauseSubMenuAction)inBackButtonAction;
-(void)InitLogo;
-(void)InitMenuToggle:(PauseSubMenuAction)linkMenuID withSuit:(CardSuit)suitID withOn:(BOOL)bToggledOn withEnabled:(BOOL)bEnabled;
-(void)InitTextBox:(NSString*)str;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end

