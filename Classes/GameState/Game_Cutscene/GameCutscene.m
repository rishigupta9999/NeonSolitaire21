//
//  GameCutscene.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "GameCutscene.h"
#import "GameObjectManager.h"
#import "Flow.h"
#import "TextureButton.h"
#import "DebugManager.h"
#import "TextTextureBuilder.h"
#import "TextureButton.h"
#import "MainMenu.h"
#import "Neon21AppDelegate.h"

#define NO_TEXT						" "
#define CUTSCENE_INDEX_INVALID		(-1)

#define IMAGE_WIDTH					(480)
#define IMAGE_HEIGHT				(240)

#define PAN_ANIMATION_TIME          (0.25f)
#define PAN_MIN_VELOCITY            (100.0f)
#define PAN_VELOCITY_EXPIRE_TIME    (0.15f)

#define WAITING_FRAMES     (3)

static Vector3 DIALOGUE_LOCATION	 = { { DialogueBox_Text_Origin_X, DialogueBox_Text_Origin_Y, 0.0 } };

// Character Voices
// =========================
// A = Amber
// B = Betty
// C = Cathy
// D = Don Cappo
// I = Igunaq
// J = Johnny
// N = Nuna
// P = Polly
// S = Subtitle  (narrator)
// V = Vut
// X = Panda

static const char*		sDialogueActors[Dialogue_TotalChaptersNeonEscape] = {
//  "123456789012345678901
	"PPCBBAACP",				// 9  frames - Chapter 1
	"JPJJJSSSSJJJSSJSSSJJS",	// 21 frames - Chapter 2
	"JASJPBCJJPA",				// 11 frames - Chapter 3
	"XPXXSXXXSSXC",				// 12 frames - Chapter 4
	"XXJABCPXXPXXX",			// 13 frames - Chapter 5
	"VNVJPABCVN",				// 10 frames - Chapter 6
	"NNVJPJVNXC",				// 10 frames - Chapter 7
	"ISISISISSIIXII",			// 14 frames - Chapter 8
	"IPXBPCPCAXNIJJPP",			// 16 frames - Chapter 9
	"DDPDDDJDDD",				// 10 frames - Chapter 10p1
	"DDDDPD",					// 6  frames - Chapter 10p2
	"DPDBJJXXVVPA",				// 12 frames - Chapter 10p3
};
		

// Kking - Translate (TODO: Read from localizable.strings for cutscene dialogue)
static const char*		sActorIcons[Actor_MAX]	= { 
	"dialogbox_empty.papng",	// Actor_None
	"dialogbox_polly.papng",	// Actor_Polly
	"dialogbox_amber.papng",	// Actor_Amber
	"dialogbox_betty.papng",	// Actor_Betty
	"dialogbox_cathy.papng",	// Actor_Cathy
	"dialogbox_johnny.papng",	// Actor_Johnny
	"dialogbox_panda.papng",	// Actor_Panda
	"dialogbox_nuna.papng",		// Actor_Nuna
	"dialogbox_vut.papng",		// Actor_Vut
	"dialogbox_igunaq.papng",	// Actor_Igunaq
	"dialogbox_cappo.papng",	// Actor_DonCappo
	"dialogbox_empty.papng"		// Actor_NotImplemented
	};
	
															
static const int		sTotalFrames[Dialogue_TotalChaptersNeonEscape]	= { 
	Escape1_FramesInCutsceneChapter_1,
	Escape1_FramesInCutsceneChapter_2,
	Escape1_FramesInCutsceneChapter_3,
	Escape1_FramesInCutsceneChapter_4,
	Escape1_FramesInCutsceneChapter_5,
	Escape1_FramesInCutsceneChapter_6,
	Escape1_FramesInCutsceneChapter_7,
	Escape1_FramesInCutsceneChapter_8,
	Escape1_FramesInCutsceneChapter_9,
	Escape1_FramesInCutsceneChapter_10p1,
	Escape1_FramesInCutsceneChapter_10p2,
	Escape1_FramesInCutsceneChapter_10p3
	};

