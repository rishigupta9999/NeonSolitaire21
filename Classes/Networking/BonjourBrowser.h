//
//  BonjourBrowser.h
//  NeonEngineDebugger
//
//  Created by Rishi Gupta on 3/14/14.
//  Copyright (c) 2014 Neon Games LLC. All rights reserved.
//

@class BrowserViewController;
@class Connection;

typedef enum
{
    SERVICEENTRY_STATE_UNRESOLVED,
    SERVICEENTRY_STATE_RESOLVED
} ServiceEntryState;

@interface ServiceEntry : NSObject<NSNetServiceDelegate>
{
    @public
        NSString*   mHostName;
        NSInteger   mPort;
        Connection* mConnection;
}

@property(retain) NSNetService* NetService;
@property ServiceEntryState ServiceEntryState;

-(ServiceEntry*)init;
-(void)dealloc;

-(void)Resolve;

-(void)netServiceDidResolveAddress:(NSNetService*)sender;

@end

@interface BonjourBrowser : NSObject<NSNetServiceBrowserDelegate>
{
    NSNetServiceBrowser*    mServiceBrowser;
    NSMutableArray*         mServicesArray;
}

@property(assign) BrowserViewController* BrowserViewController;

-(BonjourBrowser*)init;
-(void)dealloc;

+(void)CreateInstance;
+(void)DestroyInstance;
+(BonjourBrowser*)GetInstance;

-(int)GetNumServices;
-(ServiceEntry*)GetServiceAtIndex:(int)inIndex;
-(void)ConnectToService:(int)inIndex;

-(void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)netService moreComing:(BOOL)moreServicesComing;
-(void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)netService moreComing:(BOOL)moreServicesComing;

@end
