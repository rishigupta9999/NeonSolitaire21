//
//  GameCutscene.h
//  Neon21
//
//  Copyright Neon Games 2011.
//

#import "GameState.h"
#import "StateMachine.h"
#import "Button.h"
#import "TextBox.h"
#import "ImageWell.h"
#import "UIGroup.h"
#import "SequentialLoader.h"

#define CutScene_ChapterStart					0
#define Dialogue_TotalChaptersNeonEscape		12
#define Dialogue_MAX_FRAMES						25	// Todo: Remove, to use dynamic alloc

#define DialogueBox_Image_X						0
#define DialogueBox_Image_Y						240

#define DialogueBox_Text_Origin_X				70
#define DialogueBox_Text_Origin_Y				250

//#define DialogueBox_Text_Extent_X				315
//#define DialogueBox_Text_Extent_Y				375

//#define Dialogue_InitialOffset_X				60
//#define Dialogue_InitialOffset_Y				240
//#define Dialogue_InitialOffset_DeltaY			26

#define Dialogue_FontSize						12	// 10 Change to 18 once we get word wrap?
#define Dialogue_StrokeSize						0

#define Escape1_FramesInCutsceneChapter_1		9
#define Escape1_FramesInCutsceneChapter_2		21
#define Escape1_FramesInCutsceneChapter_3		11
#define Escape1_FramesInCutsceneChapter_4		12
#define Escape1_FramesInCutsceneChapter_5		13
#define Escape1_FramesInCutsceneChapter_6		10
#define Escape1_FramesInCutsceneChapter_7		10
#define Escape1_FramesInCutsceneChapter_8		14
#define Escape1_FramesInCutsceneChapter_9		16
#define Escape1_FramesInCutsceneChapter_10p1	10
#define Escape1_FramesInCutsceneChapter_10p2	6
#define Escape1_FramesInCutsceneChapter_10p3	12

// Coordinates for iPhone.

typedef enum
{
	Actor_None,
	Actor_Polly,
	Actor_Amber,
	Actor_Betty,
	Actor_Cathy,
	Actor_Johnny,
	Actor_Panda,
	Actor_Nuna,
	Actor_Vut,
	Actor_Igunaq,
	Actor_DonCappo,
	Actor_NotImplemented,
	Actor_MAX
} ActorID;


typedef enum
{
    CUTSCENE_POSITION_LEFT,
    CUTSCENE_POSITION_CENTER,
    CUTSCENE_POSITION_RIGHT,
    CUTSCENE_POSITION_NUM,
}  CutsceneImagePosition;

typedef enum
{
    PAN_STATE_IDLE,
    PAN_STATE_WAITING_FOR_LOAD,
    PAN_STATE_WAITING_FOR_IDLE,
    PAN_STATE_WAITING_FOR_GESTURES,
    PAN_STATE_TRANSITION
} PanState;

typedef struct
{
	ActorID			mActor[Dialogue_MAX_FRAMES];

} CutsceneChapter;

typedef struct
{
	int				mCurChapter;
	int             mCurFrame;
    int             mTotalFrames;
	
} ChapterBookmark;


@interface CutsceneImage : NSObject
{
    @public
        ImageWell*  mCutsceneImage;
        u32         mCutsceneImageIndex;
}

-(CutsceneImage*)Init;
-(void)dealloc;

@end

@interface GameCutscene : GameState <TouchListenerProtocol, PathCallback, SequentialLoaderProtocol>
{
    ChapterBookmark			mBookmark;
	ActorID					mSpeaker                    [Dialogue_TotalChaptersNeonEscape];
	
	TextBox					*mDialogueBox               [Dialogue_MAX_FRAMES];
	ImageWell				*mActorIcon                 [Dialogue_MAX_FRAMES];
        
    SequentialLoader		*mSequentialLoader;
    SequentialLoader		*mTextLoader;
    
    UIPanGestureRecognizer	*mPanGestureRecognizer;
    PanState                mPanState;
    CGPoint                 mLastPanVelocity;
    CFTimeInterval          mLastPanVelocityTimestamp;
    int                     mNumPanAnimations;
    int                     mFrameDelta;
    
    int                     mWaitingFrames;
}

-(void)Startup;
-(void)Shutdown;
-(void)Update:(CFTimeInterval)inTimeStep;
//-(void)InitDialogueWithActor:(ActorID)nActorID;
-(void)InitDisplay;
-(void)ClearDisplay:(BOOL)inForceImmediate;

-(void)LoadCutsceneImages;

-(void)RemoveDialogueBoxes:(BOOL)inForceImmediate;
-(void)RemoveActorIcons:(BOOL)inForceImmediate;

-(void)DrawOrtho;

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData;

-(void)EvaluatePanBegin;
-(void)EvaluatePanTranslation:(CGPoint*)inTranslation;
-(void)EvaluatePanConclusion:(CGPoint*)inTranslation;

-(void)PathEvent:(PathEvent)inEvent withPath:(Path*)inPath userData:(u32)inData;



#ifdef NEON_ESCAPE
-(NSString*)GetFilenameForFrame:(int)inFrameIndex;
-(void)InitNeonEscapeCutscene;
-(int)GetNeonEscapeChapterIDFromFlowProgress;
-(NSString*)GetLocalizedTextForFrame;
-(ActorID)GetActorForCurrentFrame;
#endif

-(NSObject*)PreloadObjectWithIndex:(int)inIndex forLoader:(SequentialLoader*)inLoader;
-(void)ProcessLoadedObject:(NSObject*)inObject atIndex:(int)inIndex forLoader:(SequentialLoader*)inLoader;
-(void)UnloadObject:(NSObject*)inObject atIndex:(int)inIndex forLoader:(SequentialLoader*)inLoader;

@end