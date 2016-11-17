//
//  CompanionSelect.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "CompanionSelect.h"
#import "Companion.h"
#import "CompanionEntity.h"
#import "CameraStateMgr.h"
#import "CompanionSelectCamera.h"
#import "GameObjectManager.h"
#import "GameStateMgr.h"

#import "UIGroup.h"
#import "NeonButton.h"
#import "TextBox.h"
#import "TextTextureBuilder.h"
#import "UINeonEngineDefines.h"

#define COMPANIONSELECTION_X_PADDING	(25.0f)
#define COMPANIONSELECTION_OFFSET_X		(65)
#define COMPANIONSELECTION_OFFSET_Y		(77)
#define NUM_PULSES						2

static NSString*	sTransparentTexture		= @"companionboundingbox.papng";

static const Vector3 sCompanionTextPositions[COMPANION_POSITION_CHANGEABLE_NUM] = 
{ { 10.0f, 190.0f, 0.0f}, { 10.0f, 240.0f, 0.0f } };
static const Vector3 sCompanionButtonPositions[COMPANION_POSITION_CHANGEABLE_NUM] = 
{ { COMPANIONSELECTION_X_PADDING, 160.0f, 0.0f }, { 410.0f, 160.0f, 0.0f } };

static Vector3 sAbilityLoc[COMPANION_POSITION_PLAYER] = 
{ { 100.0f, 60.0f, 0.0f }, { 300.0f, 60.0f, 0.0f }, {0,0,0} };

static Vector3 sCompanionButtonPosition[COMPANION_POSITION_MAX] = 
{ { 0, 60.0f, 0.0f }, { 352.0f, 60.0f, 0.0f }, {176,60,0}, {0,0,0} };

static Vector3 sDialogBaloonLocation = { 60.f, 0.f, 0.0f};

static const char*	sAbilityImages[CompID_MAX]	=	{
									"button_stay.papng",						// CompID_Empty
									"button_hit.papng",							// CompID_Polly
									"button_companion_amber_double.papng",		// CompID_Amber
									"button_betty.papng",						// CompID_Betty
									"button_cathy.papng",						// CompID_Cathy
									"button_companion_johnny_swap.papng",		// CompID_Johnny
									"button_companion_panda_surrender.papng",	// CompID_Panda
									"button_companion_vut_hit.papng",			// CompID_NunaVut
									"button_companion_igunaq_redo.papng",		// CompID_Igunaq
									"button_companion_doncappo_split.papng",	// CompID_DonCappo
													};

#define GET_ACTIVE_STATE() ( (CompanionSelectState*)(mStateMachine->mActiveState) )
#define GET_STATE_MACHINE() ( (CompanionSelectStateMachine*)(mStateMachine) )

#define COMPANION_BUTTON_PADDING     (8.0f)
#define COMPANION_BUTTON_Y_OFFSET    (8.0f)

#define COMPANION_ANIMATION_DURATION (1.2f)



@implementation CompanionSelectState

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton
{
}

-(void)InitDialogBaloon:(ImageTextHolder*)inToolTip
{
	ImageWellParams imageWellparams;
	[ImageWell InitDefaultParams:&imageWellparams];
	imageWellparams.mTextureName	= [NSString stringWithUTF8String:"dealerspeechbox.papng"];
	
	inToolTip->mImage	=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
	[inToolTip->mImage		SetPosition:&sDialogBaloonLocation];
	//[inToolTip->mImage	SetScale:&];
	[inToolTip->mImage		SetVisible:TRUE];
	//[inToolTip->mImage		release];
	[[GameObjectManager GetInstance] Add:inToolTip->mImage];

}

-(void)ClearDialogBaloon:(ImageTextHolder*)inToolTip
{
	[[GameObjectManager GetInstance] Remove:inToolTip->mImage];
}

-(void)InitToolTip:(ImageTextHolder*)inToolTip WithDialog:(NSString*)inStr
{
	[ self InitDialogBaloon:inToolTip ];
	
	TextBoxParams textBoxParams;
    [TextBox InitDefaultParams:&textBoxParams];
    
    textBoxParams.mString = NSLocalizedString( inStr, NULL );
    textBoxParams.mFontType = NEON_FONT_NORMAL;
    textBoxParams.mFontSize = 12.0f;
    SetColorFromU32(&textBoxParams.mColor, NEON_BLA);
    
    inToolTip->mText = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    [inToolTip->mText SetVisible:FALSE];
    [inToolTip->mText Enable];
	
	PlacementValue placementValue;
	SetRelativePlacement(&placementValue, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
    [inToolTip->mText SetPlacement:&placementValue];
    
    [inToolTip->mText SetPositionX:240 Y:25 Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:inToolTip->mText];
	
	// Todo: Not releaseing the alloc
}

-(void)ClearToolTip:(ImageTextHolder*)inToolTip
{
	[self ClearDialogBaloon:inToolTip];
	[inToolTip->mText Disable];
    [inToolTip->mText RemoveAfterOperations];
}

@end

@implementation CompanionSelectRootState

-(void)Startup
{
    [super Startup];
	
	[ self InitToolTip:&mToolTip_Stage1 WithDialog:@"LS_Stage1" ];

    GET_STATE_MACHINE()->mEditCompanion = COMPANION_POSITION_INVALID;
	
	Companion* dealerCompanion = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_DEALER];
	[ dealerCompanion->mEntity Pulse:NUM_PULSES ];
	
    mHackTime = 0.0f;
    mHackAnimationStarted = FALSE;
}

