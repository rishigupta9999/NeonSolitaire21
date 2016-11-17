//
//  InAppPurchaseManager.m
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

#import "InAppPurchaseManager.h"
#import "GameStateMgr.h"
#import "Flow.h"
#import "SaveSystem.h"
#import "RegenerationManager.h"
#import "GameRun21.h"
#import <Parse/Parse.h>

#define GAME_ORIENTATION                UIInterfaceOrientationLandscapeRight
#define DEBUG_DUMP_INVALID_PRODUCTS     1

static InAppPurchaseManager* sInstance = NULL;

static IAPInfo sIAPInfo[IAP_PRODUCT_NUM] = {
    {   @"UnlockRoom.All",  @"GetMaxRoomUnlocked",  @"SetMaxRoomUnlocked:", IAP_OPERATOR_SET,   LEVELSELECT_ROOM_NUM    },
#if USE_TORNADOES
    {   @"Tornado1.Bronze",  @"GetNumTornadoes",    @"SetNumTornadoes:",    IAP_OPERATOR_ADD,   5,                      },
    {   @"Tornado1.Silver",  @"GetNumTornadoes",    @"SetNumTornadoes:",    IAP_OPERATOR_ADD,   25,                     },
    {   @"Tornado1.Gold",    @"GetNumTornadoes",    @"SetNumTornadoes:",    IAP_OPERATOR_ADD,   100,                    },
#endif
    {   @"Xray.Bronze",     @"GetNumXrays",         @"SetNumXrays:",        IAP_OPERATOR_ADD,   10,                     },
    {   @"Xray.Silver",     @"GetNumXrays",         @"SetNumXrays:",        IAP_OPERATOR_ADD,   50,                     },
    {   @"Xray.Gold",       @"GetNumXrays",         @"SetNumXrays:",        IAP_OPERATOR_ADD,   200                     },
    {   @"UnlockRoom.Next", @"GetMaxRoomUnlocked",  @"SetMaxRoomUnlocked:", IAP_OPERATOR_ADD,   1                       },
#if USE_LIVES
    {   @"RefillLives",     @"GetNumLives",         @"SetNumLives:",        IAP_OPERATOR_SET,   STARTUP_POWERUP_LIVES   },
#endif
};

@implementation PaymentQueueObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *) transactions
{
    InAppPurchaseManager *purchaseManager = [InAppPurchaseManager GetInstance];
    
    
    //Go through all of the updated transactions one at a time and see how each was updated
    for (SKPaymentTransaction *transaction in transactions)
    {
        NSString *productId;
        
        // handle the transaction based on the state of the transaction
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:            //The App Store successfully processed payment.
            {
                productId           = transaction.payment.productIdentifier;
                SKProduct* product  = [purchaseManager GetProductForID:productId];
                
                [[NeonMetrics GetInstance] logEvent:@"IAP Transaction Success" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                    productId                                               ,@"IAP Product ID"   ,
                    [product.priceLocale objectForKey: NSLocaleCountryCode] ,@"IAP Country ID"   ,
                    product.price                                           ,@"IAP Price"        , nil]];
                
                [purchaseManager performSelectorOnMainThread:@selector(DeliverContent:) withObject:productId waitUntilDone:FALSE];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                purchaseManager->mIapState = IAP_STATE_IDLE;

                break;
            }
            case SKPaymentTransactionStateRestored:             //This transaction restores content previously purchased by the user.
            {
                productId           = transaction.originalTransaction.payment.productIdentifier;
                SKProduct* product  = [purchaseManager GetProductForID:productId];
                
                [[NeonMetrics GetInstance] logEvent:@"IAP Transaction Restore" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                    productId                                               ,@"IAP Product ID"   ,
                    [product.priceLocale objectForKey: NSLocaleCountryCode] ,@"IAP Country ID"   , nil]];
                
                
                [purchaseManager performSelectorOnMainThread:@selector(DeliverContent:) withObject:productId waitUntilDone:FALSE];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
               
                
                purchaseManager->mIapState = IAP_STATE_IDLE;

                break;
            }
            case SKPaymentTransactionStateFailed:               //The transaction failed. Check the error property to determine what happened.
            {
                productId               = transaction.payment.productIdentifier;
                SKProduct* product      = [purchaseManager GetProductForID:productId];
                NSString* flurryLabel;
                
                if ( transaction.error.code == SKErrorPaymentCancelled )
                {
                    flurryLabel = @"IAP Transaction Canceled";
                }
                else
                {
                    flurryLabel = @"IAP Transaction Failed";
                    [purchaseManager NotifyUserOfError:transaction.error];
                }
                
                [[NeonMetrics GetInstance] logEvent:flurryLabel withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                             productId                                               ,@"IAP Product ID"   ,
                                             [product.priceLocale objectForKey: NSLocaleCountryCode] ,@"IAP Country ID"   ,
                                             transaction.error                                       ,@"IAP Error"        , nil]];
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                purchaseManager->mIapState = IAP_STATE_IDLE;

                break;
            }
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads
{
    NSAssert(FALSE, @"We don't host our product with apple right now, we shouldn't be getting updatedDownloads");
}

