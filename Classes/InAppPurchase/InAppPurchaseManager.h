//
//  InAppPurchaseManager.h
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef enum
{
    IAP_OPERATOR_ADD,
    IAP_OPERATOR_SET
} IAPOperator;

typedef struct
{
    NSString*   mProductId;
    NSString*   mGetter;
    NSString*   mSetter;
    IAPOperator mOperator;
    u32         mAmount;
} IAPInfo;

typedef enum
{
    IAP_PRODUCT_NON_CONSUMABLE_FIRST,
    IAP_PRODUCT_UNLOCK_ALL = IAP_PRODUCT_NON_CONSUMABLE_FIRST,
    IAP_PRODUCT_NON_CONSUMABLE_NUM,
    IAP_PRODUCT_CONSUMABLE_FIRST = IAP_PRODUCT_NON_CONSUMABLE_NUM,
    IAP_PRODUCT_TORNADO_BRONZE = IAP_PRODUCT_CONSUMABLE_FIRST,
    IAP_PRODUCT_TORNADO_SILVER,
    IAP_PRODUCT_TORNADO_GOLD,
    IAP_PRODUCT_XRAY_BRONZE,
    IAP_PRODUCT_XRAY_SILVER,
    IAP_PRODUCT_XRAY_GOLD,
    IAP_PRODUCT_UNLOCK_NEXT,
    IAP_PRODUCT_CONSUMABLE_LAST = IAP_PRODUCT_UNLOCK_NEXT,
    IAP_PRODUCT_CONSUMABLE_NUM = IAP_PRODUCT_CONSUMABLE_LAST - IAP_PRODUCT_CONSUMABLE_FIRST + 1,
    IAP_PRODUCT_NUM,
    IAP_PRODUCT_INVALID = IAP_PRODUCT_NUM                                                                                                                    
} IapProduct;

typedef enum
{
    IAP_STATE_IDLE,
    IAP_STATE_PENDING
} IapState;

@interface PaymentQueueObserver : NSObject <SKPaymentTransactionObserver>

@end

@interface PurchaseProductDelegate : NSObject <UIAlertViewDelegate>

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface RepopulateProductsDictionaryDelegate : NSObject <UIAlertViewDelegate>

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface InAppPurchaseManager : NSObject <SKProductsRequestDelegate>
{
    @public
        SKProduct*              mCurrentProduct;
        IapState                mIapState;

    @private
        PurchaseProductDelegate*                mDelegatePurchaseProduct;
        RepopulateProductsDictionaryDelegate*   mDelegateRepopulateProducts;
        NSDictionary*                           mProducts;
        PaymentQueueObserver*                   mPaymentObserver;
        BOOL                                    mNonConsumablePurchases[IAP_PRODUCT_NUM];
    
        NSMutableSet*                           mProductSet;
        NSNumberFormatter*                      mNumberFormatter;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(InAppPurchaseManager*)GetInstance;
-(InAppPurchaseManager*)Init;
-(void)dealloc;

-(BOOL)RequestProduct:(IapProduct)inProduct;
-(void)RequestAllProducts;
-(void)RestorePurchases;

-(void)DeliverContent:(NSString*)inProductIdentifier;
-(void)NotifyUserOfError:(NSError*)inError;
-(BOOL)HasContent:(IapProduct)inProduct;

-(SKProduct*)GetProductForID:(NSString*)inId;
-(SKProduct*)GetProduct:(IapProduct)inProduct;
-(NSString*)GetLocalizedPrice:(SKProduct*)inProduct;

-(BOOL)IsConsumable:(IapProduct)inProduct;

-(IAPInfo*)GetIAPInfoWithIAP:(IapProduct)inProduct;
-(IapProduct)GetIAPWithIdentifier:(NSString*)inIdentifier;

-(IapState)GetIAPState;

@end


