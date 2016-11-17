//
//  SaveSystem.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import <Parse/Parse.h>

#import "SaveSystem.h"
#import "GameRun21.h"
#import "RegenerationManager.h"
#import "ExperienceManager.h"
#import "NeonAccountManager.h"
#import "LevelDefinitions.h"

// Instructions for adding a new field in the save file
//
// 1) Add the variable you want to save out in the SaveValues structure (see SaveSystem.h)
// 2) Initialize it InitializeDefaultValues
// 3) Add an accessor / setter for it.  Pattern it off the existing ones
// 4) Add an entry for it in the sSaveEntries table below.  The fields are pretty self explanatory, but are described below in more detail
// 5) Add an entry in the SaveValueIndex enum below

static SaveSystem* sInstance = NULL;

typedef enum
{
    SAVE_VALUE_TYPE_INTEGER,        // A single integer
    SAVE_VALUE_TYPE_DATA,           // Data of a specified length.  This is fixed and can never be changed without breaking compatbility
    SAVE_VALUE_TYPE_BOOL,
    SAVE_VALUE_TYPE_DOUBLE,
    SAVE_VALUE_TYPE_STRING,
} SaveValueType;

typedef struct
{
    u32             mOffset;        // Offset into the SaveValues structure that this value is stored
    char*           mKey;           // What key is used to access this
    SaveValueType   mType;          // Data type
    u32             mSize;          // Size of the data
    char*           mParseColumn;   // If this is mirrored on Parse, then this is the column that we'll write out.
} SaveEntry;

static const char* IAP_PARSE_COLUMN_NAMES[IAP_PRODUCT_NUM + 1] = {
                                                                #if !NEON_SOLITAIRE_21
                                                                    "IAP_NoAds",
                                                                #endif
                                                                    "IAP_TornadoBronze",
                                                                    "IAP_TornadoSilver",
                                                                    "IAP_TornadoGold",
                                                                    "IAP_XrayBronze",
                                                                    "IAP_XraySilver",
                                                                    "IAP_XrayGold",
                                                                #if USE_LIVES
                                                                    "IAP_RefillLives",
                                                                #endif
                                                                    NULL   };

// Note: Please prepend "Neon" to all keys to distinguish them from all other keys.
static SaveEntry    sSaveEntries[SAVE_VALUE_NUM] = {
        { offsetof(SaveValues, mStars),                 "NeonLevelScore2",          SAVE_VALUE_TYPE_DATA,    sizeof(u32) * NUM_LEVELS_IN_GAME,  NULL                },
        { offsetof(SaveValues, mMarathonScore),         "NeonMarathonScore",        SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       NULL                },
        { offsetof(SaveValues, mSoundOn),               "NeonSoundOn",              SAVE_VALUE_TYPE_BOOL,    sizeof(BOOL),                      NULL                },
        { offsetof(SaveValues, mMusicOn),               "NeonMusicOn",              SAVE_VALUE_TYPE_BOOL,    sizeof(BOOL),                      NULL                },
        { offsetof(SaveValues, mIAPNoAds),              "NeonIAPNoAds",             SAVE_VALUE_TYPE_BOOL,    sizeof(BOOL),                      NULL                },
        { offsetof(SaveValues, mNumXrays),              "NeonNumXrays",             SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       NULL                },
        { offsetof(SaveValues, mNumTornadoes),          "NeonNumTornadoes",         SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       NULL                },
        { offsetof(SaveValues, mNumLives),              "NeonNumLives",             SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       NULL                },
        { offsetof(SaveValues, mLifeLostTimestamp),     "NeonLifeLostTimestamp",    SAVE_VALUE_TYPE_DOUBLE,  sizeof(double),                    NULL                },
        { offsetof(SaveValues, mRoomUnlockTimestamp),   "NeonRoomUnlockTimestamp",  SAVE_VALUE_TYPE_DOUBLE,  sizeof(double),                    NULL                },
        { offsetof(SaveValues, mRegisteredUser),        "NeonRegisteredUser",       SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       NULL                },
        { offsetof(SaveValues, mExperience),            "NeonExperience",           SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       "Experience"        },
        { offsetof(SaveValues, mPurchaseAmount),        "NeonPurchaseAmount",       SAVE_VALUE_TYPE_DOUBLE,  sizeof(double),                    "CurrencySpent"     },
        { offsetof(SaveValues, mCurrencyCode),          "NeonCurrencyCode",         SAVE_VALUE_TYPE_STRING,  sizeof(NSString*),                 "CurrencyCode"      },
        { offsetof(SaveValues, mIAPAmounts),            "NeonIAPAmounts",           SAVE_VALUE_TYPE_DATA,    sizeof(u32) * NUM_IAPS_IN_GAME,    (char*)IAP_PARSE_COLUMN_NAMES  },
        { offsetof(SaveValues, mTimePlayed),            "NeonTimePlayed",           SAVE_VALUE_TYPE_DOUBLE,  sizeof(double),                    "TimePlayed"        },
        { offsetof(SaveValues, mTiersPurchased),        "NeonTiersPurchased",       SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       "a_TiersPurchased"  },
        { offsetof(SaveValues, mLanguageCode),          "NeonCountryCode",          SAVE_VALUE_TYPE_STRING,  sizeof(NSString*),                 "b_CountryCode"     },
        { offsetof(SaveValues, mMaxLevel),              "NeonMaxLevel",             SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       NULL                },
        { offsetof(SaveValues, mMaxLevelStarted),       "NeonMaxLevelStarted",      SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       NULL                },
        { offsetof(SaveValues, mMaxRoomUnlocked),       "NeonMaxRoomUnlocked",      SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       NULL                },
        { offsetof(SaveValues, mRatedGame),             "NeonRatedGame",            SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       NULL                },
        { offsetof(SaveValues, mNumWinsSinceRatePrompt),"NeonWinsSinceRatePrompt",  SAVE_VALUE_TYPE_INTEGER, sizeof(u32),                       NULL                }
    };

