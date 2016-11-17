//
//  CompanionManager.m
//  Neon21
//
//  Copyright Neon Games 2009 All rights reserved.
//

#import "CompanionManager.h"
#import "CompanionEntity.h"
#import "GameObjectManager.h"
#import "Flow.h"

@implementation CompanionManager

static CompanionManager*    sInstance = NULL;
static Companion*           sCompanions[CompID_MAX];

+(void)InitCompanionInfo
{
	int i;
	
	for ( i = 0 ; i < CompID_MAX; i++ )
	{
        sCompanions[i] = [Companion alloc];
        
		sCompanions[i]->isUnlocked			= false;
		sCompanions[i]->characterName		= @"Empty";
		sCompanions[i]->fileNamePrefix		= @"empty";
        sCompanions[i]->companionSize       = COMPANION_SIZE_NORMAL;
		sCompanions[i]->mEntity				= NULL;
	}
	
	sCompanions[CompID_Polly]->characterName		= @"Polly";
	sCompanions[CompID_Polly]->fileNamePrefix		= @"polly";
	
	sCompanions[CompID_Amber]->characterName		= @"Amber";
	sCompanions[CompID_Amber]->fileNamePrefix		= @"amber";
	
	sCompanions[CompID_Betty]->characterName		= @"Betty";
	sCompanions[CompID_Betty]->fileNamePrefix		= @"betty";
	
	sCompanions[CompID_Cathy]->characterName		= @"Cathy";
	sCompanions[CompID_Cathy]->fileNamePrefix		= @"cathy";
	
	sCompanions[CompID_Johnny]->characterName		= @"Johnny";
	sCompanions[CompID_Johnny]->fileNamePrefix		= @"johnny";
	
	sCompanions[CompID_Panda]->characterName		= @"Panda";
	sCompanions[CompID_Panda]->fileNamePrefix		= @"panda";
    sCompanions[CompID_Panda]->companionSize        = COMPANION_SIZE_FAT;
	
	sCompanions[CompID_Igunaq]->characterName		= @"Igunaq";
	sCompanions[CompID_Igunaq]->fileNamePrefix		= @"igunaq";
    sCompanions[CompID_Igunaq]->companionSize       = COMPANION_SIZE_FAT;
	
	sCompanions[CompID_NunaVut]->characterName		= @"NunaVut";
	sCompanions[CompID_NunaVut]->fileNamePrefix		= @"nunavut";
	
	sCompanions[CompID_DonCappo]->characterName		= @"DonCappo";
	sCompanions[CompID_DonCappo]->fileNamePrefix	= @"doncappo";
}

+(Companion**)GetCompanionInfoArray
{
    return sCompanions;
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Companion manager already created");
    
    sInstance = [CompanionManager alloc];
	
	[ sInstance InitCompanions ];
	
	// Get Flow Manager
	TableCompanionPlacement *companionLayout;

	companionLayout = [ [Flow GetInstance] GetCompanionLayout		];

#if FORCE_COMPANION_SEATS
    companionLayout->seatLeft = FORCE_COMPANION_LEFT;
    companionLayout->seatRight = FORCE_COMPANION_RIGHT;
    companionLayout->seatDealer = FORCE_COMPANION_DEALER;
#endif
        
	[ sInstance SeatCompanion:COMPANION_POSITION_LEFT	withID:companionLayout->seatLeft	];
	[ sInstance SeatCompanion:COMPANION_POSITION_RIGHT	withID:companionLayout->seatRight	];
    [ sInstance SeatCompanion:COMPANION_POSITION_DEALER withID:companionLayout->seatDealer  ];
    [ sInstance SeatCompanion:COMPANION_POSITION_PLAYER withID:companionLayout->seatPlayer  ];
    
    sInstance->mAbilitiesEnabled = TRUE;
}

+(void)DestroyInstance
{
    [sInstance release];
    
    sInstance = NULL;
}

+(CompanionManager*)GetInstance
{
    return sInstance;
}

-(void)dealloc
{
    for (int curCompanion = 0; curCompanion < COMPANION_POSITION_MAX; curCompanion++)
    {
        if (mActiveCompanions[curCompanion] != NULL)
        {
            [mActiveCompanions[curCompanion]->mEntity Remove];
            
            mActiveCompanions[curCompanion]->mEntity = NULL;
            mActiveCompanions[curCompanion] = NULL;
        }
    }
    
#if NEON_DEBUG
    for (int i = 0; i < CompID_MAX; i++)
    {
        NSAssert(sCompanions[i]->mEntity == NULL, @"Expected NULL companion entity for ID %d", i);
    }
#endif
    
    [super dealloc];
}