-(void)Resume
{
    [super Resume];
    
    [mToolTip_Stage1.mText Enable];
	[GET_STATE_MACHINE() UpdateCompanionAbilitySeats];
}

-(void)Shutdown
{
    [super Shutdown];
}

-(void)Suspend
{
    [super Suspend];
    
    [mToolTip_Stage1.mText Disable];
}

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton
{
    if (inEvent == BUTTON_EVENT_UP)
    {
        NeonButton* leftButton = GET_STATE_MACHINE()->mLeftButton;
        NeonButton* rightButton = GET_STATE_MACHINE()->mRightButton;
        
        if (inButton == GET_STATE_MACHINE()->mBackButton)
        {
            [self ClearToolTip:&mToolTip_Stage1];
        }
        else if ((inButton == leftButton) || (inButton == rightButton))
        {
            NeonButton* activeButton = inButton;
            NeonButton* inactiveButton = NULL;
            
            if (inButton == leftButton)
            {
                inactiveButton = rightButton;
            }
            else
            {
                inactiveButton = leftButton;
            }
                        
            [GET_STATE_MACHINE() SetEditCompanion:((activeButton == leftButton) ? COMPANION_POSITION_LEFT : COMPANION_POSITION_RIGHT)];
            [GET_STATE_MACHINE() Push:[CompanionSelectTransitionToChangeCompanion alloc]];
        }
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [super Update:inTimeStep];
    
    mHackTime += inTimeStep;

#if 0    
    if ((mHackTime >= 5.0f) && (!mHackAnimationStarted))
    {
        Companion* leftCompanion = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_LEFT];
        CompanionEntity* leftCompanionEntity = leftCompanion->mEntity;
        
        Companion* rightCompanion = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_RIGHT];
        CompanionEntity* rightCompanionEntity = rightCompanion->mEntity;
        
        [rightCompanionEntity PerformAction:COMPANION_ACTION_WALK_TO_TABLE_RIGHT];
        //[leftCompanionEntity PerformAction:COMPANION_ACTION_WALK_TO_TABLE_LEFT];
        mHackAnimationStarted = TRUE;
    }
#endif
}

@end


@implementation CompanionSelectTransitionToChangeCompanion

-(void)Startup
{
    [super Startup];
        
    CompanionPosition editPosition	= GET_STATE_MACHINE()->mEditCompanion;
	NeonButton* leftButton			= GET_STATE_MACHINE()->mLeftButton;
	NeonButton* rightButton			= GET_STATE_MACHINE()->mRightButton;
    NeonButton* activeButton		= NULL;
    NeonButton* inactiveButton		= NULL;
    
    // Make the portrait corresponding to the companion not being edited, inactive.
    switch(editPosition)
    {
        case COMPANION_POSITION_LEFT:
        {
            [rightButton SetActive:FALSE];
			inactiveButton	= rightButton;
            activeButton	= leftButton;
            break;
        }
        
        case COMPANION_POSITION_RIGHT:
        {
            [leftButton SetActive:FALSE];
            activeButton	= rightButton;
            inactiveButton	= leftButton;
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown companion being edited");
            break;
        }
    }
    
    [activeButton	SetPulseAmount:1.0f time:0.25f];
    [inactiveButton SetPulseAmount:0.0f time:0.25f];

    // Show the icons corresponding to companions that can be swapped in.
    Vector3* startPosition;
    
    startPosition = (Vector3*)&sCompanionButtonPositions[editPosition];
    
    [GET_STATE_MACHINE() UpdateCompanionButtonVisibility:startPosition animationTime:0.5f];
}

-(void)Resume
{
    [super Resume];
}

-(void)Shutdown
{
    [super Shutdown];
}

-(void)Suspend
{
    [super Suspend];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if ([GET_STATE_MACHINE()->mUIGroup GroupCompleted])
    {
        [mStateMachine ReplaceTop:[CompanionSelectChangeCompanion alloc]];
    }
}

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton
{
    // Intentionally do nothing during the transition state
}

@end


@implementation CompanionSelectTransitionFromChangeCompanion