@implementation SaveSystem

-(SaveSystem*)Init
{
//#if IAP_DEVELOPER_MODE
    //[self LoadDeveloperSave];
//#else
    [self InitializeDefaultValues];
    [self ParseSaveFile];
//#endif

    mDebugItemRegistered = FALSE;
    return self;
}

-(void)dealloc
{
    [[DebugManager GetInstance] UnregisterDebugMenuItem:@"Clear Powerups"];
    [super dealloc];
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to create SaveSystem a second time");
    sInstance = [(SaveSystem*)[SaveSystem alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to destroy SaveSystem when it has not yet been created");
    
    [sInstance release];
    sInstance = NULL;
}

+(SaveSystem*)GetInstance
{
    return sInstance;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if (!mDebugItemRegistered)
    {
        mDebugItemRegistered = TRUE;
        
        [[DebugManager GetInstance] RegisterDebugMenuItem:@"Clear Powerups" WithCallback:self];
    }
}

-(void)InitializeDefaultValues
{
    for (u32 i = 0; i < NUM_LEVELS_IN_GAME; i++)
	{
		mSaveValues.mStars[i] = 0;
	}
    
    mSaveValues.mMarathonScore          = 0;
    
    mSaveValues.mSoundOn                = TRUE;
    mSaveValues.mMusicOn                = TRUE;
    mSaveValues.mIAPNoAds               = NEON_FREE_VERSION ? FALSE : TRUE;         // By Default, Paid Apps don't have Ads.
    mSaveValues.mNumXrays               = STARTUP_POWERUP_XRAY;
    mSaveValues.mNumTornadoes           = STARTUP_POWERUP_TORNADO;
    mSaveValues.mNumLives               = STARTUP_POWERUP_LIVES;
    mSaveValues.mRegisteredUser         = USER_GUEST;
    mSaveValues.mLifeLostTimestamp      = [[NSDate date] timeIntervalSince1970];
    mSaveValues.mRoomUnlockTimestamp    = 0;
    mSaveValues.mExperience             = 0;
    mSaveValues.mPurchaseAmount         = 0;
    mSaveValues.mCurrencyCode           = NULL;
    mSaveValues.mTimePlayed             = 0;
    mSaveValues.mTiersPurchased         = 0;
    mSaveValues.mLanguageCode           = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    
    for (u32 i = 0; i < NUM_IAPS_IN_GAME; i++)
    {
        mSaveValues.mIAPAmounts[i] = 0;
    }
    
    mSaveValues.mMaxLevel = 0;
    mSaveValues.mMaxLevelStarted = 0;
    mSaveValues.mMaxRoomUnlocked = LEVELSELECT_ROOM_LAST;
    mSaveValues.mRatedGame = FALSE;
    mSaveValues.mNumWinsSinceRatePrompt = 0;
}

-(void)ParseSaveFile
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    for (int i = 0; i < SAVE_VALUE_NUM; i++)
    {
        id obj = [defaults objectForKey:[NSString stringWithUTF8String:sSaveEntries[i].mKey]];
        
        if (obj == NULL)
        {
            [self WriteEntry:i];
        }
        else
        {
            [self LoadEntryFromObject:obj withIndex:i];
        }
    }
}

-(void)WriteEntry:(int)inIndex
{
    [self WriteEntry:inIndex withOffset:0 numEntries:0];
}

-(void)WriteEntry:(int)inIndex withOffset:(int)inOffset numEntries:(int)numEntries
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    SaveEntry* saveEntryInfo = &sSaveEntries[inIndex];
    
    NSObject* writeObj = NULL;
    
    char* dataLocation = ((char*)&mSaveValues) + saveEntryInfo->mOffset;
    
    NSAssert((inOffset == 0) || (saveEntryInfo->mType == SAVE_VALUE_TYPE_DATA), @"Can't specify a save entry offset, unless the save value type is data");

    switch(saveEntryInfo->mType)
    {
        case SAVE_VALUE_TYPE_INTEGER:
        {
            int intVal = *(int*)dataLocation;
            [defaults setInteger:intVal forKey:[NSString stringWithUTF8String:saveEntryInfo->mKey]];

            writeObj = [NSNumber numberWithInt:intVal];
            break;
        }
        
        case SAVE_VALUE_TYPE_DATA:
        {
            writeObj = [NSData dataWithBytes:dataLocation length:saveEntryInfo->mSize];
            [defaults setObject:writeObj forKey:[NSString stringWithUTF8String:saveEntryInfo->mKey]];
            break;
        }
        
        case SAVE_VALUE_TYPE_BOOL:
        {
            BOOL boolVal = *(BOOL*)(dataLocation);
            [defaults setBool:boolVal forKey:[NSString stringWithUTF8String:saveEntryInfo->mKey]];
            
            writeObj = [NSNumber numberWithBool:boolVal];
            break;
        }
            
        case SAVE_VALUE_TYPE_DOUBLE:
        {
            double dblVal = *(double*)dataLocation;
            [defaults setDouble:dblVal forKey:[NSString stringWithUTF8String:saveEntryInfo->mKey]];
            
            writeObj = [NSNumber numberWithDouble:dblVal];
            break;
        }
        
        case SAVE_VALUE_TYPE_STRING:
        {
            NSString* string = *(NSString**)dataLocation;
            [defaults setObject:string forKey:[NSString stringWithUTF8String:saveEntryInfo->mKey]];
            
            writeObj = string;
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown data type");
        }
    }

    [defaults synchronize];
}

