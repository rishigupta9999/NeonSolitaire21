//
//  LevelDefinitions.h
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "Flow.h"

#define NUM_LEVELS_IN_ROOM      3

typedef enum
{
    RUN21_LEVEL_1,
    RUN21_LEVEL_2,
    RUN21_LEVEL_3,
    RUN21_LEVEL_4,
    RUN21_LEVEL_5,
    RUN21_LEVEL_6,
    RUN21_LEVEL_7,
    RUN21_LEVEL_8,
    RUN21_LEVEL_9,
    RUN21_LEVEL_10,
    RUN21_LEVEL_11,
    RUN21_LEVEL_12,
    RUN21_LEVEL_13,
    RUN21_LEVEL_14,
    RUN21_LEVEL_15,
    RUN21_LEVEL_16,
    RUN21_LEVEL_17,
    RUN21_LEVEL_18,
    RUN21_LEVEL_19,
    RUN21_LEVEL_20,
    RUN21_LEVEL_21,
    RUN21_LEVEL_LAST = RUN21_LEVEL_21,
    RUN21_LEVEL_NUM
} Run21Level;

typedef enum
{
    LEVELSELECT_ROOM_BRONZE,
    LEVELSELECT_ROOM_SILVER,
    LEVELSELECT_ROOM_GOLD,
    LEVELSELECT_ROOM_EMERALD,
    LEVELSELECT_ROOM_SAPPHIRE,
    LEVELSELECT_ROOM_RUBY,
    LEVELSELECT_ROOM_DIAMOND,
    LEVELSELECT_ROOM_LAST = LEVELSELECT_ROOM_DIAMOND,
    LEVELSELECT_ROOM_NUM
} LevelSelectRoom;

@interface LevelInfo : NSObject
{
}

@property CasinoID      CasinoID;
@property CompanionID   DealerID;
@property BOOL          Clubs;
@property BOOL          Spades;
@property BOOL          Diamonds;
@property BOOL          Hearts;
@property int           NumDecks;
@property int           NumCards;
@property int           NumJokers;
@property BOOL          PrioritizeHighCards;
@property BOOL          AddClubs;
@property BOOL          JokersAvailable;
@property BOOL          XrayAvailable;
@property BOOL          TornadoAvailable;
@property int           NumRunners;
@property int           XraysGranted;
@property int           TornadoesGranted;
@property int           TimeLimitSeconds;

-(LevelInfo*)init;

@end

@interface LevelDefinitions : NSObject
{
    CasinoID        mCasinoId;
    TutorialScript* mTutorialScript;
}

-(LevelDefinitions*)Init;
-(void)dealloc;

-(void)StartLevel;

-(NSString*)GetBGMusicFilename;
-(char**)GetSkyboxFilenames;
-(CompanionID)GetDealerId;
-(TutorialScript*)GetTutorialScript;

-(NSString*)GetLevelDescription:(int)inLevel;

-(BOOL)GetHearts;
-(BOOL)GetSpades;
-(BOOL)GetClubs;
-(BOOL)GetDiamonds;

-(BOOL)GetAddClubs;

-(int)GetNumDecks;
-(int)GetNumCards;
-(int)GetNumJokers;

-(BOOL)GetJokersAvailable;
-(BOOL)GetXrayAvailable;
-(BOOL)GetTornadoAvailable;

-(int)GetNumRunners;
-(int)GetNumRunnersForGameMode:(GameModeType)inGameModeType level:(int)inLevel;

-(int)GetTimeLimitSeconds;

-(LevelInfo*)GetLevelInfo:(int)inLevel;

// Textures
-(NSString*)GetMinitableTextureFilename;
-(NSString*)GetScoreboardActiveTextureFilename;
-(NSString*)GetScoreboardInactiveTextureFilename;
-(NSString*)GetScoreboardBlankTextureFilename;
-(NSString*)GetTabletTextureFilename;

+(NSString*)GetCardTextureForLevel:(int)inLevel;

-(CasinoID)GetCasinoId:(int)inLevelIndex;

-(LevelSelectRoom)GetRoomForLevel:(int)inLevel;

-(BOOL)GetMainMenuUnlocked;
-(int)GetMainMenuUnlockLevel;

-(BOOL)GetJokerUnlocked;
-(int)GetJokerUnlockLevel;
-(BOOL)GetXrayUnlocked;
-(int)GetXrayUnlockLevel;
-(BOOL)GetTornadoUnlocked;
-(int)GetTornadoUnlockLevel;
-(BOOL)GetRoomsUnlocked;
-(int)GetRoomsUnlockLevel;

-(BOOL)GetTimedLevelsUnlocked;
-(int)GetTimedUnlockLevel;

@end