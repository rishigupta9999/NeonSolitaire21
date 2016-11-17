//
//  RegenerationManager.m
//  Neon21
//
//  (c) 2013, Neon Games LLC
//

#import "RegenerationManager.h"
#import "SaveSystem.h"
#import "GameRun21.h"
#import "GameStateMgr.h"
#import "SplitTestingSystem.h"

static RegenerationManager* sInstance = NULL;

@implementation RegenerationManager

-(RegenerationManager*)Init
{
    mRoomUnlockState = ROOM_UNLOCK_STATE_IDLE;
    
    if ([[SaveSystem GetInstance] GetRoomUnlockTimestamp] > 0)
    {
        mRoomUnlockState = ROOM_UNLOCK_STATE_COUNTDOWN;
    }
    
    [self EvaluateBadge];
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create RegenerationManager");
    sInstance = [(RegenerationManager*)[RegenerationManager alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to delete RegenerationManager when it is already destroyed");
    [sInstance release];
}

+(RegenerationManager*)GetInstance
{
    return sInstance;
}

-(void)ProcessMessage:(Message*)inMsg
{
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [self UpdateHealthRegen];
    [self UpdateRoomUnlock];
}

-(void)UpdateHealthRegen
{
    SaveSystem *neonSave    = [ SaveSystem GetInstance ];
    
    // If we're at full health, we don't need to regenerate.
    if ( [neonSave GetNumLives] >= [ self GetMaxLives] )
        return;
    
    NSTimeInterval now      = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval then     = [neonSave GetLifeLostTimestamp];
    
    NSAssert(now >= then, @"Error, UpdateHealthRegen has calculated a negative time untill life regeneration");
    
    double numSecondsPassed = fabs(now - then);
    int regenInterval       = [self GetHealthRegenRate];
    int numLivesRegened     = numSecondsPassed / regenInterval;
    
    if ( numLivesRegened )
        [self SetNumLives_Regen:numLivesRegened];
}

-(int)GetHealthRegenRate
{
    int ret = SECONDS_UNTIL_NEXT_LIVE_UNREGISTERED;
    RegistrationLevel regLevel = [[ SaveSystem GetInstance ] GetRegisteredUser];
    
    switch ( regLevel )
    {
        case USER_REGISTERED_LOGGED_IN:
            ret = SECONDS_UNTIL_NEXT_LIVE_REGISTERED;
            break;
            
        case USER_GUEST:
        case USER_REGISTERED_LOGGED_OUT:
            ret = SECONDS_UNTIL_NEXT_LIVE_UNREGISTERED;
            break;
            
        default:
            NSAssert1(FALSE, @"GetHealthRegenRate unknown registration level! :: regLevel = %d", regLevel);
            break;
    }
     
    #if IAP_DEVELOPER_MODE
        ret = SECONDS_UNTIL_NEXT_LIVE_DEVELOPER;
    #endif
    
    return ret;
}

-(NSString*)GetHealthRegenTimeString
{
    NSString *retStr;
    SaveSystem *neonSave    = [ SaveSystem GetInstance ];
    
    if ( [neonSave GetNumLives] >= [ self GetMaxLives] )
    {
        retStr = @"FULL";
    }
    else
    {
        NSTimeInterval now      = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval then     = [neonSave GetLifeLostTimestamp];
        double numSecondsPassed = fabs(now - then);
        int regenInterval       = [[RegenerationManager GetInstance] GetHealthRegenRate];
        int timeUntilNextLife   = regenInterval - numSecondsPassed;
        retStr                  = [NSString stringWithFormat:@"%02d:%02d",
                                   timeUntilNextLife / 60,
                                   timeUntilNextLife % 60 ];
    }
    
    return retStr;
}

-(void)SetNumLives_Full
{
    [ [ SaveSystem GetInstance ] SetNumLives:[NSNumber numberWithInt:STARTUP_POWERUP_LIVES]];
}

-(void)SetNumLives_LevelStart
{
    SaveSystem *neonSave    = [ SaveSystem GetInstance ];
    int numLives            = [neonSave GetNumLives];
    
    // If we're at full lives, we need to start the lifelost timestamp, otherwise we don't want to lose progress on life regen.
    if ( [self GetMaxLives] == numLives )
    {
        [neonSave SetLifeLostTimestamp];
    }
    else if ( 0 >= numLives )
    {
        //NSAssert1(FALSE, @"Level Started without a positive amount of lives! :: numLives = %d", numLives);
        numLives = 1;
        [neonSave SetLifeLostTimestamp];
    }
    
    // Deduct a life and timestamp it for regeneration purposes.
    numLives--;
    
    [ neonSave SetNumLives:[NSNumber numberWithInt:numLives]];
}

-(void)SetNumLives_LevelWin;
{
    SaveSystem *neonSave    = [ SaveSystem GetInstance ];
    
    [ neonSave SetNumLives:[NSNumber numberWithInt:[neonSave GetNumLives] + 1]];
}

-(void)SetNumLives_Regen:(int)livesRegened
{
    NSAssert(livesRegened > 0 , @"SetNumLives_Regen called without positive lives to regenerate");
    
    SaveSystem *neonSave    = [ SaveSystem GetInstance ];
    int numLives            = [neonSave GetNumLives] + livesRegened;
    
    if ( numLives >= [ self GetMaxLives] )
    {
        numLives = [ self GetMaxLives];
    }
    
    [ neonSave SetNumLives:[NSNumber numberWithInt:numLives]];
    [neonSave SetLifeLostTimestamp];
    
}

-(int)GetMaxLives
{
    return STARTUP_POWERUP_LIVES;
}

-(void)UpdateRoomUnlock
{
    if ([[SaveSystem GetInstance] GetRoomUnlockTimestamp] == 0)
    {
        return;
    }
    
    if ([self GetRoomUnlockTimeRemaining] < 0)
    {
        LevelSelectRoom maxRoom = [[SaveSystem GetInstance] GetMaxRoomUnlocked];
        [[SaveSystem GetInstance] SetMaxRoomUnlocked:[NSNumber numberWithInt:(maxRoom + 1)]];
        
        NSString* identifier = [[InAppPurchaseManager GetInstance] GetIAPInfoWithIAP:IAP_PRODUCT_UNLOCK_NEXT]->mProductId;
        [[GameStateMgr GetInstance] SendEvent:EVENT_IAP_DELIVER_CONTENT withData:identifier];
        
        UIAlertView* alertView = [[UIAlertView alloc]   initWithTitle:NULL
                                                        message:NSLocalizedString(@"LS_Unlock_Room_Complete", NULL)
                                                        delegate:NULL
                                                        cancelButtonTitle:NSLocalizedString(@"LS_OK", NULL)
                                                        otherButtonTitles:NULL];
        [alertView show];
        [alertView release];
        
        [self EvaluateBadge];
    }
}

-(CFTimeInterval)GetRoomUnlockTimeRemaining
{
    CFTimeInterval startTime = [[SaveSystem GetInstance] GetRoomUnlockTimestamp];
    CFTimeInterval curTime = [[NSDate date] timeIntervalSince1970];
    CFTimeInterval elapsedTime = curTime - startTime;
    
    return [self GetRoomUnlockSeconds] - (int)elapsedTime;
}

-(void)SetRoomUnlockState:(RoomUnlockState)inRoomUnlockState
{
    if (mRoomUnlockState != inRoomUnlockState)
    {
        mRoomUnlockState = inRoomUnlockState;
        
        switch(mRoomUnlockState)
        {
            case ROOM_UNLOCK_STATE_COUNTDOWN:
            {
                [[SaveSystem GetInstance] SetRoomUnlockTimestamp];
                
                UILocalNotification* localNotification = [[UILocalNotification alloc] init];

                CFTimeInterval duration = [self GetRoomUnlockSeconds];
                
                NSDate* fireDate = [NSDate dateWithTimeIntervalSinceNow:duration];
                localNotification.fireDate = fireDate;
                
                localNotification.alertBody = NSLocalizedString(@"LS_Unlock_Room_Complete", NULL);
 
                localNotification.soundName = UILocalNotificationDefaultSoundName;
                localNotification.applicationIconBadgeNumber = 1;

                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
                break;
            }
            
            case ROOM_UNLOCK_STATE_IDLE:
            {
                [self EvaluateBadge];
                [[SaveSystem GetInstance] ClearRoomUnlockTimestamp];
                break;
            }
        }
    }
}

-(RoomUnlockState)GetRoomUnlockState
{
    return mRoomUnlockState;
}

-(int)GetRoomUnlockSeconds
{
#if IAP_DEVELOPER_MODE
    return SECONDS_UNTIL_NEXT_ROOM_UNLOCK_DEVELOPER;
#else
    return SECONDS_UNTIL_NEXT_ROOM_UNLOCK;
#endif
}

-(void)EvaluateBadge
{
    if (mRoomUnlockState == ROOM_UNLOCK_STATE_IDLE)
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
}

@end