@implementation CutsceneImage

-(CutsceneImage*)Init
{
    mCutsceneImage = NULL;
    mCutsceneImageIndex = 0;
    
    return self;
}

-(void)dealloc
{
    [[GameObjectManager GetInstance] Remove:mCutsceneImage];
    
    [super dealloc];
}

@end

@implementation GameCutscene

-(void)Startup
{
    memset(mDialogueBox, 0, sizeof(mDialogueBox));
    memset(mActorIcon, 0, sizeof(mActorIcon));
    
	// Setup the frames
	mBookmark.mCurFrame			= CutScene_ChapterStart;
    mBookmark.mCurChapter		= [self GetNeonEscapeChapterIDFromFlowProgress];
    mBookmark.mTotalFrames		= sTotalFrames[mBookmark.mCurChapter];
	
    [[TouchSystem GetInstance] AddListener:self];
    [[TouchSystem GetInstance] SetGesturesEnabled:TRUE];
	
	[self InitDisplay];	
    
    mPanGestureRecognizer		= [[TouchSystem GetInstance] GetPanGestureRecognizer];
    mPanState					= PAN_STATE_WAITING_FOR_IDLE;
    mLastPanVelocity			= CGPointZero;
    mLastPanVelocityTimestamp	= 0;
    mNumPanAnimations			= 0;
    mFrameDelta					= 0;
    
    NSMutableArray* indexArray = [[NSMutableArray alloc] initWithCapacity:mBookmark.mTotalFrames];
    
    SequentialLoaderParams sequentialLoaderParams;
    [SequentialLoader InitDefaultParams:&sequentialLoaderParams];
    
    sequentialLoaderParams.mIndices			= indexArray;
    sequentialLoaderParams.mWindowSize		= 1;
    sequentialLoaderParams.mStartingIndex	= 0;
    sequentialLoaderParams.mCallback		= self;
    
    for (int i = 0; i < mBookmark.mTotalFrames; i++)
    {
        [indexArray addObject:[NSNumber numberWithInt:i]];
    }
    
    mSequentialLoader = [(SequentialLoader*)[SequentialLoader alloc] InitWithParams:&sequentialLoaderParams];
    
    [indexArray release];
}

-(void)Shutdown
{
    [mSequentialLoader release];
    
    [[TouchSystem GetInstance] SetGesturesEnabled:FALSE];
    [[TouchSystem GetInstance] RemoveListener:self];

    [self ClearDisplay:FALSE];
}

