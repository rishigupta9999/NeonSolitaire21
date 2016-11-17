//
//  SaveSystem.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "MenuFlowTypes.h"
#import "InAppPurchaseManager.h"
#import "DebugManager.h"
#import "LevelDefinitions.h"

// @TODO: High number to leave extra blocks just in case.
#define NUM_TRACKED_LEVELS                      12
#define NUM_TRACKED_LEVEL_OFFSET                6

#define NUM_LEVELS_IN_GAME                      50
#define NUM_IAPS_IN_GAME                        128

typedef enum
{
    USER_GUEST,
    USER_REGISTERED_LOGGED_IN,
    USER_REGISTERED_LOGGED_OUT,
    USER_NUM,
} RegistrationLevel;

typedef enum
{
    SAVE_VALUE_LEVEL_STARS,
    SAVE_VALUE_MARATHON_SCORE,
    SAVE_VALUE_SOUND_ENABLED,
    SAVE_VALUE_MUSIC_ENABLED,
    SAVE_VALUE_IAP_NOADS,
    SAVE_VALUE_NUM_XRAYS,
    SAVE_VALUE_NUM_TORNADOES,
    SAVE_VALUE_NUM_LIVES,
    SAVE_VALUE_LIFE_LOST_TIMESTAMP,
    SAVE_VALUE_ROOM_UNLOCK_TIMESTAMP,
    SAVE_VALUE_REGISTERED_USER,
    SAVE_VALUE_EXPERIENCE,
    SAVE_VALUE_PURCHASE_AMOUNT,
    SAVE_VALUE_CURRENCY_CODE,
    SAVE_VALUE_IAP_NUM,
    SAVE_VALUE_TIME_PLAYED,
    SAVE_VALUE_TIERS_PURCHASED,
    SAVE_VALUE_COUNTRY_CODE,
    SAVE_VALUE_MAX_LEVEL,
    SAVE_VALUE_MAX_LEVEL_STARTED,
    SAVE_VALUE_MAX_ROOM_UNLOCKED,
    SAVE_VALUE_RATED_GAME,
    SAVE_VALUE_NUM_WINS_SINCE_RATE_PROMPT,
    SAVE_VALUE_NUM
} SaveValueIndex;

typedef struct
{
	u32                 mStars[NUM_LEVELS_IN_GAME];
    u32                 mMarathonScore;
    u32                 mSoundOn;
    u32                 mMusicOn;
    u32                 mIAPNoAds;
    u32                 mNumTornadoes;
    u32                 mNumXrays;
    u32                 mNumLives;
    NSTimeInterval      mLifeLostTimestamp;
    NSTimeInterval      mRoomUnlockTimestamp;
    u32                 mRegisteredUser;
    u32                 mExperience;
    double              mPurchaseAmount;
    NSString*           mCurrencyCode;
    u32                 mIAPAmounts[NUM_IAPS_IN_GAME];
    CFTimeInterval      mTimePlayed;
    u32                 mTiersPurchased;
    NSString*           mLanguageCode;
    u32                 mStarsLevel[NUM_TRACKED_LEVELS];
    u32                 mMaxLevel;
    u32                 mMaxLevelStarted;
    u32                 mMaxRoomUnlocked;
    u32                 mRatedGame;
    u32                 mNumWinsSinceRatePrompt;
} SaveValues;

@interface SaveSystem : NSObject<DebugMenuCallback>
{
    SaveValues          mSaveValues;
    BOOL                mDebugItemRegistered;
}

-(SaveSystem*)Init;
-(void)dealloc;

+(void)CreateInstance;
+(void)DestroyInstance;
+(SaveSystem*)GetInstance;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)InitializeDefaultValues;
-(void)ParseSaveFile;

-(void)WriteEntry:(int)inIndex;
-(void)WriteEntry:(int)inIndex withOffset:(int)inOffset numEntries:(int)numEntries;
-(void)LoadEntryFromObject:(id)inObject withIndex:(int)inIndex;

-(SaveValues*)GetSaveValues;

-(u32)GetStarsForLevel:(u32)inLevel;
-(void)SetStarsForLevel:(u32)inLevel withStars:(u32)inStars;

-(void)SetMarathonScore:(u32)inScore;
-(u32)GetMarathonScore;

-(void)SetSoundOn:(BOOL)inSoundOn;
-(BOOL)GetSoundOn;

-(void)SetMusicOn:(BOOL)inMusicOn;
-(BOOL)GetMusicOn;

-(void)SetNoAds:(NSNumber*)inNoAds;
-(BOOL)GetNoAds;

-(void)SetNumTornadoes:(NSNumber*)inNumTornadoes;
-(int)GetNumTornadoes;

-(void)SetNumXrays:(NSNumber*)inNumXrays;
-(int)GetNumXrays;

-(int)GetNumLives;
-(void)SetNumLives:(NSNumber*)inNumLives;

-(NSTimeInterval)GetLifeLostTimestamp;
-(void)SetLifeLostTimestamp;

-(NSTimeInterval)GetRoomUnlockTimestamp;
-(void)SetRoomUnlockTimestamp;
-(void)ClearRoomUnlockTimestamp;

-(RegistrationLevel)GetRegisteredUser;
-(void)SetRegisteredUser:(RegistrationLevel)regLevel;

-(int)GetExperience;
-(void)SetExperience:(int)xp;
-(void)AddExperience:(int)xp;

-(double)GetPurchaseAmount;
-(void)SetPurchaseAmount:(double)inPurchaseAmount;

-(void)SetCurrencyCode:(NSString*)inCurrencyCode;
-(NSString*)GetCurrencyCode;

-(u32)GetNumPurchasesForIAP:(IapProduct)inPurchase;
-(void)SetNumPurchasesForIAP:(IapProduct)inPurchase numPurchases:(int)inNumPurchases;
-(int)GetNumTotalPurchases;

-(double)GetTimePlayed;
-(void)SetTimePlayed:(double)inTimePlayed;

-(int)GetTiersPurchased;
-(void)AddTierPurchased:(int)tierLevel;

-(void)Reset;
-(void)LoadDeveloperSave;

-(void)SetMaxLevel:(int)inMaxLevel;
-(int)GetMaxLevel;

-(void)SetMaxLevelStarted:(int)inMaxLevelStarted;
-(int)GetMaxLevelStarted;

-(LevelSelectRoom)GetMaxRoomUnlocked;
-(void)SetMaxRoomUnlocked:(NSNumber*)inLevelSelectRoom;

-(void)SetRatedGame:(int)inRatedGame;
-(int)GetRatedGame;

-(void)SetNumWinsSinceRatePrompt:(int)inNumWins;
-(int)GetNumWinsSinceRatePrompt;

-(void)DebugMenuItemPressed:(NSString*)inName;

@end

