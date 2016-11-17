//
//  OverlayState.m
//  Neon21
//
//  Copyright Neon Games 2014. All rights reserved.
//

#import "OverlayState.h"
#import "TextureButton.h"
#import "GameObjectManager.h"
#import "NeonArrow.h"
#import "UIGroup.h"
#import "TextBox.h"
#import "NeonButton.h"
#import "GameStateMgr.h"

#define OVERLAY_BACKGROUND_OPACITY  (0.5)
#define ATLAS_PADDING_SIZE          (4)

static const NSString* sOKButtonTextureName = @"okbutton.papng";
static const NSString* sOKButtonPressedTextureName = @"okbutton_pressed.papng";

@implementation OverlayStateParams

@synthesize OverlayId = mOverlayId;

-(OverlayStateParams*)init
{
    mOverlayId = OVERLAY_ID_INVALID;
    
    return self;
}

@end

@interface OverlayEntry : NSObject
{
    @public
        Vector2     mArrowPosition;
        float       mArrowLength;
        Vector2     mArrowScale;
        float       mArrowRotation;
        
        Vector2     mTextPosition;
        float       mTextSize;
        float       mTextWidth;
        NSString*   mText;
}

-(OverlayEntry*)init;
-(void)dealloc;

-(void)SetArrowPositionX:(float)inX y:(float)inY;
-(void)SetArrowLength:(float)inLength;
-(void)SetArrowScaleX:(float)inX y:(float)inY;
-(void)SetArrowRotation:(float)inTextRotation;

-(void)SetTextPositionX:(float)inX y:(float)inY;
-(void)SetTextSize:(float)inTextSize;
-(void)SetTextWidth:(float)inTextWidth;
-(void)SetText:(NSString*)inText;

@end

@implementation OverlayEntry

-(OverlayEntry*)init
{
    SetVec2(&mArrowPosition, 0.0, 0.0);
    mArrowLength = 100;
    SetVec2(&mArrowScale, 1.0, 1.0);
    mArrowRotation = 0;

    SetVec2(&mTextPosition, 0.0, 0.0);
    mTextSize = 18;
    mTextWidth = 100;
    
    mText = NULL;

    return self;
}

-(void)dealloc
{
    [mText release];
    
    [super dealloc];
}

-(void)SetArrowPositionX:(float)inX y:(float)inY
{
    SetVec2(&mArrowPosition, inX, inY);
}

-(void)SetArrowLength:(float)inLength
{
    mArrowLength = inLength;
}

-(void)SetArrowScaleX:(float)inX y:(float)inY
{
    SetVec2(&mArrowScale, inX, inY);
}

-(void)SetArrowRotation:(float)inTextRotation
{
    mArrowRotation = inTextRotation;
}

-(void)SetTextPositionX:(float)inX y:(float)inY
{
    SetVec2(&mTextPosition, inX, inY);
}

-(void)SetTextSize:(float)inTextSize
{
    mTextSize = inTextSize;
}

-(void)SetTextWidth:(float)inTextWidth
{
    mTextWidth = inTextWidth;
}

-(void)SetText:(NSString*)inText
{
    mText = [inText retain];
}

@end

@implementation OverlayState

-(void)Startup
{
    mOverlayEntries = [[NSMutableArray alloc] init];
    
    OverlayStateParams* params = (OverlayStateParams*)mParams;
    
    switch(params.OverlayId)
    {
        case OVERLAY_ID_LEVEL_SELECT:
        {
            OverlayEntry* entry = [[OverlayEntry alloc] init];
            [entry SetArrowLength:200];
            [entry SetArrowPositionX:425.0 y:35];
            [entry SetArrowScaleX:0.25 y:0.25];
            [entry SetArrowRotation:20.0];
            [entry SetTextPositionX:370 y:125];
            [entry SetTextWidth:105];
            [entry SetText:NSLocalizedString(@"LS_Overlay_Levels", NULL)];
            [entry SetTextSize:16];
            [mOverlayEntries addObject:entry];
            [entry release];
            
            entry = [[OverlayEntry alloc] init];
            [entry SetArrowLength:200];
            [entry SetArrowPositionX:40.0 y:75.0];
            [entry SetArrowScaleX:0.15 y:0.15];
            [entry SetText:NSLocalizedString(@"LS_Overlay_Audio", NULL)];
            [entry SetTextPositionX:2 y:130];
            [entry SetTextSize:16];
            [entry SetTextWidth:115];
            [mOverlayEntries addObject:entry];
            [entry release];
            
            entry = [[OverlayEntry alloc] init];
            [entry SetArrowLength:100];
            [entry SetArrowPositionX:135.0 y:220.0];
            [entry SetArrowScaleX:0.15 y:0.15];
            [mOverlayEntries addObject:entry];
            [entry SetText:NSLocalizedString(@"LS_Overlay_EnterLevel", NULL)];
            [entry SetTextPositionX:110 y:260];
            [entry SetTextSize:16];
            [entry SetTextWidth:300];
            [entry release];
            
            entry = [[OverlayEntry alloc] init];
            [entry SetArrowLength:100];
            [entry SetArrowPositionX:227.0 y:220.0];
            [entry SetArrowScaleX:0.15 y:0.15];
            [mOverlayEntries addObject:entry];
            [entry release];
            
            entry = [[OverlayEntry alloc] init];
            [entry SetArrowLength:100];
            [entry SetArrowPositionX:319.0 y:220.0];
            [entry SetArrowScaleX:0.15 y:0.15];
            [mOverlayEntries addObject:entry];
            [entry release];
            
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unimplemented OverlayId");
            break;
        }
    }
    
    [self SetupBackground];
    [self AnalyzeOverlayEntries];
    
    TextureButtonParams buttonParams;
    [TextureButton InitDefaultParams:&buttonParams];
    
    buttonParams.mButtonTexBaseName         = (NSString*)sOKButtonTextureName;
    buttonParams.mButtonTexHighlightedName	= (NSString*)sOKButtonPressedTextureName;

    buttonParams.mUIGroup					= mUIGroup;
	buttonParams.mUISoundId					= SFX_MENU_BUTTON_PRESS;

	mOKButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&buttonParams];
    [mOKButton SetPositionX:375 Y:275 Z:0.0];
    [mOKButton SetListener:self];
    [mOKButton SetVisible:FALSE];
    [mOKButton Enable];
    
    [mOKButton release];
    
    [mUIGroup Finalize];
    [[GameObjectManager GetInstance] Add:mUIGroup];
}