-(void)dealloc
{
	[super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    switch(mPanState)
    {
        case PAN_STATE_WAITING_FOR_LOAD:
        {
            mWaitingFrames--;
            
            if (mWaitingFrames <= 0)
            {
                mWaitingFrames = 0;
                
                if (mBookmark.mCurFrame == mBookmark.mTotalFrames)
                {
                    [[Flow GetInstance] ProgressForward];
                    return;
                }

                [self InitDisplay];
                // Update the mSequentialLoader's index
                [self LoadCutsceneImages];
                
                mWaitingFrames = WAITING_FRAMES;
                mPanState = PAN_STATE_WAITING_FOR_IDLE;
            }
            
            break;
        }
        
        case PAN_STATE_WAITING_FOR_IDLE:
        {
            mWaitingFrames--;
            
            if (mWaitingFrames <= 0)
            {
                mWaitingFrames = 0;
                
                [mActorIcon[mBookmark.mCurFrame]	Enable];
                [mDialogueBox[mBookmark.mCurFrame]  Enable];

                mPanState = PAN_STATE_IDLE;
            }
            
            break;
        }
    }
}

-(void)InitDisplay
{
#ifdef NEON_ESCAPE
	// Get Flow State
	[ self InitNeonEscapeCutscene ];
#endif
}

-(void)ClearDisplay:(BOOL)inForceImmediate
{
    [self RemoveDialogueBoxes:inForceImmediate];
    [self RemoveActorIcons:inForceImmediate];
}

-(void)LoadCutsceneImages
{
    [mSequentialLoader SetIndex:mBookmark.mCurFrame];
}

-(void)RemoveDialogueBoxes:(BOOL)forceImmediate
{
    for (int dialogIndex = 0; dialogIndex < Dialogue_MAX_FRAMES; dialogIndex++)
    {
        if ((mPanState == PAN_STATE_WAITING_FOR_GESTURES) && (!forceImmediate))
        {
            [mDialogueBox[dialogIndex] Disable];
            [mDialogueBox[dialogIndex] RemoveAfterOperations];
        }
        else
        {
            [mDialogueBox[dialogIndex] Remove];
        }
        
        mDialogueBox[dialogIndex] = NULL;
    }
}

-(void)RemoveActorIcons:(BOOL)forceImmediate
{
    for (int dialogIndex = 0; dialogIndex < Dialogue_MAX_FRAMES; dialogIndex++)
    {
        if ((mPanState == PAN_STATE_WAITING_FOR_GESTURES) && (!forceImmediate))
        {
            [mActorIcon[dialogIndex] Disable];
            [mActorIcon[dialogIndex] RemoveAfterOperations];
        }
        else
        {
            [mActorIcon[dialogIndex] Remove];
        }
        
        mActorIcon[dialogIndex] = NULL;
    }
}


#ifdef NEON_ESCAPE
-(void)InitNeonEscapeCutscene
{
	ImageWellParams		imageParams;
	[ImageWell	InitDefaultParams:&imageParams];
	imageParams.mTextureName		=	[NSString stringWithUTF8String:sActorIcons[ [self GetActorForCurrentFrame] ] ];
	
	mActorIcon[mBookmark.mCurFrame]	=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageParams];
	[[GameObjectManager GetInstance]	Add:mActorIcon[mBookmark.mCurFrame]];
	[mActorIcon[mBookmark.mCurFrame]	release];
	[mActorIcon[mBookmark.mCurFrame]	SetPositionX:DialogueBox_Image_X Y:DialogueBox_Image_Y Z:0];
	[mActorIcon[mBookmark.mCurFrame]	SetVisible:FALSE];

	TextBoxParams		tbParams;
	
	mBookmark.mCurChapter	= [ self GetNeonEscapeChapterIDFromFlowProgress ];
	mBookmark.mTotalFrames	= sTotalFrames[ mBookmark.mCurChapter ];
		
	[TextBox				InitDefaultParams:&tbParams];
	tbParams.mStrokeSize	= Dialogue_StrokeSize;
	tbParams.mString		= [self GetLocalizedTextForFrame ];
	tbParams.mFontSize		= Dialogue_FontSize;
	tbParams.mFontType		= NEON_FONT_NORMAL; // NEON_FONT_STYLISH;
	tbParams.mWidth			= GetScreenVirtualWidth() - 5 - DialogueBox_Text_Origin_X;
	SetColorFloat			(&tbParams.mColor, 1.0f, 1.0f, 1.0f, 1.0f);
	SetColorFloat			(&tbParams.mStrokeColor, 1.0f, 1.0f, 1.0f, 1.0f);	
	
	mDialogueBox	[mBookmark.mCurFrame] = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
	[[GameObjectManager GetInstance] Add:mDialogueBox[mBookmark.mCurFrame]];
	[mDialogueBox	[mBookmark.mCurFrame] release];
	[mDialogueBox	[mBookmark.mCurFrame] SetPosition:&DIALOGUE_LOCATION];
	[mDialogueBox	[mBookmark.mCurFrame] SetVisible:FALSE];
}