-(void)LoadEntryFromObject:(id)inObject withIndex:(int)inIndex
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    SaveEntry* saveEntryInfo = &sSaveEntries[inIndex];
    
    char* dataLocation = ((char*)&mSaveValues) + saveEntryInfo->mOffset;
        
    switch(saveEntryInfo->mType)
    {
        case SAVE_VALUE_TYPE_INTEGER:
        {
            NSInteger integer = [defaults integerForKey:[NSString stringWithUTF8String:saveEntryInfo->mKey]];
            int intVal = (int)integer;
            
            *(int*)dataLocation = intVal;
            
            break;
        }
        
        case SAVE_VALUE_TYPE_DATA:
        {
            NSData* data = [defaults dataForKey:[NSString stringWithUTF8String:saveEntryInfo->mKey]];
            NSAssert([data length] == saveEntryInfo->mSize, @"Difference between received and expected size");
            
            memcpy(dataLocation, [data bytes], saveEntryInfo->mSize);
            break;
        }
        
        case SAVE_VALUE_TYPE_BOOL:
        {
            BOOL boolVal = [defaults boolForKey:[NSString stringWithUTF8String:saveEntryInfo->mKey]];
            *(BOOL*)dataLocation = boolVal;
            
            break;
        }
            
        case SAVE_VALUE_TYPE_DOUBLE:
        {
            double dblVal = [defaults doubleForKey:[NSString stringWithUTF8String:saveEntryInfo->mKey]];
            *(double*)dataLocation = dblVal;
            
            break;
        }
        
        case SAVE_VALUE_TYPE_STRING:
        {
            NSString* string = [defaults stringForKey:[NSString stringWithUTF8String:saveEntryInfo->mKey]];
            *(NSString**)dataLocation = string;
            [string retain];
            
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown data type");
        }
    }
}

