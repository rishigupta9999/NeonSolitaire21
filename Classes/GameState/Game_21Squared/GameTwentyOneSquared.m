//
//  GameTwentyOneSquared.m
//  Neon Engine
//
//  Copyright Neon Games LLC - 2011, All rights reserved.

#import "GameTwentyOneSquared.h"
#import "GameObjectManager.h"
#import "Flow.h"
#import "TextureButton.h"
#import "DebugManager.h"

#import "TwentyOneSquaredUI.h"
#import "TwentyOneSquaredEnvironment.h"

#import "CameraStateMgr.h"
#import "TwentyOneSquaredIntroCamera.h"

#import "CardManager.h"
#import "Card.h"
#import "UINeonEngineDefines.h"

@implementation GameTwentyOneSquared

static TwentyOneSquaredUI	*sTwentyOneSquaredUI;

-(void)Startup
{
	[ CompanionManager CreateInstance ]; 
	
    [super Startup];
 
	// TODO: Get Jokers from Flow State
	m21SqStateMachine					= [ (HandStateMachine21Sq* )				[HandStateMachine21Sq			alloc] InitWithGameTwentyOneSquared:self numJokers:2	];
	sTwentyOneSquaredUI					= [ (TwentyOneSquaredUI*				)	[TwentyOneSquaredUI				alloc] Init];
    m21SqEnvironment					= [ (TwentyOneSquaredEnvironment*		)	[TwentyOneSquaredEnvironment	alloc] Init];
	[self GetHSM]->mHand				= [(PlayerHand*)[PlayerHand alloc] Init];
	[ [CardManager GetInstance]			PreShuffleDeck:GAMETYPE_21SQUARED ];
    [ [CameraStateMgr GetInstance	]	Push:[TwentyOneSquaredIntroCamera alloc]];
	
}

-(void)Shutdown
{
	[sTwentyOneSquaredUI	release];
    [m21SqStateMachine		release];
    [m21SqEnvironment		release];
	[[self GetHSM]->mHand	removeAllObjects ];
	[[self GetHSM]->mHand	release];
	// Re-initialize the base deck.
	[ [CardManager GetInstance] RegisterDeckWithShuffle:TRUE TotalJokers:0 ];
    
	//[ [CardManager GetInstance] PreShuffleDeck:GAMETYPE_NEONBJ ];
    [super Shutdown];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [super Update:inTimeStep];
	[m21SqStateMachine		Update:inTimeStep];
}

-(void)Suspend
{
	// Remove non-projected UI elements from screen
	[ sTwentyOneSquaredUI TogglePause:TRUE];
}
-(void)Resume
{
	// Restore projected UI elements from screen
	[ sTwentyOneSquaredUI TogglePause:FALSE];
}

-(void)DrawOrtho
{
    char		myStr[256];
	CardManager *cardMan;
	Card		*nextCardToBeDealt;
	int			posY	= Score_X1 + 40;
	int			posX	= SidebarX - 110;
	int y,x;
	
	cardMan				= [CardManager GetInstance];
	if ( [cardMan-> mShoe count] - cardMan->mIndexNextCardDealt >= 1 )
	{
		nextCardToBeDealt	= [ cardMan->mShoe objectAtIndex:cardMan->mIndexNextCardDealt ];
		snprintf(myStr, 256, "Next [%s]", nextCardToBeDealt->mText );
	}
	else 
	{
		snprintf(myStr, 256, "End of Shoe" );
	}
	[[DebugManager GetInstance] DrawString: [NSString stringWithUTF8String:myStr] locX:posX + 30 locY:posY  ];
	
	for ( y = 0 ; y < NUMCARDS_LINE; y++ )
	{
		posY = 110 + ( y * 30 );
		for ( x = 0 ; x < NUMCARDS_LINE; x++ )
		{
			posX = 130 + ( x * 40 );
			Card *pCard = [self GetHSM]->mCard[y][x];
			
			if ( pCard )
			{
				snprintf(myStr, 256, "[%s]", pCard->mText );
				[[DebugManager GetInstance] DrawString: [NSString stringWithUTF8String:myStr] locX:posX locY:posY  ];
			}
		
		}
	}
	

	y		= 0;
	posY	= Score_X1; 
		
	for ( x = 0 ; x < NUMCARDS_LINE ; x++ )
	{
		posX = 130 + ( x * 40 );
		
		snprintf(myStr, 256, "(%d)", [self GetHSM]->mGridScore[y][x] );
		[[DebugManager GetInstance] DrawString: [NSString stringWithUTF8String:myStr] locX:posX locY:posY  ];
	}
	
	y		= 1;
	posX	= 50;
	
	for ( x = 0 ; x < NUMCARDS_LINE ; x++ )
	{
		posY = 110 + ( x * 30 );
		
		snprintf(myStr, 256, "(%d)", [self GetHSM]->mGridScore[y][x] );
		[[DebugManager GetInstance] DrawString: [NSString stringWithUTF8String:myStr] locX:posX locY:posY  ];
	}
	
}

-(HandStateMachine21Sq*)GetHSM
{
	return m21SqStateMachine;
}

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData
{
	CardManager				*cardMan	= [CardManager GetInstance];
	int x,y;

	switch ( inEventId )
	{
		case EVENT_21SQ_PLACE_CARD:
			for ( int i = 0 ; i < 25 ; i++ )
			{
				x = [[self GetHSM]->mHand count] % NUMCARDS_LINE;
				y = [[self GetHSM]->mHand count] / NUMCARDS_LINE;
				
				// As a temp hack, just place cards in order. top left, horizontally.
				[self GetHSM]->mCard[y][x] = [ cardMan DealCardWithFaceUp:true out_Hand:[self GetHSM]->mHand cardMode:CARDMODE_NORMAL];
			}
		
			[[self GetHSM] CalculateScores];
			break;
			
		default:
			break;
    }
	
	[super ProcessEvent:inEventId withData:inData];
}
@end

@implementation HandStateMachine21Sq

-(HandStateMachine21Sq*)InitWithGameTwentyOneSquared:(GameTwentyOneSquared*)inGameTwentyOneSquared numJokers:(int)inNumJokers
{

    mGameTwentyOneSquared = inGameTwentyOneSquared;
	mCompanionManager = [ CompanionManager GetInstance ];
	
	for ( int y = 0 ; y < GRID_NUM; y++ )
	{
		for ( int x = 0 ; x < NUMCARDS_LINE ; x++ )
		{
			mGridScore[y][x] = 0;
		}
	}
	
	return (HandStateMachine21Sq*)[super Init];
}

-(void)dealloc
{
	//[ mHand removeAllObjects ];
	//[ mHand release ];
    [CompanionManager DestroyInstance];
	
	
	[super dealloc];
}

-(void)CalculateScores
{
	int i,x,y;
	
	for ( x = 0, y = 0 ; x < NUMCARDS_LINE ; x++ )
	{
		mGridScore[y][x] = 0;
		// Calculate the column line score
		for ( i = 0; i < NUMCARDS_LINE; i++ )
		{
			mGridScore[y][x] += [mCard[i][x] GetScore];
		}
		
	}
	
	for ( x = 0, y = 1 ; x < NUMCARDS_LINE ; x++ )
	{
		mGridScore[y][x] = 0;
		// Calculate the row line score
		for ( i = 0; i < NUMCARDS_LINE; i++ )
		{
			mGridScore[y][x] += [mCard[x][i] GetScore];
		}
	}
}

@end