-(int)GetNeonEscapeChapterIDFromFlowProgress
{
	int ret = CutScene_ChapterStart;
	
	switch ( [ [Flow GetInstance] GetProgress ] )
	{
		case Escape1_Story_Chapter_1:		ret = 0;	break;
		case Escape1_Story_Chapter_2:		ret = 1;	break;
		case Escape1_Story_Chapter_3:		ret = 2;	break;
		case Escape1_Story_Chapter_4:		ret = 3;	break;
		case Escape1_Story_Chapter_5:		ret = 4;	break;
		case Escape1_Story_Chapter_6:		ret = 5;	break;
		case Escape1_Story_Chapter_7:		ret = 6;	break;
		case Escape1_Story_Chapter_8:		ret = 7;	break;
		case Escape1_Story_Chapter_9:		ret = 8;	break;
		case Escape1_Story_Chapter_10part1: ret = 9;	break;
		case Escape1_Story_Chapter_10part2: ret = 10;	break;
		case Escape1_Story_Chapter_10part3: ret = 11;	break;
			
		default: NSAssert(FALSE, @"Unknown Cutscene Chapter ID");	break;
	}
	
	return ret;
}

-(NSString*)GetLocalizedTextForFrame
{
	NSString			*str;
	NSString			*locStr;
	
	
	str = [NSString stringWithFormat:@"Cut_Ch%d_F%d", mBookmark.mCurChapter + 1, mBookmark.mCurFrame];	// Chapters are 1 based index
	locStr = NSLocalizedString(str, NULL);
	
	return locStr;
}

-(NSString*)GetFilenameForFrame:(int)inFrameIndex
{
	return [NSString stringWithFormat:@"chapter%d_frame%d.png", [ self GetNeonEscapeChapterIDFromFlowProgress ] + 1, inFrameIndex];	// 1 based indexing on chapter images
}

-(ActorID)GetActorForCurrentFrame
{
	ActorID	ret;
	const char *chPtr = sDialogueActors[mBookmark.mCurChapter];
	
	switch ( chPtr[mBookmark.mCurFrame] )
	{
		case 'A':
			ret = Actor_Amber;
			break;
			
		case 'B':
			ret = Actor_Betty;
			break;
			
		case 'C':
			ret = Actor_Cathy;
			break;
			
		case 'D':
			ret = Actor_DonCappo;
			break;
			
		case 'I':
			ret = Actor_Igunaq;
			break;
			
		case 'J':
			ret = Actor_Johnny;
			break;
			
		case 'N':
			ret = Actor_Nuna;
			break;
			
		case 'P':
			ret = Actor_Polly;
			break;
			
		case 'S':
			ret = Actor_None;
			break;
			
		case 'V':
			ret = Actor_Vut;
			break;
			
		case 'X':
			ret = Actor_Panda;
			break;
			
		default:
			NSAssert(FALSE, @"Invalid Actor");
			break;
	}
	
	return ret;
}
#endif