-(BOOL)IsCompanionActive:(CompanionID)companionID
{
    CompanionID leftCompanionID = [self GetCompanionForPosition:COMPANION_POSITION_LEFT]->mEntity->mCompanionID;
    CompanionID rightCompanionID = [self GetCompanionForPosition:COMPANION_POSITION_LEFT]->mEntity->mCompanionID;
    
	if ( companionID == leftCompanionID || rightCompanionID == companionID )
		return true;
	
	return false;
}

-(BOOL)IsRuleActive:(RuleIDs)ruleID
{
    if (!mAbilitiesEnabled)
    {
        return FALSE;
    }
    
    CompanionID leftCompanionID = CompID_Empty;
    CompanionID rightCompanionID = CompID_Empty;
    
    Companion* leftCompanion = [self GetCompanionForPosition:COMPANION_POSITION_LEFT];
    Companion* rightCompanion = [self GetCompanionForPosition:COMPANION_POSITION_RIGHT];
    
    if (leftCompanion != NULL)
    {
        leftCompanionID = leftCompanion->mEntity->mCompanionID;
    }
    
    if (rightCompanion != NULL)
    {
        rightCompanionID = rightCompanion->mEntity->mCompanionID;
    }

	if ( ruleID == leftCompanionID || rightCompanionID == ruleID )
	{
		Companion* actionCompanion = rightCompanion;
		
		if (ruleID == leftCompanionID)
		{
			actionCompanion = leftCompanion;
		}
		
		[actionCompanion->mEntity PerformAction:COMPANION_ACTION_ABILITY];
		
		return true;
	}
	
	return false;
}

-(void)UnlockCompanion:(CompanionID)companionID
{
	sCompanions[companionID]->isUnlocked = true;
}

-(BOOL)CompanionUnlocked:(CompanionID)in_CompanionID
{
    NSAssert(in_CompanionID >= 0 && in_CompanionID < CompID_MAX, @"Invalid Companion ID specified");
    
    return sCompanions[in_CompanionID]->isUnlocked;
}

-(void)SeatCompanion:(CompanionPosition)inPosition withID:(CompanionID)inCompanionID
{
    if (mActiveCompanions[inPosition] != NULL)
    {
        // Remove from GameObjectManager
        [mActiveCompanions[inPosition]->mEntity Remove];
        [[GameObjectManager GetInstance] Remove:mActiveCompanions[inPosition]->mEntity];
        
        mActiveCompanions[inPosition]->mEntity = NULL;
        mActiveCompanions[inPosition] = NULL;
    }

    if (inCompanionID != CompID_Empty)
    {
        Companion* newCompanion = sCompanions[inCompanionID];
                
        if (newCompanion->mEntity == NULL)
        {
            newCompanion->mEntity = [(CompanionEntity*)[CompanionEntity alloc] InitWithCompanionID:inCompanionID position:inPosition];
            [[GameObjectManager GetInstance] Add:newCompanion->mEntity];
            [newCompanion->mEntity release];
        }
        else
        {
            // This companion *must* be seated elsewhere.  Remove him/her for that position first.

            BOOL companionFound = FALSE;
            
            for (int curCompanion = 0; curCompanion < COMPANION_POSITION_MAX; curCompanion++)
            {
                if (mActiveCompanions[curCompanion] == newCompanion)
                {
                    mActiveCompanions[curCompanion] = NULL;
                    companionFound = TRUE;
                    
                    break;
                }
            }
            
            NSAssert(companionFound, @"Companion wasn't found seated elsewhere, but it's already created.  How is this possible?");
            
            [newCompanion->mEntity ReinitWithPosition:inPosition];
        }
        
        if (mActiveCompanions[inPosition] != NULL)
        {
            [mActiveCompanions[inPosition] release];
        }
        
        mActiveCompanions[inPosition] = newCompanion;
    }
}

-(void)InitCompanions
{    
    memset(mActiveCompanions, 0, sizeof(mActiveCompanions));
}

-(Companion*)GetCompanionForPosition:(CompanionPosition)inPosition
{
    NSAssert((inPosition >= COMPANION_POSITION_FIRST) && (inPosition <= COMPANION_POSITION_MAX), @"CompanionPosition is invalid");
    
    return mActiveCompanions[inPosition];
}

+(CompanionID)GetCompanionWithName:(NSString*)inName
{
    CompanionID retId = CompID_MAX;
    
    for (CompanionID curCompanionID = CompID_Empty; curCompanionID < CompID_MAX; curCompanionID++)
    {
        if ([sCompanions[curCompanionID]->characterName compare:inName] == NSOrderedSame)
        {
            retId = curCompanionID;
            break;
        }
    }
    
    NSAssert(retId != CompID_MAX, @"Could not find companion with name %@", inName);
    
    return retId;
}

-(void)SetAbilitiesEnabled:(BOOL)inEnabled
{
    mAbilitiesEnabled = inEnabled;
}

@end