@end

@implementation InAppPurchaseManager

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create InAppPurchaseManager");
    sInstance = [(InAppPurchaseManager*)[InAppPurchaseManager alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to delete InAppPurchaseManager when one doesn't exist");
    [sInstance release];
}

+(InAppPurchaseManager*) GetInstance
{
    return sInstance;
}

-(InAppPurchaseManager*)Init
{
    // Prepend product IDs with the bundle identifier
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* identifier = [mainBundle bundleIdentifier];
    
    for (int i = 0; i < IAP_PRODUCT_NUM; i++)
    {
        sIAPInfo[i].mProductId = [NSString stringWithFormat:@"%@.%@", identifier, sIAPInfo[i].mProductId];
    }

    mPaymentObserver = [[PaymentQueueObserver alloc] init];
    mDelegatePurchaseProduct = [[PurchaseProductDelegate alloc] init];
    mDelegateRepopulateProducts = [[RepopulateProductsDictionaryDelegate alloc] init];
        
    mCurrentProduct = NULL;
        
    for (int i = 0; i < IAP_PRODUCT_NON_CONSUMABLE_NUM; i++)
    {
        SEL getter = NSSelectorFromString(sIAPInfo[i].mGetter);
        mNonConsumablePurchases[i] = (BOOL)[[SaveSystem GetInstance] performSelector:getter];
    }
    
    mProductSet = [[NSMutableSet alloc] initWithCapacity:IAP_PRODUCT_NUM];
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:mPaymentObserver];
    
    // Get the products from the App Store
    [self RequestAllProducts];
    
    mIapState = IAP_STATE_IDLE;
    
    mNumberFormatter = [[NSNumberFormatter alloc] init];
    
    return self;
}

-(void)dealloc
{
    mCurrentProduct = NULL;     //This refernces inside the mProducts dictionary, so it will be released when mProducts is released
    [mProducts release];
    [mProductSet release];
    
    [mDelegatePurchaseProduct release];
    [mDelegateRepopulateProducts release];
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:mPaymentObserver];
    [mPaymentObserver release];
    [mNumberFormatter release];
    
    [super dealloc];
}

