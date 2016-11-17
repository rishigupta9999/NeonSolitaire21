//
//  TwentyOneSquaredUI.m
//  Neon Engine
//
//  Copyright Neon Games LLC - 2011, All rights reserved.


#import "TwentyOneSquaredUI.h"
#import "GameTwentyOneSquared.h"
#import "UINeonEngineDefines.h"

@implementation TwentyOneSquaredUI

-(TwentyOneSquaredUI*)Init
{
	[self uiAlloc];
	// Alloc the UIGroup
	GameObjectBatchParams uiGroupParams;
    [GameObjectBatch InitDefaultParams:&uiGroupParams];
    uiGroupParams.mUseAtlas = TRUE;
    mUserInterface[UIGROUP_2D] = [(UIGroup*)[UIGroup alloc] InitWithParams:&uiGroupParams];
    [[GameObjectManager GetInstance] Add:mUserInterface[UIGROUP_2D]];
	[self InitDebugButtons];
    [mUserInterface[UIGROUP_2D] release];
	
	[mUserInterface[UIGROUP_2D] Finalize];
	
	return self;
}

-(void)InitDebugButtons
{
	// Draw a "place card button"
	// mDebugButton
	
	NeonButtonParams				buttonParams;
	int								buttonColor		= 0xFFFFFFFF;
	
    [NeonButton InitDefaultParams:	&buttonParams];
	
	buttonParams.mTexName					= [NSString stringWithUTF8String:"button_place_card_row3.papng"];
    buttonParams.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:"button_place_card_row3_glow.papng"];
    buttonParams.mUISoundId					= SFX_BLACKJACK_HIT;
	buttonParams.mText						= [NSString stringWithUTF8String:"21 Sq." ];
	buttonParams.mTextSize					= 12;
    buttonParams.mBorderSize				= 1;
    buttonParams.mQuality					= NEON_BUTTON_QUALITY_HIGH;
    buttonParams.mUIGroup					= mUserInterface[UIGROUP_2D];
    buttonParams.mBoundingBoxCollision		= TRUE;
    SetVec2(&buttonParams.mBoundingBoxBorderSize, 2, 2);
	SetColorFromU32(&buttonParams.mTextColor, buttonColor);
	
	mDebugButton = [(NeonButton*)[NeonButton alloc] InitWithParams:&buttonParams];
	[mDebugButton Enable];
	
	[mDebugButton SetVisible:TRUE];
    [mDebugButton SetPositionX:330 Y:230 Z:0.0];
	[mDebugButton SetListener:self];
	[mDebugButton release];
	
	buttonParams.mTexName					= [NSString stringWithUTF8String:"button_pause.papng"];
    buttonParams.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:"button_pause_glow.papng"];
    mPauseButton = [(NeonButton*)[NeonButton alloc] InitWithParams:&buttonParams		];
    [mPauseButton release];
    
    [mPauseButton SetListener:self];
    [mPauseButton SetPositionX:0 Y:0 Z:0];
    
}

-(void)dealloc
{
	[super dealloc];
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
	if ( BUTTON_EVENT_UP == inEvent )
	{
		if ( mDebugButton == inButton )
		{
			[ [GameStateMgr GetInstance] SendEvent:EVENT_21SQ_PLACE_CARD withData:NULL ];
		
		}
		else if ( mPauseButton == inButton )
		{
			[ [GameStateMgr GetInstance] Push:[PauseMenu alloc] ];
		}
	
	
	}
	return;
}


-(void)TogglePause:(BOOL)bSuspend
{

}

@end