-(SaveValues*)GetSaveValues
{
    return &mSaveValues;
}

-(void)Reset
{
    NSAssert(FALSE, @"Currently unimplemented");
}

// Debug values for development
-(void)LoadDeveloperSave
{
    NSAssert( IAP_DEVELOPER_MODE, @"Cannot Load Developer Save while not in IAP_DEVELOPER_MODE");
    
    // Uncomment this to oblitierate any user defaults and save data to test fresh installs, or remove debug entries.
    // Or open Simulator -> iOS Simulator ( Top left menu ) -> Reset Content and Settings.
    /*
     NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
     [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
     */
    
    for ( u32 i = 0 ; i < NUM_LEVELS_IN_GAME ; i++ )
	{
		mSaveValues.mStars[i] = 2; // 2-Star Every Level.
	}
    
    mSaveValues.mSoundOn                = FALSE;
    mSaveValues.mMusicOn                = FALSE;
    mSaveValues.mIAPNoAds               = TRUE;
    mSaveValues.mNumXrays               = 0;
    mSaveValues.mNumTornadoes           = 0;
    mSaveValues.mNumLives               = 0;
    mSaveValues.mRegisteredUser         = USER_GUEST;
    mSaveValues.mLifeLostTimestamp      = [[NSDate date] timeIntervalSince1970];
    mSaveValues.mExperience             = 0;
    mSaveValues.mPurchaseAmount         = 0;
    mSaveValues.mCurrencyCode           = NULL;
    mSaveValues.mTiersPurchased         = 0;
    mSaveValues.mLanguageCode           = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    
    for ( u32 i = 0 ; i < SAVE_VALUE_NUM ; i++ )
    {
        [self WriteEntry:i];
    }
}

-(u32)GetStarsForLevel:(u32)inLevel
{
	return mSaveValues.mStars[inLevel];
}

-(void)SetStarsForLevel:(u32)inLevel withStars:(u32)inStars
{
	if (inStars > mSaveValues.mStars[inLevel] )
	{
		mSaveValues.mStars[inLevel] = inStars;
		[self WriteEntry:SAVE_VALUE_LEVEL_STARS];
	}
}

-(void)SetMarathonScore:(u32)inScore
{
    mSaveValues.mMarathonScore = inScore;
    [self WriteEntry:SAVE_VALUE_MARATHON_SCORE];
}

-(u32)GetMarathonScore
{
    return mSaveValues.mMarathonScore;
}

-(void)SetSoundOn:(BOOL)inSoundOn
{
    mSaveValues.mSoundOn = inSoundOn;
    [self WriteEntry:SAVE_VALUE_SOUND_ENABLED];
}

-(BOOL)GetSoundOn
{
    return mSaveValues.mSoundOn;
}

-(void)SetMusicOn:(BOOL)inMusicOn
{
    mSaveValues.mMusicOn = inMusicOn;
    [self WriteEntry:SAVE_VALUE_MUSIC_ENABLED];
}

-(BOOL)GetMusicOn
{
    return mSaveValues.mMusicOn;
}

-(void)SetNoAds:(NSNumber*)inNoAds
{
    mSaveValues.mIAPNoAds = [inNoAds boolValue];
    [self WriteEntry:SAVE_VALUE_IAP_NOADS];
}