-(void)Startup
{
    [super Startup];
    
    CompanionPosition editCompanion = GET_STATE_MACHINE()->mEditCompanion;
    NeonButton* activeButton = NULL;
    
    // Make the portrait corresponding to the companion not being edited, inactive.
    switch(editCompanion)
    {
        case COMPANION_POSITION_LEFT:
        {
            [GET_STATE_MACHINE()->mRightButton SetActive:TRUE];
            
            activeButton = GET_STATE_MACHINE()->mLeftButton;
            
            break;
        }
        
        case COMPANION_POSITION_RIGHT:
        {
            [GET_STATE_MACHINE()->mLeftButton SetActive:TRUE];
            
            activeButton = GET_STATE_MACHINE()->mRightButton;
            
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown companion being edited");
            break;
        }
    }
    
    [GET_STATE_MACHINE()->mLeftButton ResumePulse:0.5f];
    [GET_STATE_MACHINE()->mRightButton ResumePulse:0.5f];
    
    Vector3 endPosition;
    [activeButton GetPositionWithoutPlacement:&endPosition];
            
    for (NeonButton* curButton in GET_STATE_MACHINE()->mCompanionButtons)
    {
        if ((curButton != GET_STATE_MACHINE()->mLeftButton) && (curButton != GET_STATE_MACHINE()->mRightButton))
        {
            if ((curButton->mIdentifier == CompID_Empty) && (curButton != GET_STATE_MACHINE()->mEmptyButton[GET_STATE_MACHINE()->mEditCompanion]))
            {
                continue;
            }
            
            [curButton Disable];
            
            Path* newPath = [(Path*)[Path alloc] Init];
            
            Vector3 startPosition;
            [curButton GetPositionWithoutPlacement:&startPosition];
            
            [newPath AddNodeVec3:&startPosition atTime:0.0f];
            [newPath AddNodeVec3:&endPosition atTime:0.5f];
            
            [curButton AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:newPath];
            
            [newPath release];
        }
    }
}

-(void)Resume
{
    [super Resume];
}

-(void)Shutdown
{
    [super Resume];
}

-(void)Suspend
{
    [super Suspend];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if ([GET_STATE_MACHINE()->mUIGroup GroupCompleted])
    {
        [mStateMachine Pop];
    }
}

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton
{
}

@end

@implementation CompanionSelectChangeCompanion

-(void)Startup
{
    [ self InitToolTip:&mToolTip_Stage2 WithDialog:@"LS_Stage2" ];
    
    for (Button* curButton in GET_STATE_MACHINE()->mCompanionButtons)
    {
        if ((curButton != GET_STATE_MACHINE()->mLeftButton) && (curButton != GET_STATE_MACHINE()->mRightButton))
        {
            [curButton SetListener:self];
        }
    }
    
    mNewCompanionId = CompID_MAX;
}

-(void)Resume
{
    for (Button* curButton in GET_STATE_MACHINE()->mCompanionButtons)
    {
        if ((curButton != GET_STATE_MACHINE()->mLeftButton) && (curButton != GET_STATE_MACHINE()->mRightButton))
        {
            [curButton SetListener:self];
        }
    }
}

-(void)Shutdown
{
	[self ClearToolTip:&mToolTip_Stage2];
    
    // Companion buttons should not be responsive when animating out.  That's
    // an unnecessary edge case that could cause a lot of issues.
    
    // Companion buttons are now allowed to respond to button presses (having them be
    // responsive while animating in would require more work to handle, with minimal
    // benefit)
    
    for (Button* curButton in GET_STATE_MACHINE()->mCompanionButtons)
    {
        if ((curButton != GET_STATE_MACHINE()->mLeftButton) && (curButton != GET_STATE_MACHINE()->mRightButton))
        {
            [curButton SetListener:NULL];
        }
    }
}

