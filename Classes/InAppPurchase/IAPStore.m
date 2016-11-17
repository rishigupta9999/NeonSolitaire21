//
//  IAPStore.m
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

#import "IAPStore.h"
#import "GameObjectManager.h"
#import "SaveSystem.h"
#import "RegenerationManager.h"
#import "Fader.h"
#import "LevelDefinitions.h"
#import "NeonSpinner.h"
#import "MainMenu.h"
#import "Neon21AppDelegate.h"
#import "StringCloud.h"

static const char* sBackButtonFileName = "iap_store_exit.papng";
static const char* sBackButtonGlowFileName = "iap_store_exit_glow.papng";
static Vector3 sBackButtonLocation = { 0, 0, 0	};

static Vector3 sButtonScale = {1.0, 1.0, 1.0};

static NSString* sPurchaseButtonFilenames[NUM_QUANTITIES_PER_IAP] = { @"store_bronze.papng",
                                                                      @"store_silver.papng",
                                                                      @"store_gold.papng"   };

static NSString* sRestoreButtonFilename = @"store_emerald.papng";

static const int sPowerupRowHeight = 106;

static const NSString* sPowerupRowFileName = @"run21_powerup_row.papng";
static const NSString* sPowerupLockedRowFileName = @"run21_powerup_locked_row.papng";
static const NSString* sPurchaseButtonGlowFilename = @"store_glow.papng";
static const NSString* sRestoreButtonGlowFilename = @"store_emerald_glow.papng";

@interface PowerupInfo : NSObject
{
    @public
        IapProduct  mProductIDs[NUM_QUANTITIES_PER_IAP];
        Vector2     mQuantityStringPosition;
        Vector2     mQuantityStringWidth;
}

@property (retain) NSString* OverlayFilename;
@property (retain) NSString* DescriptionString;
@property (retain) NSString* DescriptionStringTimed;

@property BOOL QuantityRequiresUpdate;
@property int  QuantityStringFontSize;
@property (retain) NSString* QuantityString;
@property (retain) NSString* QuantityAccessor;

@property (retain) NSString* Unlocked;
@property (retain) NSString* UnlockLevel;
@property (retain) NSString* PowerupName;

@property (retain) NSString* PowerupPurchaseSelector;
@property (retain) NSString* ActiveSelector;

@property BOOL HasRestoreButton;

-(PowerupInfo*)init;
-(void)SetProduct:(IapProduct)inProductId forIndex:(int)inIndex;
-(IapProduct)GetProductForIndex:(int)inIndex;

@end

@implementation PowerupInfo

@synthesize OverlayFilename = mOverlayFilename;
@synthesize DescriptionString = mDescriptionString;
@synthesize DescriptionStringTimed = mDescriptionStringTimed;

@synthesize QuantityRequiresUpdate = mQuantityRequiresUpdate;
@synthesize QuantityStringFontSize = mQuantityStringFontSize;
@synthesize QuantityString = mQuantityString;
@synthesize QuantityAccessor = mQuantityAccessor;

@synthesize Unlocked = mUnlocked;
@synthesize UnlockLevel = mUnlockLevel;
@synthesize PowerupName = mPowerupName;

@synthesize PowerupPurchaseSelector = mPowerupPurchaseSelector;
@synthesize ActiveSelector = mActiveSelector;

@synthesize HasRestoreButton = mHasRestoreButton;

-(PowerupInfo*)init
{
    mOverlayFilename = NULL;
    mDescriptionString = NULL;
    mDescriptionStringTimed = NULL;
    
    for (int i = 0; i < NUM_QUANTITIES_PER_IAP; i++)
    {
        mProductIDs[i] = IAP_PRODUCT_INVALID;
    }
    
    mQuantityRequiresUpdate = FALSE;
    mQuantityStringFontSize = 14;
    mQuantityString = @"GetPowerupQuantityDescription:";
    mQuantityAccessor = NULL;
    
    mUnlocked = NULL;
    mUnlockLevel = NULL;
    mPowerupName = NULL;
    
    SetVec2(&mQuantityStringPosition, 10, 80);
    
    mPowerupPurchaseSelector = @"GetQuantityPowerup:";
    mActiveSelector = NULL;
    
    mHasRestoreButton = FALSE;
    
    return self;
}

-(void)dealloc
{
    [mOverlayFilename release];
    [mDescriptionString release];
    [mDescriptionStringTimed release];
    [mQuantityString release];
    [mQuantityAccessor release];
    [mUnlocked release];
    [mUnlockLevel release];
    [mPowerupName release];
    [mActiveSelector release];
    
    [super dealloc];
}

-(void)SetProduct:(IapProduct)inProductId forIndex:(int)inIndex
{
    NSAssert((inIndex >= 0) && (inIndex < NUM_QUANTITIES_PER_IAP), @"Invalid index");
    
    mProductIDs[inIndex] = inProductId;
}

-(IapProduct)GetProductForIndex:(int)inIndex
{
    NSAssert((inIndex >= 0) && (inIndex < NUM_QUANTITIES_PER_IAP), @"Invalid index");

    return mProductIDs[inIndex];
}

@end