-(BOOL)RequestProduct:(IapProduct)inProduct
{
    if (mIapState == IAP_STATE_PENDING)
    {
        return FALSE;
    }
    
    if(![SKPaymentQueue canMakePayments])
    {
        //The user cannot make In App Purchases. Create an alert telling them so.
        [UIApplication sharedApplication].statusBarOrientation = GAME_ORIENTATION;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LS_IAP_ERROR_PAYMENTNOTALLOWED", NULL) message:NULL delegate:NULL cancelButtonTitle:NSLocalizedString(@"LS_OK",NULL) otherButtonTitles:nil];
        [alert show];
        return FALSE;
    }
    
    NSAssert(mCurrentProduct == NULL, @"Current product wasn't cleared out before");
    
    mCurrentProduct = [mProducts objectForKey:sIAPInfo[inProduct].mProductId];
    
    // We can't process a non-exsistant product. If we can't find the product, maybe the user couldn't connect to the internet on startup, try to get the list of products again
    if (mCurrentProduct == nil)
    {
        NSLog(@"Invalid product with ID: %d, Products Available: %d :: Repopulating products dictionary on user tap.", inProduct, [mProducts count]);

        // Put up Alert: In-App Purchases could not be found?  Retry
        [UIApplication sharedApplication].statusBarOrientation = GAME_ORIENTATION;

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"LS_IAP_ERROR_TITLE", NULL)
                                                        message: NSLocalizedString(@"LS_IAP_ERROR_RECHECKFORPRODUCTS",NULL)
                                                       delegate: mDelegateRepopulateProducts
                                              cancelButtonTitle: NSLocalizedString(@"LS_OK", NULL)
                                              otherButtonTitles: nil,
                              nil];
        
        [alert show];
        
        // Product is not accessible, terminate execution early.
        return FALSE;
    }

    [UIApplication sharedApplication].statusBarOrientation = GAME_ORIENTATION;
    
    // KK, Don't prompt the user before the App Store prompts them.
    // In the future, we'll allow for restoring of non-consumables.
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(promptForConfimation, NULL)
                                                    message: mCurrentProduct.localizedDescription
                                                   delegate: mDelegatePurchaseProduct
                                          cancelButtonTitle: NSLocalizedString(@"LS_No", NULL)
                                          otherButtonTitles: NSLocalizedString(@"LS_Yes", NULL),
                                                             //NSLocalizedString(@"LS_Restore",NULL), //@FB:Restore - restores all purchases

                                                             nil];
    
    [alert show];*/
    
    SKPaymentQueue *defQueue        = [SKPaymentQueue defaultQueue];
    InAppPurchaseManager* appMan    = [InAppPurchaseManager GetInstance];
    [[NeonMetrics GetInstance] logEvent:@"IAP Transaction Request" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                             appMan->mCurrentProduct.productIdentifier                               , @"IAP Product ID"   ,
                                             [appMan->mCurrentProduct.priceLocale objectForKey: NSLocaleCountryCode] , @"IAP Country ID"   ,
                                             nil]];
    appMan->mIapState = IAP_STATE_PENDING;
    [defQueue addPayment:[SKPayment paymentWithProduct: appMan->mCurrentProduct]];
    appMan->mCurrentProduct = NULL;
    
    return TRUE;
}

-(void)RequestAllProducts
{
    SKProductsRequest* requestForProducts;  // This is the request for the products that we send to the iTunes Store
    
    [mProductSet removeAllObjects];
    
    // Only make the request if the user can make purchases
    if([SKPaymentQueue canMakePayments])
    {
        // populate the set with all of the product identifiers
        for (int i = 0; i < IAP_PRODUCT_NUM; i++)
        {
            [mProductSet addObject:sIAPInfo[i].mProductId];
        }
        
        requestForProducts = [[SKProductsRequest alloc] initWithProductIdentifiers:mProductSet];
        
        if (requestForProducts != NULL)
        {
            requestForProducts.delegate = self;
            [requestForProducts start];
        }
    }
}