-(void)Suspend
{
    for (Button* curButton in GET_STATE_MACHINE()->mCompanionButtons)
    {
        if ((curButton != GET_STATE_MACHINE()->mLeftButton) && (curButton != GET_STATE_MACHINE()->mRightButton))
        {
            [curButton SetListener:NULL];
        }
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( GET_STATE_MACHINE()->mCompanionAlreadyChosen )
	{
		GET_STATE_MACHINE()->mCompanionAlreadyChosen = FALSE;
		[GET_STATE_MACHINE() ReplaceTop:[CompanionSelectTransitionFromChangeCompanion alloc]];
	}
}

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton
{
    if (inEvent == BUTTON_EVENT_UP)
    {
        NeonButton* activeButton		= NULL;
        
        switch(GET_STATE_MACHINE()->mEditCompanion)
        {
            case COMPANION_POSITION_LEFT:
            {
                activeButton = GET_STATE_MACHINE()->mLeftButton;
                break;
            }
            
            case COMPANION_POSITION_RIGHT:
            {
                activeButton = GET_STATE_MACHINE()->mRightButton;
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown active button");
                break;
            }
        }
        
        if ((inButton == GET_STATE_MACHINE()->mBackButton) || (inButton == activeButton))
        {
            [GET_STATE_MACHINE() ReplaceTop:[CompanionSelectTransitionFromChangeCompanion alloc]];
        }
        else
        {
            [self ButtonEvent:inEvent Button:inButton];
        }
    }
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if (inEvent == BUTTON_EVENT_UP)
    {
        CompanionID currentCompanionId = CompID_MAX;
        CompanionID newCompanionId = inButton->mIdentifier;
		
        
        switch(GET_STATE_MACHINE()->mEditCompanion)
        {
            case COMPANION_POSITION_LEFT:
            {
                currentCompanionId = GET_STATE_MACHINE()->mLeftButton->mIdentifier;
                break;
            }
            
            case COMPANION_POSITION_RIGHT:
            {
                currentCompanionId = GET_STATE_MACHINE()->mRightButton->mIdentifier;
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown companion position");
                break;
            }
        }
        
        if (newCompanionId == currentCompanionId)
        {
            [GET_STATE_MACHINE() Pop];
        }
        else
        {
            GET_STATE_MACHINE()->mNewCompanionId = newCompanionId;
            [GET_STATE_MACHINE() Push:[CompanionSelectAnimateOutCompanion alloc]];
        }
    }
}

@end

@implementation CompanionSelectAnimateOutCompanion

-(void)Startup
{
    [super Startup];
    
    CompanionPosition editCompanionPosition = GET_STATE_MACHINE()->mEditCompanion;
    
    Companion* editCompanion = [[CompanionManager GetInstance] GetCompanionForPosition:editCompanionPosition];
    
    if (editCompanion != NULL)
    {
        switch(editCompanionPosition)
        {
            case COMPANION_POSITION_LEFT:
            {
                [editCompanion->mEntity PerformAction:COMPANION_ACTION_WALK_FROM_TABLE_LEFT];
                break;
            }
            
            case COMPANION_POSITION_RIGHT:
            {
                [editCompanion->mEntity PerformAction:COMPANION_ACTION_WALK_FROM_TABLE_RIGHT];
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown companion position");
                break;
            }
        }
    }
    
    // Disable all buttons
    
    for (NeonButton* curButton in GET_STATE_MACHINE()->mCompanionButtons)
    {
        [curButton SetActive:FALSE];
        [curButton SetPulseAmount:0.0f time:0.25f];
    }
    
    mElapsedTime = 0.0f;
}

-(void)Resume
{
    NSAssert(FALSE, @"This is unimplemented");
    [super Resume];
}

-(void)Shutdown
{
    [super Shutdown];
}

-(void)Suspend
{
    NSAssert(FALSE, @"This is unimplemented");
    [super Suspend];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [super Update:inTimeStep];
    
    mElapsedTime += inTimeStep;
    
    CompanionPosition editCompanionPosition = GET_STATE_MACHINE()->mEditCompanion;
    Companion* editCompanion = [[CompanionManager GetInstance] GetCompanionForPosition:editCompanionPosition];  
    
    if ((mElapsedTime > COMPANION_ANIMATION_DURATION) || (editCompanion == NULL))
    {
        [[CompanionManager GetInstance] SeatCompanion:editCompanionPosition withID:CompID_Empty];
        
        [GET_STATE_MACHINE() ReplaceTop:[CompanionSelectAnimateInCompanion alloc]];
    }
}

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton
{
}

@end

@implementation CompanionSelectAnimateInCompanion

-(void)Startup
{
    [super Startup];
    
    CompanionPosition editCompanionPosition = GET_STATE_MACHINE()->mEditCompanion;
    CompanionID newCompanionId				= GET_STATE_MACHINE()->mNewCompanionId;
    
    [[CompanionManager GetInstance] SeatCompanion:editCompanionPosition withID:newCompanionId];
    
    Companion* newCompanion = [[CompanionManager GetInstance] GetCompanionForPosition:editCompanionPosition];
        
    Button** editButton = NULL;
	NeonButton* leftButton = GET_STATE_MACHINE()->mLeftButton;
	NeonButton* rightButton = GET_STATE_MACHINE()->mRightButton;
    
    switch(editCompanionPosition)
    {
        case COMPANION_POSITION_LEFT:
        {
            if (newCompanion != NULL)
            {
                [newCompanion->mEntity PerformAction:COMPANION_ACTION_WALK_TO_TABLE_LEFT];
            }
            
            editButton = &leftButton;
            break;
        }
        
        case COMPANION_POSITION_RIGHT:
        {
            if (newCompanion != NULL)
            {
                [newCompanion->mEntity PerformAction:COMPANION_ACTION_WALK_TO_TABLE_RIGHT];
            }
            
            editButton = &rightButton;
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown companion position");
            break;
        }
    }
    
    // Disable all buttons
    
    NeonButton* newCompanionButton = NULL;
    
    for (NeonButton* curButton in GET_STATE_MACHINE()->mCompanionButtons)
    {
        if ((curButton->mIdentifier == CompID_Empty) && (curButton != GET_STATE_MACHINE()->mEmptyButton[GET_STATE_MACHINE()->mEditCompanion]))
        {
            continue;
        }

        if (curButton->mIdentifier == newCompanionId)
        {
            newCompanionButton = curButton;
            break;
        }
    }
    
    // Move the companion being selected to the active location
    
    Path* newCompanionPath = [(Path*)[Path alloc] Init];
    
    Vector3 curPosition;
    [newCompanionButton GetPositionWithoutPlacement:&curPosition];
    
    [newCompanionPath AddNodeVec3:&curPosition atTime:0.0f];
    [newCompanionPath AddNodeVec3:(Vector3*)&sCompanionButtonPositions[editCompanionPosition] atTime:1.0f];
    [newCompanionButton AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:newCompanionPath];
        
    CompanionSelectChangeCompanion* state = (CompanionSelectChangeCompanion*)[GET_STATE_MACHINE() FindInstanceInStack:[CompanionSelectChangeCompanion class]];
    
	// Kking - If this is a transparent button, then we should remove the listener.
    
	if ( *editButton != leftButton && *editButton != rightButton )
		[*editButton SetListener:state];

    *editButton = newCompanionButton;
    [*editButton SetListener:GET_STATE_MACHINE()];
    
    [newCompanionPath release];
    
    // Update the buttons corresponding to companions that can now be swapped in
    [GET_STATE_MACHINE() UpdateCompanionButtonVisibility:NULL animationTime:1.0f];
}

-(void)Resume
{
    [super Resume];
}

-(void)Shutdown
{
    [super Shutdown];
    
    Button* avoidButton = NULL;
    Button* activeButton = NULL;
        
    switch(GET_STATE_MACHINE()->mEditCompanion)
    {
        case COMPANION_POSITION_LEFT:
        {
			[GET_STATE_MACHINE()->mLeftButton SetActive:TRUE];	
            
            avoidButton = GET_STATE_MACHINE()->mRightButton;
            activeButton = GET_STATE_MACHINE()->mLeftButton;
			
			
            break;
        }
        
        case COMPANION_POSITION_RIGHT:
        {
            [GET_STATE_MACHINE()->mRightButton SetActive:TRUE];
            
            avoidButton = GET_STATE_MACHINE()->mLeftButton;
            activeButton = GET_STATE_MACHINE()->mRightButton;
            break;
        }
    }
    
    for (NeonButton* curButton in GET_STATE_MACHINE()->mCompanionButtons)
    {
		if ( curButton == GET_STATE_MACHINE()->mCompanionButton[COMPANION_POSITION_LEFT] || GET_STATE_MACHINE()->mCompanionButton[COMPANION_POSITION_RIGHT] == curButton )
		{
			GET_STATE_MACHINE()->mLeftButton	= GET_STATE_MACHINE()->mCompanionButton[COMPANION_POSITION_LEFT];
			GET_STATE_MACHINE()->mRightButton	= GET_STATE_MACHINE()->mCompanionButton[COMPANION_POSITION_RIGHT];
			[curButton SetActive:TRUE];

			continue;
		}
		
		[curButton SetActive:FALSE];
		[curButton SetVisible:FALSE];

        if ((curButton->mIdentifier == CompID_Empty) && (curButton != GET_STATE_MACHINE()->mEmptyButton[GET_STATE_MACHINE()->mEditCompanion]))
        {
            continue;
        }
        
        if ((curButton != avoidButton) && ([curButton GetVisible]))
        {
            [curButton SetActive:TRUE];
            
            if (curButton == activeButton)
            {
                [curButton SetPulseAmount:1.0f time:0.25f];
            }
            else
            {
                [curButton ResumePulse:0.5f];
            }
        }
    }
}

-(void)Suspend
{
    [super Suspend];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [super Update:inTimeStep];
    
    CompanionPosition editCompanionPosition = GET_STATE_MACHINE()->mEditCompanion;
    Companion* newCompanion = [[CompanionManager GetInstance] GetCompanionForPosition:editCompanionPosition];
    
    if (newCompanion == NULL)
    {
        BOOL complete = TRUE;
        
        for (NeonButton* curButton in GET_STATE_MACHINE()->mCompanionButtons)
        {
            if ([curButton AnyPropertyIsAnimating])
            {
                complete = FALSE;
                break;
            }
        }
        
        if (complete)
        {
            [GET_STATE_MACHINE() Pop];
        }
    }
    else if ([newCompanion->mEntity GetCompanionState] == COMPANION_STATE_IDLE)
    {
		// A new companion has been selected, update the companion ability seats accordingly
		[GET_STATE_MACHINE() UpdateCompanionAbilitySeats];
		
		// Kking - TODO:  Don't just pop state, return back to stage 1 by setting a flag.
		GET_STATE_MACHINE()->mCompanionAlreadyChosen = TRUE;
        [GET_STATE_MACHINE() Pop];
    }
}

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton
{
}

@end

@implementation CompanionSelectStateMachine

-(CompanionSelectStateMachine*)Init
{
    [super Init];
 
	CompanionManager *CompMan = [ CompanionManager GetInstance ];   
    [[CameraStateMgr GetInstance] Push:[CompanionSelectCamera alloc]];
    
    GameObjectBatchParams params;
    [GameObjectBatch InitDefaultParams:&params];
    
    params.mUseAtlas = TRUE;
    
    mUIGroup = [(UIGroup*)[UIGroup alloc] InitWithParams:&params];
    [[GameObjectManager GetInstance] Add:mUIGroup];
    [mUIGroup release];
    
    [self InitBackButton];
	
	// Allocate the "press" dealer buttons
	NeonButtonParams neonButtonParams;
	[NeonButton InitDefaultParams:&neonButtonParams];
	
	neonButtonParams.mTexName					= sTransparentTexture;
	neonButtonParams.mPregeneratedGlowTexName	= sTransparentTexture;
	neonButtonParams.mUIGroup					= mUIGroup;
	neonButtonParams.mBoundingBoxCollision		= TRUE;
	neonButtonParams.mUISoundId					= SFX_MENU_BUTTON_PRESS;
	SetVec2(&neonButtonParams.mBoundingBoxBorderSize, 2, 2);
	
	for ( CompanionPosition iCompPosition = COMPANION_POSITION_FIRST ; iCompPosition < COMPANION_POSITION_MAX ; iCompPosition++ )
	{
		// Player is not used
		if ( iCompPosition == COMPANION_POSITION_PLAYER )
			continue;
			
		mCompanionButton[iCompPosition] = [(NeonButton*)[NeonButton alloc] InitWithParams:&neonButtonParams];
		[mCompanionButton[iCompPosition] release];
		[mCompanionButton[iCompPosition] SetListener:self];
		[ mCompanionButton[iCompPosition] SetPosition:&sCompanionButtonPosition[iCompPosition] ];
		[ mCompanionButton[iCompPosition] SetActive:FALSE];
	}
    
    mCompanionButtons = [[NSMutableArray alloc] initWithCapacity:CompID_MAX];
	
    // Create active companion buttons
    for (int curCompanionId = CompID_FirstActive; curCompanionId < CompID_MAX; curCompanionId++)
    {
        NeonButton* newButton = [self CreateCompanionButton:curCompanionId];
        newButton->mIdentifier = curCompanionId;
        
        [newButton SetVisible:FALSE];
        [newButton Disable];
        
        [mCompanionButtons addObject:newButton];
    }
    
    // Create the empty companion buttons.  Special case as this is the only button that can exist more than once
    for (CompanionPosition curPosition = COMPANION_POSITION_FIRST; curPosition < COMPANION_POSITION_CHANGEABLE_NUM; curPosition++)
    {
        mEmptyButton[curPosition] = [self CreateCompanionButton:CompID_Empty];
        mEmptyButton[curPosition]->mIdentifier = CompID_Empty;
        [mEmptyButton[curPosition] SetVisible:FALSE];
        [mEmptyButton[curPosition] Disable];
        
        [mCompanionButtons addObject:mEmptyButton[curPosition]];
    }
        
    [self SetActiveCompanionButton:COMPANION_POSITION_LEFT];
    [self SetActiveCompanionButton:COMPANION_POSITION_RIGHT];

	CompanionID companionSeat[COMPANION_POSITION_CHANGEABLE_NUM];
	
	for ( CompanionPosition abilityIndex = COMPANION_POSITION_FIRST; abilityIndex < COMPANION_POSITION_CHANGEABLE_NUM; abilityIndex++ )
	{
		if ( [ CompMan GetCompanionForPosition:abilityIndex] )
			companionSeat[abilityIndex] = [ CompMan GetCompanionForPosition:abilityIndex]->mEntity->mCompanionID;
		else
			companionSeat[abilityIndex] = CompID_Empty;

	}
	  
	for ( CompanionID compID = CompID_FirstActive; compID < CompID_MAX; compID++ )
	{
		ImageWellParams					imageWellparams;
		[ImageWell InitDefaultParams:	&imageWellparams];
		imageWellparams.mUIGroup		= mUIGroup;
		imageWellparams.mTextureName	= [ NSString stringWithUTF8String: sAbilityImages[compID] ];
		
		mCompanionAbility[compID]		=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
		[ mCompanionAbility[compID]		release];
		[ mCompanionAbility[compID]		SetVisible:false ];
		[ mCompanionAbility[compID]		SetPosition:&sAbilityLoc[COMPANION_POSITION_DEALER] ];
		
		if ( compID == companionSeat[COMPANION_POSITION_LEFT] )
		{
			[ mCompanionAbility[compID] SetVisible:true ];
			[ mCompanionAbility[compID] SetPosition:&sAbilityLoc[COMPANION_POSITION_LEFT] ];
			
		}
		if ( compID == companionSeat[COMPANION_POSITION_RIGHT] )
		{
			[ mCompanionAbility[compID] SetVisible:true ];
			[ mCompanionAbility[compID] SetPosition:&sAbilityLoc[COMPANION_POSITION_RIGHT] ];
		}
			
	}

    [mUIGroup Finalize];
    
    mCompanionSelectState = COMPANION_SELECT_LOADED;
    mNewCompanionId = CompID_MAX;
    
    [self Push:[CompanionSelectRootState alloc]];
    
    return self;
}

-(void)dealloc
{
    [mUIGroup removeAllObjects];
    [mUIGroup Remove];
    
    [mCompanionButtons release];
            
    [[CameraStateMgr GetInstance] Pop];

    [super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [super Update:inTimeStep];
    
    switch(mCompanionSelectState)
    {
        case COMPANION_SELECT_WAITING_TO_FINISH:
        {
            if ([mUIGroup GroupCompleted])
            {
				[[GameStateMgr GetInstance] Pop];
            }
            
            break;
        }
        
        default:
        {
            break;
        }
    }
}

-(void)SetActiveCompanionButton:(CompanionPosition)inPosition
{
	NeonButton* newButton = NULL;

    switch(inPosition)
    {
        case COMPANION_POSITION_LEFT:
        {
			mLeftButton = mCompanionButton[COMPANION_POSITION_LEFT];
			newButton = mLeftButton;
            break;
        }
        
        case COMPANION_POSITION_RIGHT:
        {
			mRightButton = mCompanionButton[COMPANION_POSITION_RIGHT];
			newButton = mRightButton;
            break;
        }
        
		default:
        {
			NSAssert(FALSE, @"Invalid Position set to SetActiveCompanionButton");
        }
    }
    
	[newButton SetListener:self];
    [newButton SetVisible:FALSE];
    [newButton Enable];
}
 
-(NeonButton*)CreateCompanionButton:(CompanionID)inCompanionId
{
    Companion** companionArray = [CompanionManager GetCompanionInfoArray];

    NSString* iconSubString = companionArray[inCompanionId]->fileNamePrefix;
    NSString* iconFilename = [NSString stringWithFormat:@"cs_%@.papng", iconSubString];
    
    NeonButtonParams neonButtonParams;
    [NeonButton InitDefaultParams:&neonButtonParams];
    
    neonButtonParams.mTexName					= iconFilename;
    neonButtonParams.mPregeneratedGlowTexName	= [NSString stringWithFormat:@"cs_%@_glow.papng", iconSubString];
    neonButtonParams.mUIGroup					= mUIGroup;
    neonButtonParams.mBoundingBoxCollision		= TRUE;
	neonButtonParams.mUISoundId					= SFX_MENU_BUTTON_PRESS;
    SetVec2(&neonButtonParams.mBoundingBoxBorderSize, 2, 2);
    
    NeonButton* newButton = [(NeonButton*)[NeonButton alloc] InitWithParams:&neonButtonParams];
    [newButton release];
    
    PlacementValue placementValue;
    SetRelativePlacement(&placementValue, PLACEMENT_ALIGN_LEFT, PLACEMENT_ALIGN_CENTER);
            
    [newButton SetPlacement:&placementValue];
    
    return newButton;
}

-(void)SetEditCompanion:(CompanionPosition)inPosition
{
    mEditCompanion = inPosition;
}

-(void)InitBackButton
{
    NeonButtonParams	button;
    [NeonButton InitDefaultParams:&button ];
        
    button.mTexName                 = sTransparentTexture;
    button.mPregeneratedGlowTexName = sTransparentTexture;
    button.mUIGroup                 = mUIGroup;
    button.mBoundingBoxCollision    = TRUE;
	button.mUISoundId				= SFX_MENU_BACK;
        
    mBackButton = [(NeonButton*)[NeonButton alloc] InitWithParams:&button];
    
    [mBackButton SetVisible:FALSE];
    [mBackButton Enable];
    [mBackButton SetPosition: &sCompanionButtonPosition[COMPANION_POSITION_DEALER]];
    [mBackButton SetListener:self];
    [mBackButton release];
}

-(void)UpdateCompanionButtonVisibility:(Vector3*)inStartPosition animationTime:(float)inAnimationTime
{
    NeonButton* activeButton = NULL;
	Companion*	selectedCompanion	= NULL;
    
    // Make the portrait corresponding to the companion not being edited, inactive.
    switch(mEditCompanion)
    {
        case COMPANION_POSITION_LEFT:
        {
            activeButton = mLeftButton;
			selectedCompanion = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_LEFT];
			
            break;
        }
        
        case COMPANION_POSITION_RIGHT:
        {            
            activeButton = mRightButton;     
			selectedCompanion = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_RIGHT];       
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown companion being edited");
            break;
        }
    }
	
	[ selectedCompanion->mEntity Pulse:NUM_PULSES ];
    
    int validButtons = 0;
    Vector3* basePosition;
	Vector3  compPosition;
    
    basePosition = (Vector3*)&sCompanionButtonPositions[mEditCompanion];
	compPosition.mVector[x] = COMPANIONSELECTION_X_PADDING;
	compPosition.mVector[y] = GetScreenVirtualHeight() - COMPANIONSELECTION_OFFSET_Y;	// activebutton is no longer a "real" buttton, get height from elsewhere.

    for (NeonButton* curButton in mCompanionButtons)
    {
        CompanionID buttonCompanionId = curButton->mIdentifier;
        
        if ((buttonCompanionId == CompID_Empty) && (curButton != mEmptyButton[mEditCompanion]))
        {
            continue;
        }
        
        if ([self CompanionIdSwitchable:buttonCompanionId])
        {
            // Only show the button if it is unlocked
            if ([[CompanionManager GetInstance] CompanionUnlocked:buttonCompanionId])
            {
                if (![curButton GetVisible])
                {
                    [curButton Enable];
                }
                
                Vector3 currentPosition;
                [curButton GetPositionWithoutPlacement:&currentPosition];

                Vector3* startPosition = inStartPosition;
                
                if (startPosition == NULL)
                {
                    startPosition = &currentPosition;
                }
                
                Path* newPath = [(Path*)[Path alloc] Init];
                
                [newPath AddNodeVec3:startPosition atTime:0.0f];
                
                Vector3 endPosition;
                
                endPosition.mVector[x] = compPosition.mVector[x] + ((COMPANIONSELECTION_OFFSET_X + COMPANION_BUTTON_PADDING) * (validButtons + 0));
                endPosition.mVector[y] = compPosition.mVector[y] + COMPANION_BUTTON_Y_OFFSET;
                endPosition.mVector[z] = 0.0f;
                
                [newPath AddNodeVec3:&endPosition atTime:inAnimationTime];
                [curButton AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:newPath];
                
                [newPath release];
                
                validButtons++;
            }
        }
    }
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if (inEvent == BUTTON_EVENT_UP)
    {
        if (inButton == mBackButton)
        {
            if ([mActiveState class] == [CompanionSelectRootState class])
            {
                int numObjects = [mUIGroup count];
                
                for (int i = 0; i < numObjects; i++)
                {
                    UIObject *nObject = [mUIGroup objectAtIndex:i];
                    
                    [nObject RemoveAfterOperations];
                    [nObject Disable];
                }
                
                mCompanionSelectState = COMPANION_SELECT_WAITING_TO_FINISH;
            }
        }
    }
    
    [(CompanionSelectState*)mActiveState CompanionButtonEvent:inEvent Button:(NeonButton*)inButton];
}

