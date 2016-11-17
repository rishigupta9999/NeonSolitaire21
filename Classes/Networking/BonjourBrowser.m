//
//  BonjourBrowser.m
//  NeonEngineDebugger
//
//  Created by Rishi Gupta on 3/14/14.
//  Copyright (c) 2014 Neon Games LLC. All rights reserved.
//

#import "BonjourBrowser.h"
#import "Connection.h"

static BonjourBrowser* sInstance = NULL;

static NSString* NEON_TRANSPORT_SERVICE = @"_neonengine._tcp.";

@implementation ServiceEntry

@synthesize NetService = mNetService;
@synthesize ServiceEntryState = mServiceEntryState;

-(ServiceEntry*)init
{
    mNetService = NULL;
    mServiceEntryState = SERVICEENTRY_STATE_UNRESOLVED;
    mConnection = FALSE;
    
    return self;
}

-(void)dealloc
{
    [mConnection release];
    
    [super dealloc];
}

-(void)Resolve
{
    [mNetService setDelegate:self];
    [mNetService resolveWithTimeout:1000];
}

-(void)netServiceDidResolveAddress:(NSNetService*)sender
{
    mHostName = sender.hostName;
    mPort = sender.port;
}

@end

@implementation BonjourBrowser

@synthesize BrowserViewController = mBrowserViewController;

-(BonjourBrowser*)init
{
    self = [super init];
    
    mServicesArray = [[NSMutableArray alloc] init];
    
    mServiceBrowser = [[NSNetServiceBrowser alloc] init];
    [mServiceBrowser setDelegate:self];
    [mServiceBrowser searchForServicesOfType:NEON_TRANSPORT_SERVICE inDomain:@"local."];
    
    mBrowserViewController = NULL;
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create BonjourBrowser");
    sInstance = [[BonjourBrowser alloc] init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to double-delete BonjourBrowser");
    [sInstance release];
    
    sInstance = NULL;
}

+(BonjourBrowser*)GetInstance
{
    return sInstance;
}

-(int)GetNumServices
{
    return (int)[mServicesArray count];
}

-(ServiceEntry*)GetServiceAtIndex:(int)inIndex
{
    return [mServicesArray objectAtIndex:inIndex];
}

-(void)ConnectToService:(int)inIndex
{
    ServiceEntry* serviceEntry = [self GetServiceAtIndex:inIndex];
    serviceEntry->mConnection = [[Connection alloc] initWithServiceEntry:serviceEntry];
}

-(void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)netService moreComing:(BOOL)moreServicesComing
{
    ServiceEntry* serviceEntry = [[ServiceEntry alloc] init];
    serviceEntry.NetService = netService;
    
    [mServicesArray addObject:serviceEntry];
    [serviceEntry Resolve];
    [serviceEntry release];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
    int numEntries = (int)[mServicesArray count];
    
    for (int i = 0; i < numEntries; i++)
    {
        ServiceEntry* curEntry = [mServicesArray objectAtIndex:i];
        NSNetService* entryService = curEntry.NetService;
        
        if ([entryService isEqual:netService])
        {
            [mServicesArray removeObjectAtIndex:i];
            break;
        }
    }
}


@end