-(void)DrawOrtho
{
#if !NEON_PRODUCTION
    /*char myStr[256];

	// This text is mirrored and alligned vertically.  Some type of allignment needs to be cleared?
	snprintf(myStr, 256, "Chapter %i : Frame %i/%i",  mBookmark.mCurChapter , mBookmark.mCurFrame + 1, mBookmark.mTotalFrames );
	[[DebugManager GetInstance] DrawString:[NSString stringWithUTF8String:myStr] locX:-50 locY:220 size:10 red:1.0 blue:0.0 green:0.0];	// -50 because of the misalignment, change back to 0
	*/
#endif
}

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData
{
    switch(inData->mTouchType)
    {
        case TOUCHES_BEGAN:
        {
            if ((mPanState != PAN_STATE_TRANSITION) && (mPanState != PAN_STATE_WAITING_FOR_LOAD))
            {
                if (inData->mTouchLocation.y < IMAGE_HEIGHT)
                {
                    mPanState = PAN_STATE_WAITING_FOR_GESTURES;
                }
                else
                {
                    mPanState = PAN_STATE_IDLE;
                }
            }
            
            break;
        }
        
        case TOUCHES_ENDED:
        {
            mPanState = PAN_STATE_IDLE;
            
#if !NEON_PRODUCTION
            if (inData->mNumTouches == 2)
            {
                [[Flow GetInstance] ProgressForward];
            }
#endif
            break;
        }
        
        case PAN_EVENT:
        {
            if (mPanState == PAN_STATE_WAITING_FOR_GESTURES)
            {
                UIGestureRecognizerState gestureRecognizerState = [mPanGestureRecognizer state];
                                
                switch(gestureRecognizerState)
                {
                    case UIGestureRecognizerStateBegan:
                    case UIGestureRecognizerStateChanged:
                    {
                        CGPoint translation = [mPanGestureRecognizer translationInView:gAppView];
                        
                        [self EvaluatePanBegin];
                        [self EvaluatePanTranslation:&translation];
                        
                        mLastPanVelocity = [mPanGestureRecognizer velocityInView:gAppView];
                        mLastPanVelocityTimestamp = CACurrentMediaTime();

                        break;
                    }
                    
                    case UIGestureRecognizerStateCancelled:
                    case UIGestureRecognizerStateEnded:
                    case UIGestureRecognizerStatePossible:
                    {
                        CGPoint translation = [mPanGestureRecognizer translationInView:gAppView];
                        [self EvaluatePanConclusion:&translation];
                        
                        break;
                    }
                }
            }
            
            break;
        }
    }
    
    return TOUCHSYSTEM_CONSUME_NONE;
}

-(void)EvaluatePanBegin
{
    [self ClearDisplay:FALSE];
}

-(void)EvaluatePanTranslation:(CGPoint*)inTranslation
{
    for (int i = 0; i < CUTSCENE_POSITION_NUM; i++)
    {
        ImageWell* curImageWell = (ImageWell*)[mSequentialLoader GetObjectAtWindowPosition:i];
        
        if (curImageWell != NULL)
        {
            // x and y are swapped because we're in landscape mode.  We also don't honor vertical translation.
            
            Vector3 position = { { ( i - CUTSCENE_POSITION_CENTER) * IMAGE_WIDTH, 0.0, 0.0 } };
            
            float scaleFactor = 1.0f;
            
            // Can't go back anymore, so scale the translation by a half to show that we can't go in that direction.
            if ((inTranslation->y > 0) && (mBookmark.mCurFrame == 0))
            {
                scaleFactor = 0.5f;
            }
            // Can't go forward anymore, so scale the translation by a half to show that we can't go in that direction.
            else if ((inTranslation->y < 0) && (mBookmark.mCurFrame == (mBookmark.mTotalFrames - 1)))
            {
                //scaleFactor = 0.5f;
            }
            
            Vector3 delta = { { inTranslation->y * scaleFactor, 0.0f, 0.0f } };
            
            Add3(&position, &delta, &position);
            
            [curImageWell SetPosition:&position];
        }
    }
}

