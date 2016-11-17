//
//  GlobalUI.h
//  Neon Engine
//
//  Copyright Neon Games LLC - 2011
//  All Cross-Game / Cross-SKU UI Functionality

#import "UINeonEngineDefines.h"
#import "NeonButton.h"
#import "NeonColorDefines.h"
#import "MultiStateButton.h"
#import "CharMap.h"
#import "CardDefines.h"
#import "Flow.h"

// Forward Declarations
@class ImageWell;
@class TextBox;
@class HandStateMachine;
@class PlayerHand;
@class MultiStateButton;
@class TextureButton;

typedef enum
{
	NEONFONT_FIRST,
	NEONFONT_BLUE		= NEONFONT_FIRST,
	NEONFONT_YELLOW,
	NEONFONT_LAST		= NEONFONT_YELLOW,
	NEONFONT_NUM,
} ENeonFontColor;

typedef enum
{
	UIGROUP_FIRST,
	UIGROUP_2D				= UIGROUP_FIRST,
	UIGROUP_Projected3D,
	UIGROUP_LAST			= UIGROUP_Projected3D,
	UIGROUP_NUM
} EUIGroup;

@interface GlobalUI : NSObject <ButtonListenerProtocol> 
{
	@protected
	CharMap		*mCharMap[NEONFONT_NUM];
	UIGroup		*mUserInterface[UIGROUP_NUM];
}

-(void)uiAlloc;
-(void)dealloc;
-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;
-(void)InitFonts;
-(void)DeallocFonts;
-(void)InitFont:(ENeonFontColor)fontID;
-(void)DeallocUserInterface;

-(TextBox*)InitTextBoxWithFontColor:(ENeonFontColor)inFontColor uiGroup:(UIGroup*)uiGroup;
-(TextBox*)InitTextBoxWithFontColor:(ENeonFontColor)inFontColor fontType:(NeonFontType)inFontType uiGroup:(UIGroup*)inUIGroup;

-(NSMutableArray*)GetButtonArray;

@end