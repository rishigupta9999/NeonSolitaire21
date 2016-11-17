//
//  FacebookLoginMenu.m
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

#import "FacebookLoginMenu.h"
#import "Flow.h"
#import "NeonAccountManager.h"
#import "SplitTestingSystem.h"

static NSString* sBackgroundFileName = @"bg_facebook.papng";
static Vector3 sBackgroundPosition = {0, 0, 0};

static FacebookButton sFacebookButtons[FACEBOOKID_NUM] = {
          {@"facebook_login.papng", @"facebook_login.papng", @"facebook_login_glow.papng", SFX_MENU_BACK, {86 ,160, 0} },   // FACEBOOKID_LOGIN
          {@"facebook_later.papng", @"facebook_later.papng", @"facebook_later_glow.papng", SFX_MENU_BACK, {156,240, 0} }};  // FACEBOOKID_BACK

@implementation FacebookLoginMenuParams

-(FacebookLoginMenuParams*)InitWithType:(FacebookLoginMenuType)inType
{
    mType = inType;
    
    return self;
}

-(FacebookLoginMenuType)GetType
{
    return mType;
}

@end
                                        
@implementation FacebookLoginMenu

-(void)Startup
{
    [[NeonMetrics GetInstance] logEvent:@"Facebook Login Menu Entered" withParameters:NULL];
    
    [[Flow GetInstance] SetRequestedFacebookLogin:TRUE];
        
    GameObjectBatchParams groupParams;
    
    [GameObjectBatch InitDefaultParams:&groupParams];
    
    groupParams.mUseAtlas = TRUE;
    
	mUIObjects = [(UIGroup*)[UIGroup alloc] InitWithParams:&groupParams];

    [[GameObjectManager GetInstance] Add:mUIObjects];
    
    mBackground = sBackgroundFileName;
    [self ActivateBackgroundWithUIGroup:mUIObjects];
    [self ActivateButtons];
    [mUIObjects Finalize];
    [mUIObjects release];
    
        
    FaderParams faderParams;
    [Fader InitDefaultParams:&faderParams];
    
    faderParams.mFadeType = FADE_FROM_BLACK;
    
    [[Fader GetInstance] StartWithParams:&faderParams];
}

-(void)Resume
{
    NSAssert(FALSE, @"Shouldn't be here");
}
-(void)Shutdown
{
    [mUIObjects removeAllObjectsFinal:TRUE];
    [[GameObjectManager GetInstance] Remove:mUIObjects];
}

-(void)Suspend
{
    NSAssert(FALSE, @"Shouldn't be here");
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if(inEvent == BUTTON_EVENT_UP)
    {
        if (inButton == mButtons[FACEBOOKID_GUEST])
        {
            [[NeonMetrics GetInstance] logEvent:@"Facebook Login - Declined" withParameters:NULL];
            [self ExitMenu];
        }
        if (inButton == mButtons[FACEBOOKID_LOGIN])
        {
            [[NeonMetrics GetInstance] logEvent:@"Facebook Login - Accepted" withParameters:NULL];
            
            [self ExitMenu];
        }
    }
}


-(void) ActivateBackgroundWithUIGroup:(UIGroup*)inUIGroup
{
    //TODO: will have to change this to a more complicated thing once we have more Backgrounds, so they stay in the back
    ImageWell						*logoImage;
	
	ImageWellParams					imageWellparams;
	[ImageWell InitDefaultParams:	&imageWellparams];
	imageWellparams.mUIGroup		= inUIGroup;
    
    imageWellparams.mTextureName = mBackground;
    
	logoImage	=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
	[logoImage		SetPosition:&sBackgroundPosition];
	[logoImage		SetVisible:TRUE];
	[logoImage		release];
    
}

-(void)ActivateButtons
{
    for ( int i = 0 ; i < FACEBOOKID_NUM; i++ )
    {
        NeonButtonParams                buttonParams;
        [NeonButton InitDefaultParams:  &buttonParams ];
        
        buttonParams.mTexName					= sFacebookButtons[i].texName;
        buttonParams.mToggleTexName             = sFacebookButtons[i].toggleTexName;
        buttonParams.mPregeneratedGlowTexName	= sFacebookButtons[i].glowName;
        buttonParams.mUISoundId                 = sFacebookButtons[i].soundID;
        
        buttonParams.mText                      = NSLocalizedString(@"LS_EmptyString", NULL);  // Setting text to empty causes crash.
        buttonParams.mTextSize                  = 18;
        buttonParams.mBorderSize                = 1;
        buttonParams.mUIGroup                   = mUIObjects;
        buttonParams.mBoundingBoxCollision      = TRUE;
        
        SetColorFromU32(        &buttonParams.mBorderColor          , NEON_BLA);
        SetColorFromU32(        &buttonParams.mTextColor            , NEON_WHI);
        SetRelativePlacement(   &buttonParams.mTextPlacement        , PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
        SetVec2(                &buttonParams.mBoundingBoxBorderSize, 2                     , 2);
        
        mButtons[i] = [ (NeonButton*)[NeonButton alloc] InitWithParams:&buttonParams ];
        [mButtons[i] Enable];
        [mButtons[i] SetVisible:TRUE];
        [mButtons[i] SetPosition:&sFacebookButtons[i].location];
        [mButtons[i] SetListener:self];
        [mButtons[i] release];
    }
}

-(void)ExitMenu
{
    if (mParams == NULL)
    {
        [[GameStateMgr GetInstance] Pop];
    }
    else
    {
        FacebookLoginMenuParams* params = (FacebookLoginMenuParams*)mParams;
        
        switch([params GetType])
        {
            case FACEBOOK_LOGIN_MENU_RETRY:
            case FACEBOOK_LOGIN_MENU_ADVANCE:
            {
                FaderParams faderParams;
                [Fader InitDefaultParams:&faderParams];

                faderParams.mFadeType = FADE_TO_BLACK_HOLD;
                faderParams.mCallback = self;

                [[Fader GetInstance] StartWithParams:&faderParams];

                break;
            }
        }
    }
}

-(void)FadeComplete:(NSObject*)inObject
{
    FacebookLoginMenuParams* params = (FacebookLoginMenuParams*)mParams;

    switch([params GetType])
    {
        case FACEBOOK_LOGIN_MENU_RETRY:
        {
            [[Flow GetInstance] RestartLevel];
            break;
        }
        
        case FACEBOOK_LOGIN_MENU_ADVANCE:
        {
            [[Flow GetInstance] AdvanceLevel];
            break;
        }
    }

}

@end