-(BOOL)GetNoAds
{
    return mSaveValues.mIAPNoAds;
}

-(void)SetNumTornadoes:(NSNumber*)inNumTornadoes
{
    mSaveValues.mNumTornadoes = [inNumTornadoes intValue];
    [self WriteEntry:SAVE_VALUE_NUM_TORNADOES];
}

-(int)GetNumTornadoes
{
    return mSaveValues.mNumTornadoes;
}

-(void)SetNumXrays:(NSNumber*)inNumXrays
{
    mSaveValues.mNumXrays = [inNumXrays intValue];
    [self WriteEntry:SAVE_VALUE_NUM_XRAYS];
}

-(int)GetNumXrays
{
    return mSaveValues.mNumXrays;
}

-(void)SetNumLives:(NSNumber*)inNumLives
{
    mSaveValues.mNumLives = [inNumLives intValue];
    [self WriteEntry:SAVE_VALUE_NUM_LIVES];
}

-(int)GetNumLives
{
#if UNLIMITED_LIVES || !USE_LIVES
    return STARTUP_POWERUP_LIVES;
#endif
    return mSaveValues.mNumLives;
}

-(void)SetLifeLostTimestamp
{
    mSaveValues.mLifeLostTimestamp = [[NSDate date] timeIntervalSince1970];
    [self WriteEntry:SAVE_VALUE_LIFE_LOST_TIMESTAMP];
}

-(NSTimeInterval)GetLifeLostTimestamp
{
    return mSaveValues.mLifeLostTimestamp;
}

-(void)SetRoomUnlockTimestamp
{
    mSaveValues.mRoomUnlockTimestamp = [[NSDate date] timeIntervalSince1970];
    [self WriteEntry:SAVE_VALUE_ROOM_UNLOCK_TIMESTAMP];
}

-(NSTimeInterval)GetRoomUnlockTimestamp
{
    return mSaveValues.mRoomUnlockTimestamp;
}

-(void)ClearRoomUnlockTimestamp
{
    mSaveValues.mRoomUnlockTimestamp = 0;
    [self WriteEntry:SAVE_VALUE_ROOM_UNLOCK_TIMESTAMP];
}

-(RegistrationLevel)GetRegisteredUser
{
    return mSaveValues.mRegisteredUser;
}
-(void)SetRegisteredUser:(RegistrationLevel)regLevel
{
    mSaveValues.mRegisteredUser = regLevel;
    [self WriteEntry:SAVE_VALUE_REGISTERED_USER];
}

-(int)GetExperience
{
    return mSaveValues.mExperience;
}

-(void)SetExperience:(int)xp
{
    mSaveValues.mExperience = xp;
    [self WriteEntry:SAVE_VALUE_EXPERIENCE];
}


-(void)AddExperience:(int)xp
{
    int thisLevel, nextLevel;
    float percent;
    [[ExperienceManager GetInstance] GetPlayerWithLevel:&thisLevel WithPercent:&percent];

    mSaveValues.mExperience += xp;
    [self WriteEntry:SAVE_VALUE_EXPERIENCE];
    
    [[ExperienceManager GetInstance] GetPlayerWithLevel:&nextLevel WithPercent:&percent];

    // Test to see if we level up here.
    if (nextLevel > thisLevel)
    {
        [[ExperienceManager GetInstance] AwardLevelUpPrizesFromLevel:thisLevel toLevel:nextLevel];
    }
}

-(double)GetPurchaseAmount
{
    return mSaveValues.mPurchaseAmount;
}

-(void)SetPurchaseAmount:(double)inPurchaseAmount
{
    mSaveValues.mPurchaseAmount = inPurchaseAmount;
    [self WriteEntry:SAVE_VALUE_PURCHASE_AMOUNT];
}

-(void)SetCurrencyCode:(NSString*)inCurrencyCode
{
    [mSaveValues.mCurrencyCode release];
    mSaveValues.mCurrencyCode = [inCurrencyCode retain];
    
    [self WriteEntry:SAVE_VALUE_CURRENCY_CODE];
}