-(void)Resume
{
}

-(void)Shutdown
{
    [mOverlayEntries release];
}

-(void)Suspend
{
}

-(void)SetupBackground
{
    TextureButtonParams textureButtonParams;
    
    [TextureButton InitDefaultParams:&textureButtonParams];
    SetColorFloat(&textureButtonParams.mColor, 0.0, 0.0, 0.0, OVERLAY_BACKGROUND_OPACITY);
    
    mBackground = [(TextureButton*)[TextureButton alloc] InitWithParams:&textureButtonParams];
    
    [mBackground SetVisible:TRUE];
    [mBackground SetScaleX:GetScreenVirtualWidth() Y:GetScreenVirtualHeight() Z:1.0];

    Path* alphaPath = [[Path alloc] Init];
    
    [alphaPath AddNodeScalar:0.0 atTime:0.0];
    [alphaPath AddNodeScalar:1.0 atTime:1.0];
    
    [mBackground AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:alphaPath];
    
    [alphaPath release];
    
    [[GameObjectManager GetInstance] Add:mBackground];
}

-(void)AnalyzeOverlayEntries
{
    GameObjectBatchParams groupParams;
    [GameObjectBatch InitDefaultParams:&groupParams];
    
    groupParams.mUseAtlas = TRUE;
    
    mUIGroup = [[UIGroup alloc] InitWithParams:&groupParams];
    
    // Use a bit of padding, there's some bleeding of the arrow into other textures in the texture atlas
    [[mUIGroup GetTextureAtlas] SetPaddingSize:ATLAS_PADDING_SIZE];
    
    NeonArrowParams neonArrowParams;
    [NeonArrow InitDefaultParams:&neonArrowParams];

    neonArrowParams.mUIGroup = mUIGroup;
    
    TextBoxParams textBoxParams;
    [TextBox InitDefaultParams:&textBoxParams];
    
    textBoxParams.mUIGroup = mUIGroup;
    SetColorFloat(&textBoxParams.mColor, 1.0, 0.91, 0.27, 1.0);
    SetColorFloat(&textBoxParams.mStrokeColor, 0.0, 0.0, 0.0, 1.0);
    textBoxParams.mStrokeSize = 5;
    
    for (OverlayEntry* curEntry in mOverlayEntries)
    {
        neonArrowParams.mLength = curEntry->mArrowLength;
        NeonArrow* curArrow = [[NeonArrow alloc] initWithParams:&neonArrowParams];
        
        [curArrow SetPositionX:curEntry->mArrowPosition.mVector[x] Y:curEntry->mArrowPosition.mVector[y] Z:0.0];
        [curArrow SetScaleX:curEntry->mArrowScale.mVector[x] Y:curEntry->mArrowScale.mVector[y] Z:1.0];
        
        [curArrow SetOrientationX:0.0 Y:0.0 Z:curEntry->mArrowRotation];
        [curArrow SetVisible:FALSE];
        [curArrow Enable];
        
        if (curEntry->mText != NULL)
        {
            textBoxParams.mString = curEntry->mText;
            textBoxParams.mFontSize = curEntry->mTextSize;
            textBoxParams.mWidth = curEntry->mTextWidth;
            
            TextBox* curTextBox = [[TextBox alloc] InitWithParams:&textBoxParams];
            [curTextBox SetPositionX:curEntry->mTextPosition.mVector[x] Y:curEntry->mTextPosition.mVector[y] Z:0.0];
            [curTextBox SetVisible:FALSE];
            [curTextBox Enable];
            
            [curTextBox release];
        }
        
        [curArrow release];
    }
}

-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if (inEvent == BUTTON_EVENT_UP)
    {
        if (inButton == mOKButton)
        {
            int count = [mUIGroup count];
            
            for (int i = 0; i < count; i++)
            {
                GameObject* curObject = [mUIGroup objectAtIndex:i];
                
                [(UIObject*)curObject Disable];
            }
            
            [mBackground Disable];
            
            [mBackground PerformAfterOperationsInQueue:dispatch_get_main_queue() block:^
            {
                [[GameStateMgr GetInstance] Pop];
            } ];

        }
    }
}

@end