//
//  IAPStore.h
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

#import "GameState.h"
#import "Button.h"
#import "UIGroup.h"
#import "GameStateMgr.h"
#import "GlobalUI.h"
#import "InAppPurchaseManager.h"

#define NUM_QUANTITIES_PER_IAP 3

typedef enum
{
    IAPSTORE_STATE_NORMAL,
    IAPSTORE_STATE_PURCHASING,
    IAPSTORE_STATE_WAITING_TO_REQUEST
} IAPStoreState;

typedef enum
{
    IAPSTORE_PRODUCT_XRAY,
    IAPSTORE_PRODUCT_TORNADOES,
    IAPSTORE_PRODUCT_POWERUP_LAST = IAPSTORE_PRODUCT_TORNADOES,
    IAPSTORE_PRODUCT_NUM,
} IAPStoreProduct;

typedef enum
{
    IAPSTORE_MODE_NORMAL,
    IAPSTORE_MODE_POWERUP
} IAPStoreMode;

// I need this subclass to prevent the buttons from automatically switching to toggle off
@interface IAPButton : NeonButton
{
    @public
        TextBox* mTextPrice;
        TextBox* mQuantityTextBox;
}

-(void)SetActive:(BOOL)inActive;
-(void)DispatchEvent:(ButtonEvent)inEvent;

@end

@interface IAPStoreParams : NSObject
{
}

@property(retain) NSString* MessageString;
@property IAPStoreMode StoreMode;

-(IAPStoreParams*)init;
-(void)dealloc;

@end

@interface IAPRow : NSObject
{
    @public
        ImageWell*      mBackground;
        IAPButton*      mButtons[NUM_QUANTITIES_PER_IAP];
        TextBox*        mAmount;
        TextBox*        mDescription;
        TextBox*        mQuantities[NUM_QUANTITIES_PER_IAP];
        IAPButton*      mRestoreButton;
}

-(IAPRow*)init;
-(void)dealloc;

@end

@class NeonSpinner;
@class PowerupInfo;
@class StringCloud;

@interface IAPStore : GameState <ButtonListenerProtocol, UIAlertViewDelegate>
{
    @protected
        //Stuff that all menus should have
        NSString*       mBackground;
        UIGroup*        mUIObjects;
        NeonButton*     mBackButton;

    @private
        PowerupInfo*    mIAPRowDefinitions[IAPSTORE_PRODUCT_NUM];
        IAPRow*         mIAPRows[IAPSTORE_PRODUCT_NUM];
        
        IAPStoreState   mIAPStoreState;
    
        TextBox*        mConnectingTextBox;
        TextBox*        mMessageTextBox;
    
        ImageWell*      mLogoImage;
        int             mFrameDelay;
    
        int             mYOffset;
    
        BOOL            mUIEnabled;
        NeonSpinner*    mSpinner;
    
        StringCloud*    mRemoveAds;
}

-(IAPStore*)Init;
-(void)dealloc;

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

-(void)LeaveMenu;

-(void)ActivateConsumablesTab;

//menu-wide
-(void)ActivateBackButton;
-(void)ActivateStatus;
-(void)ActivateMessage;

//powerups
-(void)ActivatePowerups;
-(void)ActivateRowBackground:(int)inRowIndex;

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

-(void)RequestProduct:(IapProduct)inProduct;
-(void)SetIAPStoreState:(IAPStoreState)inState;

-(NSString*)GetPowerupQuantityDescription:(NSNumber*)inRow;
-(NSString*)GetRoomUnlockDescription:(NSNumber*)inRow;

-(NSString*)GetQuantityPowerup:(NSArray*)inProductAndIndex;
-(NSString*)GetRoomUnlockString:(NSArray*)inProductAndIndex;

-(BOOL)GetRoomUnlockButtonActive:(NSArray*)inProductAndIndex;
-(BOOL)EvaluateButtonActiveForProduct:(int)inProduct index:(int)inIndex;

-(void)EnableAllItems;

@end