static Vector2 sPowerupButtonOffsets[NUM_QUANTITIES_PER_IAP] = { { 100, 35 },
                                                                 { 215, 35 },
                                                                 { 330, 35 } };

@implementation IAPStoreParams

@synthesize MessageString = mMessageString;
@synthesize StoreMode = mStoreMode;

-(IAPStoreParams*)init
{
    mMessageString = NULL;
    mStoreMode = IAPSTORE_MODE_NORMAL;
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

@end

@implementation IAPButton

-(void)SetActive:(BOOL)inActive
{
    [mTextPrice SetActive:inActive];
    [mQuantityTextBox SetActive:inActive];
    
    [super SetActive:inActive];
}

-(void)DispatchEvent:(ButtonEvent)inEvent;
{
    BOOL success = [mListenerObj ButtonEvent:inEvent Button:self];
    
    if ((inEvent == BUTTON_EVENT_UP) && (success))
    {
        [[GameStateMgr GetInstance] SendEvent:EVENT_ANY_BUTTON_UP withData:self];
    }
}

@end

@implementation IAPRow

-(IAPRow*)init
{
    mBackground = NULL;
    memset(mButtons, 0, sizeof(mButtons));
    mAmount = 0;
    memset(mQuantities, 0, sizeof(mQuantities));
    
    mRestoreButton = NULL;
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

@end

@implementation IAPStore

-(IAPStore*)Init
{
    // X-ray
    mIAPRowDefinitions[0] = [[PowerupInfo alloc] init];
    
    mIAPRowDefinitions[0].OverlayFilename = @"run21_xray_overlay.papng";
    mIAPRowDefinitions[0].DescriptionString = @"LS_Powerup_Xray_Description";
    mIAPRowDefinitions[0].DescriptionStringTimed = @"LS_Powerup_Xray_Description_Timed";
    
    [mIAPRowDefinitions[0] SetProduct:IAP_PRODUCT_XRAY_BRONZE forIndex:0];
    [mIAPRowDefinitions[0] SetProduct:IAP_PRODUCT_XRAY_SILVER forIndex:1];
    [mIAPRowDefinitions[0] SetProduct:IAP_PRODUCT_XRAY_GOLD forIndex:2];
    
    mIAPRowDefinitions[0].QuantityAccessor = @"GetNumXrays";
    mIAPRowDefinitions[0].Unlocked = @"GetXrayUnlocked";
    mIAPRowDefinitions[0].UnlockLevel = @"GetXrayUnlockLevel";
    mIAPRowDefinitions[0].PowerupName = @"LS_Powerup_Xrays";
    
    // Tornado
    mIAPRowDefinitions[1] = [[PowerupInfo alloc] init];
    
    mIAPRowDefinitions[1].OverlayFilename = @"run21_tornado_overlay.papng";
    mIAPRowDefinitions[1].DescriptionString = @"LS_Powerup_Tornado_Description";
    mIAPRowDefinitions[1].DescriptionStringTimed = @"LS_Powerup_Tornado_Description_Timed";
    
    [mIAPRowDefinitions[1] SetProduct:IAP_PRODUCT_TORNADO_BRONZE forIndex:0];
    [mIAPRowDefinitions[1] SetProduct:IAP_PRODUCT_TORNADO_SILVER forIndex:1];
    [mIAPRowDefinitions[1] SetProduct:IAP_PRODUCT_TORNADO_GOLD forIndex:2];
    
    mIAPRowDefinitions[1].QuantityAccessor = @"GetNumTornadoes";
    mIAPRowDefinitions[1].Unlocked = @"GetTornadoUnlocked";
    mIAPRowDefinitions[1].UnlockLevel = @"GetTornadoUnlockLevel";
    mIAPRowDefinitions[1].PowerupName = @"LS_Powerup_Tornadoes";
        
    return self;
}

-(void)dealloc
{
    for (int i = 0; i < IAPSTORE_PRODUCT_NUM; i++)
    {
        [mIAPRowDefinitions[i] release];
    }
    
    [super dealloc];
}

-(void)Startup
{
    GameObjectBatchParams groupParams;
    
    [GameObjectBatch InitDefaultParams:&groupParams];
    
    groupParams.mUseAtlas = TRUE;
    
	mUIObjects = [(UIGroup*)[UIGroup alloc] InitWithParams:&groupParams];
    [mUIObjects SetPositionX:0.0 Y:25.0 Z:0.0];
    
    mYOffset = 50;
    
    for (int i = 0; i < IAPSTORE_PRODUCT_NUM; i++)
    {
        mIAPRows[i] = [[IAPRow alloc] init];
    }
    
    [self ActivateConsumablesTab];
    [self ActivateStatus];
    
    [self ActivateMessage];
    
    //add this last so that the back button appears on top of the background
    [[GameObjectManager GetInstance] Add:mUIObjects];
    
    [self ActivateBackButton];
    
    if (([[SaveSystem GetInstance] GetNumTotalPurchases] == 0) && ([[[Flow GetInstance] GetLevelDefinitions] GetRoomsUnlocked]))
    {
        StringCloudParams* stringCloudParams = [[StringCloudParams alloc] init];
        stringCloudParams->mUIGroup = mUIObjects;
        [stringCloudParams->mStrings addObject:@"<B>Any purchase removes ads!</B>"];
        [stringCloudParams->mStrings addObject:@"<B><color=0xFFE845>Any purchase removes ads!</color></B>"];
        stringCloudParams->mFontSize = 16;
        
        mRemoveAds = [[StringCloud alloc] initWithParams:stringCloudParams];
        [mRemoveAds SetPositionX:220 Y:245 Z:0.0];
        
        [stringCloudParams release];
    }

    [mUIObjects Finalize];
    
    mIAPStoreState = IAPSTORE_STATE_NORMAL;
    
    FaderParams faderParams;
    [Fader InitDefaultParams:&faderParams];
    
    faderParams.mFadeType = FADE_FROM_BLACK;
    faderParams.mFrameDelay = 2;
    
    if ([[InAppPurchaseManager GetInstance] GetIAPState] == IAP_STATE_PENDING)
    {
        [self SetIAPStoreState:IAPSTORE_STATE_PURCHASING];
    }
    
    mUIEnabled = FALSE;
    
    mFrameDelay = 3;
    
    [[NeonMetrics GetInstance] logEvent:@"IAP Store Enter" withParameters:NULL];
}

-(void)Resume
{
    
}

-(void)Shutdown
{
    [self LeaveMenu];
    
    for (int i = 0; i < IAPSTORE_PRODUCT_NUM; i++)
    {
        [mIAPRows[i] release];
    }

    [[GameObjectManager GetInstance] Remove:mSpinner];

    [[NeonMetrics GetInstance] logEvent:@"IAP Store Exit" withParameters:NULL];
}

-(void)Suspend
{

}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if (mFrameDelay > 0)
    {
        mFrameDelay--;
        
        if (mFrameDelay == 0)
        {
            if (!mUIEnabled)
            {
                mUIEnabled = TRUE;
                
                [self EnableAllItems];
            }
        }
    }


    // We don't really have a mechanism for the InAppPurchaseManager to do stuff with listeners.  This is better, but generally
    // prone to memory leaks or other issues.  So we'll go with the slightly more unclean way of polling the InAppPurchaseManager
    switch(mIAPStoreState)
    {
        case IAPSTORE_STATE_PURCHASING:
        {
            if ([[InAppPurchaseManager GetInstance] GetIAPState] == IAP_STATE_IDLE)
            {
                [self SetIAPStoreState:IAPSTORE_STATE_NORMAL];
            }
            
            break;
        }
    }
    
    for (int curProduct = 0; curProduct < IAPSTORE_PRODUCT_NUM; curProduct++)
    {
        if (mIAPRowDefinitions[curProduct].QuantityRequiresUpdate)
        {
            SEL quantityStringSelector = NSSelectorFromString(mIAPRowDefinitions[curProduct].QuantityString);
            NSString* newString = [self performSelector:quantityStringSelector withObject:[NSNumber numberWithInt:curProduct]];
            
            [mIAPRows[curProduct]->mAmount SetString:newString];
        }
    }
}

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData
{
    SaveSystem *saveFile = [SaveSystem GetInstance];
    
    switch(inEventId)
    {
        case EVENT_IAP_DELIVER_CONTENT:
        {
            InAppPurchaseManager* inAppPurchaseManager  = [InAppPurchaseManager GetInstance];
            IapProduct product                          = [inAppPurchaseManager GetIAPWithIdentifier:inData];
            BOOL foundProduct                           = FALSE;
            
            [mRemoveAds Disable];

            for (int curProduct = 0; curProduct < IAPSTORE_PRODUCT_NUM; curProduct++)
            {
                for (int i = 0; i < NUM_QUANTITIES_PER_IAP; i++)
                {
                    if (product == [mIAPRowDefinitions[curProduct] GetProductForIndex:i])
                    {
                        foundProduct = TRUE;
                        
                        int numProducts = 0;
                        
                        switch(curProduct)
                        {
                            case IAPSTORE_PRODUCT_XRAY:
                            {
                                numProducts = [saveFile GetNumXrays];
                                break;
                            }
                            
                            case IAPSTORE_PRODUCT_TORNADOES:
                            {
                                numProducts = [saveFile GetNumTornadoes];
                                break;
                            }
                            
                            default:
                            {
                                break;
                            }
                        }
                        
                        SEL quantityStringSelector = NSSelectorFromString(mIAPRowDefinitions[curProduct].QuantityString);
                        [mIAPRows[curProduct]->mAmount SetString:[self performSelector:quantityStringSelector withObject:[NSNumber numberWithInt:curProduct]]];
                        break;
                    }
                }
            }

            if ( foundProduct && product >= IAP_PRODUCT_CONSUMABLE_FIRST && IAP_PRODUCT_CONSUMABLE_LAST >= product)
            {
                int         tiersSpent  = 0;
                const int   tier_Bronze = 1;
                const int   tier_Silver = 3;
                const int   tier_Gold   = 10;
                
                switch (product)
                {
                    case IAP_PRODUCT_TORNADO_BRONZE:
                    case IAP_PRODUCT_XRAY_BRONZE:
                        tiersSpent = tier_Bronze;
                        break;
                        
                    case IAP_PRODUCT_TORNADO_SILVER:
                    case IAP_PRODUCT_XRAY_SILVER:
                        tiersSpent = tier_Silver;
                        break;

                    case IAP_PRODUCT_TORNADO_GOLD:
                    case IAP_PRODUCT_XRAY_GOLD:
                        tiersSpent = tier_Gold;
                        break;
                        
                    case IAP_PRODUCT_UNLOCK_NEXT:
                        tiersSpent = tier_Bronze;
                        break;

                    default:
                        NSAssert(FALSE, @"Unknown IAP product");
                        break;
                }
                
                [saveFile AddTierPurchased:tiersSpent];
            }          
            break;
        }
    }
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if (inEvent == BUTTON_EVENT_UP)
    {
        // if the user hit the back button, we are done with this menu
        if (inButton == mBackButton)
        {
            [[GameStateMgr GetInstance] Pop];
            return;
        }
        
        for (int curProduct = 0; curProduct < IAPSTORE_PRODUCT_NUM; curProduct++)
        {
            for(int i = 0; i < NUM_QUANTITIES_PER_IAP; i++)
            {
                if (inButton == mIAPRows[curProduct]->mButtons[i])
                {
                    [self RequestProduct:[mIAPRowDefinitions[curProduct] GetProductForIndex:i]];
                    return;
                }
            }
            
            if (inButton == mIAPRows[curProduct]->mRestoreButton)
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LS_RestorePurchases", NULL) message:NSLocalizedString(@"LS_RestorePurchasesText", NULL) delegate:self cancelButtonTitle:NSLocalizedString(@"LS_Cancel", NULL) otherButtonTitles:NSLocalizedString(@"LS_OK", NULL), NULL];
                [alert show];
                [alert release];
            }
        }
    }
}

