//
//  NeonMetrics.m
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "NeonMetrics.h"
#import "KISSMetricsAPI.h"
#import "SplitTestingSystem.h"
#import "LocalyticsSession.h"
#import "Event.h"

static NeonMetrics* sInstance = NULL;
static const NSString* sLocalyticsKey = @"116d1fca0f36701b8baa52b-93391014-0d6f-11e4-21a1-004a77f8b47f";

@implementation NeonMetrics

-(NeonMetrics*)Init
{    
    mVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [mVersion retain];

#if !NEON_PRODUCTION
    [Flurry setAppVersion:[NSString stringWithFormat:@"Prerelease-%@", mVersion]];
#else
    [Flurry setAppVersion:mVersion];
#endif
    
    // @TODO: Separate per SKU.
#if NEON_SOLITAIRE_21
    [Flurry startSession:@"GXCM9QJY4BMJBVPYNCNM"];
    [KISSMetricsAPI sharedAPIWithKey:@"5bd6895c9b59d3827385ea73c070891193e0cc19"];
#elif NEON_FREE_VERSION
    [Flurry startSession:@"3PPKCZ4RBXJ47JC3GGR6"];
    [KISSMetricsAPI sharedAPIWithKey:@"5bd6895c9b59d3827385ea73c070891193e0cc19"];
#else
    [Flurry startSession:@"HZHG2S9B27ZZSHX3RJMN"];
#endif

    [[LocalyticsSession shared] LocalyticsSession:(NSString*)sLocalyticsKey];
    [[LocalyticsSession shared] resume];
    
    mLocalyticsSessionCreated = TRUE;
    
    [GetGlobalMessageChannel() AddListener:self];

    return self;
}

-(void)dealloc
{
    [mVersion release];
    
    [super dealloc];
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"NeonMetrics has already been created");
    
    sInstance = [(NeonMetrics*)[NeonMetrics alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"NeonMetrics has already been destroyed");
    
    [sInstance release];
    sInstance = NULL;
}

+(NeonMetrics*)GetInstance
{
    return sInstance;
}

-(NSString*)GetVersion
{
    return mVersion;
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_APPLICATION_RESUMED:
        {
            if (!mLocalyticsSessionCreated)
            {
                [[LocalyticsSession shared] LocalyticsSession:(NSString*)sLocalyticsKey];
            }
            
            [[LocalyticsSession shared] resume];
            [[LocalyticsSession shared] upload];

            break;
        }
        
        case EVENT_APPLICATION_WILL_TERMINATE:
        case EVENT_APPLICATION_SUSPENDED:
        case EVENT_APPLICATION_ENTERED_BACKGROUND:
        {
            [[LocalyticsSession shared] close];
            [[LocalyticsSession shared] upload];

            break;
        }
    }
}

-(void)logEvent:(NSString*)inEvent withParameters:(NSDictionary*)inParameters
{
    NSMutableDictionary* newDictionary = [[NSMutableDictionary alloc] initWithDictionary:inParameters];
    
#if !SPLIT_TEST_FORCE_BUCKETS
    for (int i = 0; i < SPLIT_TEST_NUM; i++)
    {
        [newDictionary setObject:[NSNumber numberWithBool:[[SplitTestingSystem GetInstance] GetSplitTestValue:i]] forKey:[[SplitTestingSystem GetInstance] GetSplitTestString:i]];
    }
#endif
    
    [Flurry logEvent:inEvent withParameters:newDictionary];
    [[KISSMetricsAPI sharedAPI] recordEvent:inEvent withProperties:newDictionary];
    [[LocalyticsSession shared] tagEvent:inEvent attributes:newDictionary];
    
    [newDictionary release];
}

-(void)logEvent:(NSString*)inEvent withParameters:(NSDictionary*)inParameters type:(NeonMetricType)inType
{
    NSMutableDictionary* newDictionary = [[NSMutableDictionary alloc] initWithDictionary:inParameters];

#if !SPLIT_TEST_FORCE_BUCKETS
    for (int i = 0; i < SPLIT_TEST_NUM; i++)
    {
        [newDictionary setObject:[NSNumber numberWithBool:[[SplitTestingSystem GetInstance] GetSplitTestValue:i]] forKey:[[SplitTestingSystem GetInstance] GetSplitTestString:i]];
    }
#endif

    switch(inType)
    {
        case NEON_METRIC_TYPE_KISS:
        {
            [[KISSMetricsAPI sharedAPI] recordEvent:inEvent withProperties:newDictionary];
            [[LocalyticsSession shared] tagEvent:inEvent attributes:newDictionary];
            break;
        }
        
        case NEON_METRIC_TYPE_FLURRY:
        {
            [Flurry logEvent:inEvent withParameters:newDictionary];
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown metric type");
        }
    }
    
    [newDictionary release];
}

-(void)logEvent:(NSString*)inEvent withParameters:(NSDictionary*)inParameters timed:(BOOL)inTimed
{
    NSMutableDictionary* newDictionary = [[NSMutableDictionary alloc] initWithDictionary:inParameters];
    
    for (int i = 0; i < SPLIT_TEST_NUM; i++)
    {
        [newDictionary setObject:[NSNumber numberWithBool:[[SplitTestingSystem GetInstance] GetSplitTestValue:i]] forKey:[[SplitTestingSystem GetInstance] GetSplitTestString:i]];
    }

    [Flurry logEvent:inEvent withParameters:newDictionary timed:inTimed];
    [[KISSMetricsAPI sharedAPI] recordEvent:[NSString stringWithFormat:@"%@_start", inEvent] withProperties:newDictionary];
    [[LocalyticsSession shared] tagEvent:[NSString stringWithFormat:@"%@_start", inEvent] attributes:newDictionary];
    
    [newDictionary release];
}

-(void)endTimedEvent:(NSString*)inEvent withParameters:(NSDictionary*)inParameters
{
    NSMutableDictionary* newDictionary = [[NSMutableDictionary alloc] initWithDictionary:inParameters];
    
    for (int i = 0; i < SPLIT_TEST_NUM; i++)
    {
        [newDictionary setObject:[NSNumber numberWithBool:[[SplitTestingSystem GetInstance] GetSplitTestValue:i]] forKey:[[SplitTestingSystem GetInstance] GetSplitTestString:i]];
    }

    [Flurry endTimedEvent:inEvent withParameters:newDictionary];
    [[KISSMetricsAPI sharedAPI] recordEvent:[NSString stringWithFormat:@"%@_end", inEvent] withProperties:newDictionary];
    [[LocalyticsSession shared] tagEvent:[NSString stringWithFormat:@"%@_end", inEvent] attributes:newDictionary];
    
    [newDictionary release];
}

@end