-(NSString*)GetCurrencyCode
{
    return mSaveValues.mCurrencyCode;
}

-(u32)GetNumPurchasesForIAP:(IapProduct)inPurchase
{
    return mSaveValues.mIAPAmounts[inPurchase];
}

-(int)GetNumTotalPurchases
{
    int total = 0;
    
    for (IapProduct curProduct = IAP_PRODUCT_NON_CONSUMABLE_FIRST; curProduct < IAP_PRODUCT_NUM; curProduct++)
    {
        total += [self GetNumPurchasesForIAP:curProduct];
    }
    
    return total;
}

-(void)SetNumPurchasesForIAP:(IapProduct)inPurchase numPurchases:(int)inNumPurchases
{
    mSaveValues.mIAPAmounts[inPurchase] = inNumPurchases;
    
    [self WriteEntry:SAVE_VALUE_IAP_NUM withOffset:inPurchase numEntries:1];
}

-(double)GetTimePlayed
{
    return mSaveValues.mTimePlayed;
}

-(void)SetTimePlayed:(double)inTimePlayed
{
    mSaveValues.mTimePlayed = inTimePlayed;
    
    [self WriteEntry:SAVE_VALUE_TIME_PLAYED];
}

-(int)GetTiersPurchased
{
    return mSaveValues.mTiersPurchased;
}

-(void)AddTierPurchased:(int)tierLevel
{
    mSaveValues.mTiersPurchased += tierLevel;
    [self WriteEntry:SAVE_VALUE_TIERS_PURCHASED];
}

-(void)SetMaxLevel:(int)inMaxLevel
{
    NSAssert(inMaxLevel <= RUN21_LEVEL_NUM, @"Invalid level");
    
    if (inMaxLevel > mSaveValues.mMaxLevel)
    {
        mSaveValues.mMaxLevel = inMaxLevel;
    }
    
    [self WriteEntry:SAVE_VALUE_MAX_LEVEL];
}

-(int)GetMaxLevel
{
    return mSaveValues.mMaxLevel;
}

-(void)SetMaxLevelStarted:(int)inMaxLevelStarted
{
    NSAssert(inMaxLevelStarted <= RUN21_LEVEL_NUM, @"Invalid level");
    
    if (inMaxLevelStarted > mSaveValues.mMaxLevelStarted)
    {
        mSaveValues.mMaxLevelStarted = inMaxLevelStarted;
    }
    
    [self WriteEntry:SAVE_VALUE_MAX_LEVEL_STARTED];
}

-(int)GetMaxLevelStarted
{
    return mSaveValues.mMaxLevelStarted;
}

-(LevelSelectRoom)GetMaxRoomUnlocked
{
    return mSaveValues.mMaxRoomUnlocked;
}

-(void)SetMaxRoomUnlocked:(NSNumber*)inLevelSelectRoom
{
    if ([inLevelSelectRoom intValue] > mSaveValues.mMaxRoomUnlocked)
    {
        [[RegenerationManager GetInstance] SetRoomUnlockState:ROOM_UNLOCK_STATE_IDLE];
        
        mSaveValues.mMaxRoomUnlocked = [inLevelSelectRoom intValue];
        [self WriteEntry:SAVE_VALUE_MAX_ROOM_UNLOCKED];
    }
}

-(void)SetRatedGame:(int)inRatedGame
{
    mSaveValues.mRatedGame = inRatedGame;
    
    [self WriteEntry:SAVE_VALUE_RATED_GAME];
}

-(int)GetRatedGame
{
    return mSaveValues.mRatedGame;
}

-(void)SetNumWinsSinceRatePrompt:(int)inNumWins
{
    mSaveValues.mNumWinsSinceRatePrompt = inNumWins;
    
    [self WriteEntry:SAVE_VALUE_NUM_WINS_SINCE_RATE_PROMPT];
}

-(int)GetNumWinsSinceRatePrompt
{
    return mSaveValues.mNumWinsSinceRatePrompt;
}

-(void)DebugMenuItemPressed:(NSString*)inName
{
    [self SetNumXrays:0];
    [self SetNumTornadoes:0];
}

@end