-(void)LeaveMenu
{
    int numObjects = [mUIObjects count];
    for (int i = 0; i < numObjects; i++)
    {
        UIObject *nObject = [ mUIObjects objectAtIndex:i ];
        
        [nObject RemoveAfterOperations];
        [nObject Disable];
    }
}

-(void)ActivateConsumablesTab
{
    [self ActivatePowerups];
}

-(void)ActivateBackButton
{
    NeonButtonParams	buttonParams;
    [NeonButton InitDefaultParams:&buttonParams ];
    
	buttonParams.mTexName					= [NSString stringWithUTF8String:sBackButtonFileName];
    buttonParams.mToggleTexName             = [NSString stringWithUTF8String:sBackButtonFileName];
    buttonParams.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:sBackButtonGlowFileName];
    
    buttonParams.mText					= NULL;
	buttonParams.mTextSize				= 18;
    buttonParams.mBorderSize            = 1;
	buttonParams.mUIGroup               = mUIObjects;
    buttonParams.mBoundingBoxCollision  = TRUE;
	buttonParams.mUISoundId             = SFX_MENU_BACK;
    
	SetColorFromU32(&buttonParams.mBorderColor, NEON_BLA);
    SetColorFromU32(&buttonParams.mTextColor, NEON_WHI);
    SetRelativePlacement(&buttonParams.mTextPlacement, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
    SetVec2(&buttonParams.mBoundingBoxBorderSize, 16, 16);
    
    mBackButton = [ (NeonButton*)[NeonButton alloc] InitWithParams:&buttonParams ];
    [mBackButton Enable];
    [mBackButton SetVisible:TRUE];
	[mBackButton SetPositionX:sBackButtonLocation.mVector[x] Y:(sBackButtonLocation.mVector[y]) Z:sBackButtonLocation.mVector[z] ];
    [mBackButton SetListener:self];
    [mBackButton release];
}

