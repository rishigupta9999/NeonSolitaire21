//
//  MiniGameTableEntity.h
//  Neon21
//
//  Copyright 2011 Neon Games. All rights reserved.
//

#import "GameObject.h"
#import "AdvertisingManager.h"
#import "RenderGroup.h"

@class Model;
@class ImageWell;
@class TextBox;
@class GameEnvironment;
@class Framebuffer;
@class JumbotronFilter;
@class NeonLightShaft;

typedef enum
{
    TABLET_STATE_RUN21,
    TABLET_STATE_AD,
} TabletState;

// Intentionally not a type
enum
{
    ADVERTISING_STATE_IDLE,
    ADVERTISING_STATE_NEW_DATA,
} AdvertisingState;

typedef struct
{
    NSMutableArray*     mAdvertisingBannerArray;        // ImageWell
    NSMutableArray*     mAdvertisingGameNameArray;      // NSString
    NSMutableArray*     mAdvertisingURLArray;           // NSString
    int                 mAdvertisingBannerIndex;
} AdvertisingHolder;

extern const int JUMBOTRON_WIDTH;
extern const int JUMBOTRON_HEIGHT;

@interface MiniGameTableEntity : GameObject<MessageChannelListener, AdvertisingManagerListener, RenderGroupCallback>
{
    Model* mTableBezel;
	Model* mTableScoreboard;
    Model* mTableCenter;
    Model* mTableTablet;
	
    // For the scoreboard
	RenderGroup* mScoreboardRenderGroup;
    
    // For the tablet texture itself
    RenderGroup* mTabletRenderGroup;
    Framebuffer* mTabletFramebuffer;
    
    // For the contents of the jumbotron portion
    RenderGroup* mJumbotronRenderGroup;
    Framebuffer* mJumbotronFramebuffer;
    Framebuffer* mJumbotronOutputFramebuffer;
    
    ImageWell* mScoreboardInactiveImageWell;
    ImageWell* mScoreboardActiveImageWell;
    ImageWell* mScoreboardCurrentImageWell;
    ImageWell* mJumbotronImageWell;
    
    Light*          mTabletLight;
    NeonLightShaft* mXrayLightShaft;
    
    JumbotronFilter* mJumbotronFilter;
    
    AdvertisingHolder  mAdHolder;
    
    s32             mAdvertisingState;
    
    Matrix44        mTabletTransform;
    Matrix44        mScoreboardTransform;
    Matrix44        mTableSurfaceTransform;
    Matrix44        mBezelTransform;
    
    Vector3         mTabletColor;
    Vector3         mAdColor;
    Vector3         mProgressBannerColor;
    
    BOOL            mTerminateAds;
    
    TabletState     mTabletState;
    CFTimeInterval  mTabletStateTime;
    
    int             mStingerCount;
}

-(MiniGameTableEntity*)InitWithEnvironment:(GameEnvironment*)inEnvironment;
-(void)dealloc;

-(void)Remove;
-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Draw;

-(void)CreateScoreboardRenderGroup;
-(RenderGroup*)GetScoreboardRenderGroup;

-(void)CreateTabletRenderGroup;
-(void)CreateJumbotronRenderGroup;
-(RenderGroup*)GetJumbotronRenderGroup;

-(Model*)GetTableBezel;
-(Model*)GetTableScoreboard;
-(Model*)GetTableTablet;
-(Matrix44*)GetScoreboardTransform;
-(BOOL)IsScoreboardAdDisplaying;
-(NSString*)GetScoreboardAdURL;
-(NSString*)GetAssetNameFromBaseName:(NSString*)inBaseName withExtension:(NSString*)inExtension;

-(BOOL)BannerAvailable;
-(void)CycleAd;

-(void)ProcessMessage:(Message*)inMsg;

-(void)AdvertisingManagerRequestComplete:(BOOL)success;

+(u32)GetHashForClass;

-(Model*)GetPuppet;

-(void)RenderGroupDrawComplete:(RenderGroup*)inRenderGroup;
-(void)RenderGroupUpdateComplete:(RenderGroup*)inRenderGroup timeStep:(CFTimeInterval)inTimeStep;

@end