-(BOOL)CompanionIdSwitchable:(CompanionID)inCompanionId
{
    BOOL switchable = FALSE;
    
    Companion* companion = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_LEFT];
    CompanionID leftCompanionId = CompID_Empty;
    
    if (companion != NULL)
    {
        leftCompanionId = companion->mEntity->mCompanionID;
    }
    
    companion = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_RIGHT];
    CompanionID rightCompanionId = CompID_Empty;
    
    if (companion != NULL)
    {
        rightCompanionId = companion->mEntity->mCompanionID;
    }
    
    companion = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_DEALER];
    CompanionID dealerCompanionId = CompID_Empty;
    
    if (companion != NULL)
    {
        dealerCompanionId = companion->mEntity->mCompanionID;
    }
    
    companion = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_PLAYER];
    CompanionID playerCompanionId = CompID_Empty;
    
    if (companion != NULL)
    {
        playerCompanionId = companion->mEntity->mCompanionID;
    }
    
    CompanionID editCompanionId = CompID_Empty;
    
    switch(mEditCompanion)
    {
        case COMPANION_POSITION_LEFT:
        {
            editCompanionId = leftCompanionId;
            break;
        }

        case COMPANION_POSITION_RIGHT:
        {
            editCompanionId = rightCompanionId;
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown companion position");
            break;
        }
    }
    
    // Don't show buttons for companions already on screen, or for the dealer, or for the player
    // Empty companion ID is always allowed, unless the active companion happens to be empty
	
	// Kking - Not allowing empty companion anymore in release game.
    if (    (inCompanionId != leftCompanionId)		&&
            (inCompanionId != rightCompanionId)		&&
            (inCompanionId != dealerCompanionId)	&&
            (inCompanionId != playerCompanionId)	&&
			(inCompanionId != CompID_Empty)			&&
            (inCompanionId != editCompanionId)		)
    {
        switchable = TRUE;
    }
    
    return switchable;
}