-(void)EvaluatePanConclusion:(CGPoint*)inTranslation
{
    Vector3 curCenterPosition;
    
    ImageWell* centerWell = (ImageWell*)[mSequentialLoader GetObjectAtWindowPosition:CUTSCENE_POSITION_CENTER];
    [centerWell GetPosition:&curCenterPosition];
    
    BOOL velocityValid = (CACurrentMediaTime() - mLastPanVelocityTimestamp) < PAN_VELOCITY_EXPIRE_TIME;
    
    mFrameDelta = 0;
    
    if ((inTranslation->y <= (float)(-IMAGE_WIDTH / 2)) || ((mLastPanVelocity.y < -PAN_MIN_VELOCITY) && velocityValid))
    {
        //if (mCurFrame != (mNumFrames - 1))
        {
            mFrameDelta = 1;
        }
    }
    else if ((inTranslation->y > (float)(IMAGE_WIDTH / 2)) || ((mLastPanVelocity.y > PAN_MIN_VELOCITY) && velocityValid))
    {        
        if (mBookmark.mCurFrame != 0)
        {
            mFrameDelta = -1;
        }
    }
    
    for (int posIndex = 0; posIndex < CUTSCENE_POSITION_NUM; posIndex++)
    {
        ImageWell* cutsceneImageWell = (ImageWell*)[mSequentialLoader GetObjectAtWindowPosition:posIndex];
        
        if (cutsceneImageWell != NULL)
        {
            Vector3 curPosition;
            [cutsceneImageWell GetPosition:&curPosition];
            
            Vector3 desiredPosition = { { ( (posIndex - mFrameDelta) - CUTSCENE_POSITION_CENTER) * IMAGE_WIDTH, 0.0, 0.0 } };

            Path* animatePath = [(Path*)[Path alloc] Init];
            
            [animatePath AddNodeVec3:&curPosition atTime:0.0f];
            [animatePath AddNodeVec3:&desiredPosition atTime:PAN_ANIMATION_TIME];
            
            [animatePath SetCallback:self withData:0];

            mNumPanAnimations++;
            
            [cutsceneImageWell AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:animatePath];
            
            [animatePath release];
        }
    }
    
    mPanState = PAN_STATE_TRANSITION;
    
	// We have transitioned from one frame to another, play the slide frame sound
	if ( mFrameDelta )
	{
		[UISounds PlayUISound:SFX_MENU_SLIDE_FRAME];
		mBookmark.mCurFrame += mFrameDelta;
	}
}

-(void)PathEvent:(PathEvent)inEvent withPath:(Path*)inPath userData:(u32)inData
{
    NSAssert(mPanState == PAN_STATE_TRANSITION, @"Unexpected pan state in the PathEvent callback");
    
    mNumPanAnimations--;
    
    if (mNumPanAnimations == 0)
    {   
		mPanState = PAN_STATE_WAITING_FOR_LOAD;
        mWaitingFrames = WAITING_FRAMES;
        mFrameDelta = 0;
	}
}

-(NSObject*)PreloadObjectWithIndex:(int)inIndex forLoader:(SequentialLoader*)inLoader
{
    ImageWellParams imageParams;
    [ImageWell InitDefaultParams:&imageParams];

    imageParams.mTextureName	= [self GetFilenameForFrame:inIndex];
        
    ImageWell* newImage = [(ImageWell*)[ImageWell alloc] InitWithParams:&imageParams];
    [newImage autorelease];
    
    [[GameObjectManager GetInstance] Add:newImage];
    
    int activeIndex = [mSequentialLoader GetIndex];
    int curPosition = inIndex - activeIndex;

    [newImage SetPositionX:IMAGE_WIDTH * curPosition Y:0 Z:0];
    [newImage SetVisible:TRUE];
    
    newImage->mIdentifier = 0;

    return newImage;
}

-(void)ProcessLoadedObject:(NSObject*)inObject atIndex:(int)inIndex forLoader:(SequentialLoader*)inLoader
{
    ImageWell* imageWell = (ImageWell*)inObject;
    
    int activeIndex = [mSequentialLoader GetIndex];
    int curPosition = inIndex - activeIndex;

    [imageWell SetPositionX:IMAGE_WIDTH * curPosition Y:0 Z:0];
}

-(void)UnloadObject:(NSObject*)inObject atIndex:(int)inIndex forLoader:(SequentialLoader*)inLoader
{
    [[GameObjectManager GetInstance] Remove:(ImageWell*)inObject];
}

-(int)AddRef:(NSObject*)inObject
{
    return ++((ImageWell*)inObject)->mIdentifier;
}

-(int)DecRef:(NSObject*)inObject
{
    return --((ImageWell*)inObject)->mIdentifier;
}

@end