-(void)RestorePurchases
{
    mIapState = IAP_STATE_PENDING;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)inResponse
{
    NSMutableArray *productIds, *products;
    
    //Create arrays for the dictionary
    productIds = [[NSMutableArray alloc] initWithCapacity:IAP_PRODUCT_NUM];
    products = [[NSMutableArray alloc] initWithCapacity:IAP_PRODUCT_NUM];
    
    for (SKProduct* product in inResponse.products)
    {
        [productIds addObject:product.productIdentifier];
        [products addObject:product];
    }
    
    //release the old dictionary
    [mProducts release];
    mProducts = [NSDictionary dictionaryWithObjects:products forKeys:productIds];
    [mProducts retain];
    
    [productIds release];
    [products release];
    
#if DEBUG_DUMP_INVALID_PRODUCTS
    for (NSString *invalidProductString in inResponse.invalidProductIdentifiers)
    {
        NSLog(@"Invalid Product: %@",invalidProductString);
    }
#endif
        
    [request release];
}

-(void)DeliverContent:(NSString*)inProductIdentifier
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"This should only be called on the main thread");
    
    SKProduct*  product = [mProducts objectForKey:inProductIdentifier];
    NSString*   resultString = NSLocalizedString(@"LS_ERROR",NULL);              //if we can't find a product associated with the identifier, notify the user of an error
    
    for (int i = 0; i < IAP_PRODUCT_NUM; i++)
    {
        //if the product identifier is the ith product, then enable the content
        if ([sIAPInfo[i].mProductId isEqualToString:inProductIdentifier])
        {
            SEL getter = NSSelectorFromString(sIAPInfo[i].mGetter);
            SEL setter = NSSelectorFromString(sIAPInfo[i].mSetter);
            
            int numItems = (int)[[SaveSystem GetInstance] performSelector:getter];
            
            switch(sIAPInfo[i].mOperator)
            {
                case IAP_OPERATOR_ADD:
                {
                    numItems += sIAPInfo[i].mAmount;
                    break;
                }
                
                case IAP_OPERATOR_SET:
                {
                    numItems = sIAPInfo[i].mAmount;
                    break;
                }
                
                default:
                {
                    NSAssert(FALSE, @"Unknown operator");
                    break;
                }
            }
                            
            [[SaveSystem GetInstance] performSelector:setter withObject:[NSNumber numberWithInt:numItems]];
            
            double purchaseAmount = [[SaveSystem GetInstance] GetPurchaseAmount];
            purchaseAmount += [product.price doubleValue];
            
            [[SaveSystem GetInstance] SetPurchaseAmount:purchaseAmount];
            
            NSString* currencyString = [[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode];
            [[SaveSystem GetInstance] SetCurrencyCode:currencyString];

            numItems = [[SaveSystem GetInstance] GetNumPurchasesForIAP:i];
            numItems++;
            
            [[SaveSystem GetInstance] SetNumPurchasesForIAP:i numPurchases:numItems];
            
            resultString = [NSString stringWithFormat:NSLocalizedString(@"LS_IAP_SUCCESS",NULL) , product.localizedTitle];
            break;
        }
    }
    
    // Tell the user that we have succesfully activated the requested content or failed
    [UIApplication sharedApplication].statusBarOrientation = GAME_ORIENTATION;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:resultString message:NULL delegate:NULL cancelButtonTitle:NSLocalizedString(@"LS_OK",NULL) otherButtonTitles:nil];
    [alert show];
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_IAP_DELIVER_CONTENT withData:inProductIdentifier];
}

-(void)NotifyUserOfError:(NSError*)inError
{
    NSString* errorString;
    switch (inError.code)
    {
    
        case SKErrorPaymentCancelled:
            //the user knows that they cancelled the payment, early return
            return;
        case SKErrorClientInvalid:
            errorString = NSLocalizedString(@"LS_IAP_ERROR_CLIENTINVALID", NULL);
            break;
        case SKErrorPaymentInvalid:
            errorString = NSLocalizedString(@"LS_IAP_ERROR_PAYMENTINVALID", NULL);
            break;
        case SKErrorPaymentNotAllowed:
            errorString = NSLocalizedString(@"LS_IAP_ERROR_PAYMENTNOTALLOWED", NULL);
            break;
        case SKErrorStoreProductNotAvailable:
            errorString = NSLocalizedString(@"LS_IAP_ERROR_PRODUCTNOTAVAILABLE", NULL);
            break;
        case SKErrorUnknown:
            errorString = [inError localizedDescription];
            if(errorString == nil)
            {
                errorString = NSLocalizedString(@"LS_IAP_ERROR_UNKNOWN",NULL);
            }
            break;
        default:
            NSAssert(FALSE,@"%@",inError.domain);
            errorString = NSLocalizedString(@"LS_ERROR",NULL);
            break;
            
    }
    
    [UIApplication sharedApplication].statusBarOrientation = GAME_ORIENTATION;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LS_IAP_ERROR_TITLE",NULL) message:errorString delegate:NULL cancelButtonTitle:NSLocalizedString(@"LS_OK",NULL) otherButtonTitles:nil];
    [alert show];
}