-(void)UpdateCompanionAbilitySeats
{
	CompanionManager	*CompMan = [ CompanionManager GetInstance ];  
	CompanionID			companionSeat[COMPANION_POSITION_CHANGEABLE_NUM];
	
	for ( CompanionPosition abilityIndex = COMPANION_POSITION_FIRST; abilityIndex < COMPANION_POSITION_CHANGEABLE_NUM; abilityIndex++ )
	{
		if ( [ CompMan GetCompanionForPosition:abilityIndex] )
			companionSeat[abilityIndex] = [ CompMan GetCompanionForPosition:abilityIndex]->mEntity->mCompanionID;
		else
			companionSeat[abilityIndex] = CompID_Empty;

	}
	
	// Find the 2 abilities that are active, and make them visible
	for ( CompanionID compID = CompID_FirstActive; compID < CompID_MAX; compID++ )
	{
		[ mCompanionAbility[compID] SetVisible:false ];
		[ mCompanionAbility[compID] SetPosition:&sAbilityLoc[COMPANION_POSITION_DEALER] ];
		
		if ( compID == companionSeat[COMPANION_POSITION_LEFT] )
		{
			[ mCompanionAbility[compID] SetVisible:true ];
			[ mCompanionAbility[compID] SetPosition:&sAbilityLoc[COMPANION_POSITION_LEFT] ];
			
		}
		if ( compID == companionSeat[COMPANION_POSITION_RIGHT] )
		{
			[ mCompanionAbility[compID] SetVisible:true ];
			[ mCompanionAbility[compID] SetPosition:&sAbilityLoc[COMPANION_POSITION_RIGHT] ];
		}
	}
}

@end

@implementation CompanionSelect

-(void)Startup
{
    mCompanionSelectStateMachine = [(CompanionSelectStateMachine*)[CompanionSelectStateMachine alloc] Init];
}

-(void)Resume
{
}

-(void)Suspend
{
}

-(void)Shutdown
{
    [mCompanionSelectStateMachine release];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [mCompanionSelectStateMachine Update:inTimeStep];
}

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData
{
}

@end