-(void)ActivateStatus
{
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    SetColorFromU32(&tbParams.mColor,          NEON_WHI);
    SetColorFromU32(&tbParams.mStrokeColor,    NEON_BLA);
    
    tbParams.mStrokeSize	= 2;
    tbParams.mString		= NSLocalizedString(@"LS_Connecting", NULL);
    tbParams.mFontSize		= 18;
    tbParams.mFontType		= NEON_FONT_NORMAL;
    tbParams.mUIGroup		= mUIObjects;
    
    mConnectingTextBox     = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    
    [mConnectingTextBox SetVisible:FALSE];
    [mConnectingTextBox Disable];
    [mConnectingTextBox SetPositionX:200 Y:(30 + mYOffset) Z:0.0];
    [mConnectingTextBox release];
}

-(void)ActivateMessage
{
    NSString* messageString = ((IAPStoreParams*)mParams).MessageString;
    mSpinner = NULL;
    
    if (messageString == NULL)
    {
        return;
    }
    
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    SetColorFromU32(&tbParams.mColor,          NEON_WHI);
    SetColorFromU32(&tbParams.mStrokeColor,    NEON_BLA);
    
    tbParams.mStrokeSize	= 2;
    tbParams.mString		= messageString;
    tbParams.mFontSize		= 30;
    tbParams.mStrokeSize    = 10;
    tbParams.mFontType		= NEON_FONT_NORMAL;
    tbParams.mUIGroup		= mUIObjects;
    tbParams.mWidth         = 470;
    
    TextBox* msgBox = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    
    [msgBox Enable];
    [msgBox SetPositionX:10 Y:220 Z:0.0];
    [msgBox release];
    
    NeonSpinnerParams params;
    [NeonSpinner InitDefaultParams:&params];
    
    mSpinner = [[NeonSpinner alloc] initWithParams:&params];
    
    if (GetDeviceiPhoneTall())
    {
        [mSpinner SetSizeWidth:140 height:50];
        [mSpinner SetPositionX:45 Y:125 Z:0.0];
    }
    else if (GetDevicePad())
    {
        [mSpinner SetSizeWidth:140 height:45];
        [mSpinner SetPositionX:30 Y:130 Z:0.0];
    }
    else
    {
        [mSpinner SetSizeWidth:155 height:50];
        [mSpinner SetPositionX:13 Y:125 Z:0.0];
    }
    
    [[GameObjectManager GetInstance] Add:mSpinner];
    [mSpinner release];
    
}