-(BOOL)HasContent:(IapProduct)inProduct
{
    #if !NEON_FREE_VERSION
        if ( inProduct == IAP_PRODUCT_NOADS )
            return TRUE;
    #endif
    
    #if ADVERTISING_FORCE
        return FALSE;
    #endif
    
    NSAssert(inProduct >= IAP_PRODUCT_NON_CONSUMABLE_FIRST && inProduct < IAP_PRODUCT_NON_CONSUMABLE_NUM, @"Product out of range");
    
    return mNonConsumablePurchases[inProduct];
}

-(SKProduct*)GetProductForID:(NSString*)inId
{
    return [mProducts objectForKey:inId];
}

-(SKProduct*)GetProduct:(IapProduct)inProduct
{
    return [mProducts objectForKey:sIAPInfo[inProduct].mProductId];
}

-(NSString*)GetLocalizedPrice:(SKProduct*)inProduct
{
    [mNumberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [mNumberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [mNumberFormatter setLocale:inProduct.priceLocale];
    
    return [mNumberFormatter stringFromNumber:inProduct.price];
}

-(BOOL)IsConsumable:(IapProduct)inProduct
{
    BOOL retVal = TRUE;
    
    if ((inProduct >= IAP_PRODUCT_NON_CONSUMABLE_FIRST) && (inProduct < IAP_PRODUCT_NON_CONSUMABLE_NUM))
    {
        retVal = FALSE;
    }
    
    return retVal;
}

-(IAPInfo*)GetIAPInfoWithIAP:(IapProduct)inProduct
{
    return &sIAPInfo[inProduct];
}

-(IapProduct)GetIAPWithIdentifier:(NSString*)inIdentifier
{
    for (int i = 0; i < IAP_PRODUCT_NUM; i++)
    {
        if ([sIAPInfo[i].mProductId isEqualToString:inIdentifier])
        {
            return i;
        }
    }
    
    return IAP_PRODUCT_INVALID;
}

-(IapState)GetIAPState
{
    return mIapState;
}

@end

@implementation PurchaseProductDelegate
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    SKPaymentQueue *defQueue = [SKPaymentQueue defaultQueue];
    InAppPurchaseManager* appMan = [InAppPurchaseManager GetInstance];
    
    if([title isEqualToString:NSLocalizedString(@"LS_Yes", NULL)])
    {
        appMan->mIapState = IAP_STATE_PENDING;
        [defQueue addPayment:[SKPayment paymentWithProduct: appMan->mCurrentProduct]];
    }
    else if([title isEqualToString:NSLocalizedString(@"LS_Restore",NULL)])
    {
        [defQueue restoreCompletedTransactions];        //@FB:Restore - restores all purchases
    }
    else if([title isEqualToString:NSLocalizedString(@"LS_No",NULL)])
    {
    }
    
    appMan->mCurrentProduct = NULL;
}

@end

@implementation RepopulateProductsDictionaryDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    InAppPurchaseManager* appMan = [InAppPurchaseManager GetInstance];
    
    if ([title isEqualToString:NSLocalizedString(@"LS_OK",NULL)])
    {
        [appMan RequestAllProducts];
    }
}

@end