-(void)ActivatePowerups
{
    LevelDefinitions* levelDefinitions = [[Flow GetInstance] GetLevelDefinitions];
    
    IAPStoreMode storeMode = IAPSTORE_MODE_NORMAL;
    
    if (mParams != NULL)
    {
        storeMode = ((IAPStoreParams*)mParams).StoreMode;
    }
    
    for (int curProduct = 0; curProduct < IAPSTORE_PRODUCT_NUM; curProduct++)
    {
        if ((curProduct > IAPSTORE_PRODUCT_POWERUP_LAST) && (storeMode == IAPSTORE_MODE_POWERUP))
        {
            break;
        }
        
        [self ActivateRowBackground:curProduct];
        
        SEL productUnlockedSelector = NSSelectorFromString(mIAPRowDefinitions[curProduct].Unlocked);
        BOOL productLocked = !(BOOL)[levelDefinitions performSelector:productUnlockedSelector];

        if (productLocked)
        {
            continue;
        }
        
        for (int i = 0; i < NUM_QUANTITIES_PER_IAP; i++)
        {
            if ([mIAPRowDefinitions[curProduct] GetProductForIndex:i] == IAP_PRODUCT_INVALID)
            {
                continue;
            }
            
            NSArray* productQuantityPair = [NSArray arrayWithObjects:[NSNumber numberWithInt:curProduct], [NSNumber numberWithInt:i], NULL];
            
            NeonButtonParams	buttonParams;
            [NeonButton InitDefaultParams:&buttonParams ];
            
            buttonParams.mTexName					= sPurchaseButtonFilenames[i];
            buttonParams.mToggleTexName             = sPurchaseButtonFilenames[i];
            buttonParams.mPregeneratedGlowTexName	= (NSString*)sPurchaseButtonGlowFilename;
            
            buttonParams.mText					= NULL;
            buttonParams.mTextSize				= 18;
            buttonParams.mBorderSize				= 1;
            buttonParams.mUIGroup                 = mUIObjects;
            buttonParams.mBoundingBoxCollision    = TRUE;
            SetColorFromU32(&buttonParams.mBorderColor	, NEON_BLA);
            SetColorFromU32(&buttonParams.mTextColor		, NEON_WHI);
            SetRelativePlacement(&buttonParams.mTextPlacement, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
            SetVec2(&buttonParams.mBoundingBoxBorderSize, 2, 2);
            
            IAPButton* curButton = NULL;
            curButton = (IAPButton*)[[IAPButton alloc] InitWithParams:&buttonParams ];
            [curButton SetVisible:TRUE];
            [curButton SetScale:&sButtonScale];
            [curButton SetPositionX:sPowerupButtonOffsets[i].mVector[x] Y:sPowerupButtonOffsets[i].mVector[y] + (sPowerupRowHeight * curProduct) Z:0.0];
            [curButton SetListener:self];
            [curButton release];
            
            mIAPRows[curProduct]->mButtons[i] = curButton;
            
            TextBoxParams tbParams;
            [TextBox InitDefaultParams:&tbParams];
            SetColorFromU32(&tbParams.mColor,          NEON_WHI);
            SetColorFromU32(&tbParams.mStrokeColor,    NEON_BLA);
            
            SKProduct* product = [[InAppPurchaseManager GetInstance] GetProduct:[mIAPRowDefinitions[curProduct] GetProductForIndex:i]];
            NSString* price = @"-";
            
            if (product != NULL)
            {
                price = [[InAppPurchaseManager GetInstance] GetLocalizedPrice:product];
            }
            
            tbParams.mStrokeSize	= 10;
            tbParams.mString		= price;
            tbParams.mFontSize		= 12;
            tbParams.mFontType		= NEON_FONT_NORMAL;
            tbParams.mWidth         = 320;
            tbParams.mUIGroup		= mUIObjects;
            tbParams.mAlignment     = TEXTBOX_ALIGNMENT_CENTER;
            
            curButton->mTextPrice     = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
            [curButton->mTextPrice    SetVisible:TRUE];
            [curButton->mTextPrice    release];
            
            NSString* powerupPurchaseSelectorString = mIAPRowDefinitions[curProduct].PowerupPurchaseSelector;
            SEL powerupPurchaseSelector = NSSelectorFromString(powerupPurchaseSelectorString);
            
            tbParams.mString = (NSString*)[self performSelector:powerupPurchaseSelector withObject:productQuantityPair];
            tbParams.mFontSize = 15;
            tbParams.mHorizontalPadding = 4;
            
            curButton->mQuantityTextBox = [[TextBox alloc] InitWithParams:&tbParams];

            dispatch_async(dispatch_get_main_queue(), ^
            {
                while([[curButton GetUseTexture] GetStatus] != TEXTURE_STATUS_DECODING_COMPLETE)
                {
                    [NSThread sleepForTimeInterval:0.001f];
                }
                
                [curButton->mTextPrice  SetPositionX:(sPowerupButtonOffsets[i].mVector[x] + [curButton GetWidth] / 2.0)
                                                     Y:(sPowerupButtonOffsets[i].mVector[y] + (sPowerupRowHeight * curProduct) + 50)
                                                     Z:0.0];

                float buttonHeight = [curButton GetHeight];
                float textBoxHeight = [curButton->mQuantityTextBox GetHeight];
                
                [curButton->mQuantityTextBox    SetPositionX:(sPowerupButtonOffsets[i].mVector[x] + [curButton GetWidth] / 2.0)
                                                     Y:(sPowerupButtonOffsets[i].mVector[y] +
                                                        (buttonHeight - textBoxHeight) / 2.0 +
                                                        (sPowerupRowHeight * curProduct))
                                                     Z:0.0];
            } );
        }
        
        TextBoxParams tbParams;
        [TextBox InitDefaultParams:&tbParams];
        SetColorFromU32(&tbParams.mColor,          NEON_WHI);
        SetColorFromU32(&tbParams.mStrokeColor,    NEON_BLA);
        
        tbParams.mStrokeSize	= 2;
        
        SEL quantityStringSelector = NSSelectorFromString(mIAPRowDefinitions[curProduct].QuantityString);

        tbParams.mString        = [self performSelector:quantityStringSelector withObject:[NSNumber numberWithInt:curProduct]];
        tbParams.mFontSize		= mIAPRowDefinitions[curProduct].QuantityStringFontSize;
        tbParams.mFontType		= NEON_FONT_NORMAL;
        tbParams.mWidth         = 320;
        tbParams.mUIGroup		= mUIObjects;
        
        tbParams.mMutable       = TRUE;
        
        tbParams.mMaxWidth		= 420;
        tbParams.mMaxHeight		= 200;
        
        tbParams.mAlignment     = TEXTBOX_ALIGNMENT_LEFT;
        
        TextBox* curTextBox = NULL;;
        
        curTextBox   = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
        [curTextBox    SetVisible:TRUE];
        
        Vector2* positionOffset = &mIAPRowDefinitions[curProduct]->mQuantityStringPosition;
        [curTextBox    SetPositionX:positionOffset->mVector[x] Y:(curProduct * sPowerupRowHeight) + positionOffset->mVector[y] Z:0];
        [curTextBox    release];

        mIAPRows[curProduct]->mAmount = curTextBox;
        
        BOOL timedLevelsUnlocked = [levelDefinitions GetTimedLevelsUnlocked];
        
        tbParams.mFontSize = 12;
        tbParams.mWidth = 350;
        tbParams.mMaxWidth = 0;
        tbParams.mMaxHeight = 0;
        tbParams.mMutable = FALSE;
        tbParams.mStrokeSize = 10;
        tbParams.mAlignment = TEXTBOX_ALIGNMENT_LEFT;
        tbParams.mUIGroup		= mUIObjects;

        
        if (timedLevelsUnlocked)
        {
            tbParams.mString = NSLocalizedString(mIAPRowDefinitions[curProduct].DescriptionStringTimed, NULL);
        }
        else
        {
            tbParams.mString = NSLocalizedString(mIAPRowDefinitions[curProduct].DescriptionString, NULL);
        }
        
        curTextBox   = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
        [curTextBox    SetVisible:TRUE];
        [curTextBox    SetPositionX:100 Y:(curProduct * sPowerupRowHeight) + 5 Z:0];
        [curTextBox    release];

        mIAPRows[curProduct]->mDescription = curTextBox;
        
        // ---- Restore Button ----
        if (mIAPRowDefinitions[curProduct].HasRestoreButton)
        {
            NeonButtonParams	buttonParams;
            [NeonButton InitDefaultParams:&buttonParams ];
            
            buttonParams.mTexName					= sRestoreButtonFilename;
            buttonParams.mToggleTexName             = sRestoreButtonFilename;
            buttonParams.mPregeneratedGlowTexName	= (NSString*)sRestoreButtonGlowFilename;
            
            buttonParams.mText					= @"<B>Restore</B>";
            buttonParams.mTextSize				= 12;
            buttonParams.mFontType              = NEON_FONT_NORMAL;
            buttonParams.mBorderSize				= 4;
            buttonParams.mUIGroup                 = mUIObjects;
            buttonParams.mBoundingBoxCollision    = TRUE;
            SetColorFromU32(&buttonParams.mBorderColor	, NEON_BLA);
            SetColorFromU32(&buttonParams.mTextColor		, NEON_WHI);
            SetRelativePlacement(&buttonParams.mTextPlacement, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
            SetVec2(&buttonParams.mBoundingBoxBorderSize, 2, 2);
            
            IAPButton* curButton = NULL;
            curButton = (IAPButton*)[[IAPButton alloc] InitWithParams:&buttonParams ];
            [curButton SetVisible:TRUE];
            
            [curButton SetPositionX:10.0 Y:75 + (sPowerupRowHeight * curProduct) Z:0.0];
            [curButton SetListener:self];
            [curButton release];

            mIAPRows[curProduct]->mRestoreButton = curButton;
        }
    }
}

-(void)ActivateRowBackground:(int)inRowIndex
{
    LevelDefinitions* levelDefinitions = [[Flow GetInstance] GetLevelDefinitions];

    ImageWellParams imageWellParams;
    [ImageWell InitDefaultParams:&imageWellParams];
    
    imageWellParams.mUIGroup = mUIObjects;
    imageWellParams.mTextureName = (NSString*)sPowerupRowFileName;
    
    SEL productUnlockedSelector = NSSelectorFromString(mIAPRowDefinitions[inRowIndex].Unlocked);
    BOOL productLocked = !(BOOL)[levelDefinitions performSelector:productUnlockedSelector];
    
    SEL productUnlockLevel = NSSelectorFromString(mIAPRowDefinitions[inRowIndex].UnlockLevel);
    int unlockLevel = (int)[levelDefinitions performSelector:productUnlockLevel] + 1;
    
    if (productLocked)
    {
        imageWellParams.mTextureName = (NSString*)sPowerupLockedRowFileName;
    }
    
    ImageWell* curImageWell = [[ImageWell alloc] InitWithParams:&imageWellParams];
    [curImageWell SetVisible:FALSE];
    [curImageWell Enable];
    
    [curImageWell SetPositionX:0.0 Y:(inRowIndex * sPowerupRowHeight) Z:0.0];
    
    if (productLocked)
    {
        TextBoxParams tbParams;
        [TextBox InitDefaultParams:&tbParams];
        SetColorFromU32(&tbParams.mColor,          NEON_WHI);
        SetColorFromU32(&tbParams.mStrokeColor,    NEON_BLA);
        
        tbParams.mStrokeSize	= 8;
        tbParams.mString		= [NSString stringWithFormat:NSLocalizedString(@"LS_Store_Unlocked", NULL), unlockLevel];
        tbParams.mFontSize		= 32;
        tbParams.mFontType		= NEON_FONT_NORMAL;
        tbParams.mUIGroup		= mUIObjects;
        
        TextBox* textBox = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
        [textBox    SetVisible:TRUE];
        [textBox    SetPositionX:55 Y:((inRowIndex * sPowerupRowHeight) + 30) Z:0.0];
        [textBox    release];
    }
    else
    {
        imageWellParams.mTextureName = mIAPRowDefinitions[inRowIndex].OverlayFilename;
        
        curImageWell = [[ImageWell alloc] InitWithParams:&imageWellParams];
        [curImageWell SetVisible:FALSE];
        [curImageWell Enable];
        
        [curImageWell SetPositionX:0.0 Y:(inRowIndex * sPowerupRowHeight) Z:0.0];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0)
    {
        [self SetIAPStoreState:IAPSTORE_STATE_WAITING_TO_REQUEST];
        [[InAppPurchaseManager GetInstance] RestorePurchases];
        [self SetIAPStoreState:IAPSTORE_STATE_PURCHASING];
    }
}

-(void)RequestProduct:(IapProduct)inProduct
{
    [self SetIAPStoreState:IAPSTORE_STATE_WAITING_TO_REQUEST];
    
    [mIAPRows[0]->mDescription PerformAfterOperationsInQueue:dispatch_get_main_queue() block:^
        {
            [self SetIAPStoreState:IAPSTORE_STATE_PURCHASING];
            [[InAppPurchaseManager GetInstance] RequestProduct:inProduct];
        } ];
    
}

-(void)SetIAPStoreState:(IAPStoreState)inState
{
    switch(inState)
    {
        case IAPSTORE_STATE_WAITING_TO_REQUEST:
        {
            for (int curProduct = 0; curProduct < IAPSTORE_PRODUCT_NUM; curProduct++)
            {
                for (int i = 0; i < NUM_QUANTITIES_PER_IAP; i++)
                {
                    IAPButton* curButton = mIAPRows[curProduct]->mButtons[i];
                    
                    if (curButton != NULL)
                    {
                        [curButton Disable];
                        [curButton->mTextPrice Disable];
                        [curButton->mQuantityTextBox Disable];
                    }
                }
                
                [mIAPRows[curProduct]->mDescription Disable];
            }
            
            [mConnectingTextBox Enable];
            
            break;
        }
        
        case IAPSTORE_STATE_NORMAL:
        {
            [self EnableAllItems];
            
            [mConnectingTextBox Disable];
        }
    }
    
    mIAPStoreState = inState;
}

-(NSString*)GetPowerupQuantityDescription:(NSNumber*)inRow
{
    SEL getter = NSSelectorFromString(mIAPRowDefinitions[[inRow intValue]].QuantityAccessor);
    int quantity = (int)[[SaveSystem GetInstance] performSelector:getter];

    return [NSString stringWithFormat:NSLocalizedString(@"LS_Powerup_Quantity", NULL), quantity];
}

-(NSString*)GetRoomUnlockDescription:(NSNumber*)inRow
{
    NSString* roomDescription = [MainMenu GetRoomLockDescription];
    
    if (roomDescription != NULL)
    {
        int roomsRemaining = LEVELSELECT_ROOM_LAST - [[SaveSystem GetInstance] GetMaxRoomUnlocked];
        NSString* roomString = roomsRemaining > 1 ? @"rooms" : @"room";
        NSString* remainsString = roomsRemaining > 1 ? @"remain" : @"remains";
        
        return [NSString stringWithFormat:@"%@ (%d %@ %@)", [MainMenu GetRoomLockDescription], roomsRemaining, roomString, remainsString];
    }
    
    return NULL;
}

-(NSString*)GetQuantityPowerup:(NSArray*)inProductAndIndex
{
    int product = [[inProductAndIndex objectAtIndex:0] intValue];
    int index = [[inProductAndIndex objectAtIndex:1] intValue];
    
    IapProduct iapProductId = [mIAPRowDefinitions[product] GetProductForIndex:index];
    IAPInfo* iapInfo = [[InAppPurchaseManager GetInstance] GetIAPInfoWithIAP:iapProductId];
    int quantity = iapInfo->mAmount;

    return [NSString stringWithFormat:NSLocalizedString(@"LS_Powerup_Purchase", NULL), quantity, NSLocalizedString(mIAPRowDefinitions[product].PowerupName, NULL)];
}

-(NSString*)GetRoomUnlockString:(NSArray*)inProductAndIndex
{
    int product = [[inProductAndIndex objectAtIndex:0] intValue];
    int index = [[inProductAndIndex objectAtIndex:1] intValue];
    
    IapProduct iapProductId = [mIAPRowDefinitions[product] GetProductForIndex:index];

    NSString* retString = NULL;
    
    switch(iapProductId)
    {
        case IAP_PRODUCT_UNLOCK_NEXT:
        {
            retString = [NSString stringWithFormat:@"Unlock Now!"];
            break;
        }
        
        case IAP_PRODUCT_UNLOCK_ALL:
        {
            retString = [NSString stringWithFormat:@"<B>Unlock All!!!</B>"];
            break;
        }
    }
    
    return retString;
}

-(BOOL)GetRoomUnlockButtonActive:(NSArray*)inProductAndIndex
{
    int product = [[inProductAndIndex objectAtIndex:0] intValue];
    int index = [[inProductAndIndex objectAtIndex:1] intValue];
    
    IapProduct iapProductId = [mIAPRowDefinitions[product] GetProductForIndex:index];
    
    if (iapProductId == IAP_PRODUCT_UNLOCK_NEXT)
    {
        if ([[SaveSystem GetInstance] GetMaxRoomUnlocked] >= LEVELSELECT_ROOM_LAST)
        {
            return FALSE;
        }
    }
    else if (iapProductId == IAP_PRODUCT_UNLOCK_ALL)
    {
        if ([[SaveSystem GetInstance] GetMaxRoomUnlocked] >= (LEVELSELECT_ROOM_LAST - 1))
        {
            return FALSE;
        }
    }
    
    return TRUE;
}

-(BOOL)EvaluateButtonActiveForProduct:(int)inProduct index:(int)inIndex
{
    BOOL buttonActive = TRUE;
    
    if (mIAPRowDefinitions[inProduct].ActiveSelector != NULL)
    {
        NSArray* productQuantityPair = [NSArray arrayWithObjects:[NSNumber numberWithInt:inProduct], [NSNumber numberWithInt:inIndex], NULL];
        buttonActive = (BOOL)[self performSelector:NSSelectorFromString(mIAPRowDefinitions[inProduct].ActiveSelector) withObject:productQuantityPair];
    }
    
    return buttonActive;
}

-(void)EnableAllItems
{
    for (int product = 0; product < IAPSTORE_PRODUCT_NUM; product++)
    {
        for (int i = 0; i < NUM_QUANTITIES_PER_IAP; i++)
        {
            IAPButton* curButton = mIAPRows[product]->mButtons[i];
            
            if (curButton != NULL)
            {
                BOOL active = [self EvaluateButtonActiveForProduct:product index:i];

                if (active)
                {
                    [curButton Enable];
                    [curButton->mTextPrice Enable];
                    [curButton->mQuantityTextBox Enable];
                }
                else
                {
                    [curButton SetVisible:TRUE];
                    [curButton->mTextPrice SetVisible:TRUE];
                    [curButton->mQuantityTextBox SetVisible:TRUE];
                    [curButton SetActive:FALSE];
                }
            }
        }
        
        [mIAPRows[product]->mDescription Enable];
    }
}

@end
