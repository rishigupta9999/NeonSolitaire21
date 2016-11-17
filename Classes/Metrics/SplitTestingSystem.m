//
//  SplitTestingSystem.m
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

#import "SplitTestingSystem.h"

static const char*  sSplitTestNames[SPLIT_TEST_NUM] = { };

static const char*  sVersionName = "App Version";

static SplitTestingSystem* sInstance = NULL;

@implementation SplitTestingSystem

-(SplitTestingSystem*)Init
{
    mFirstLaunch = FALSE;
    
#if SPLIT_TEST_FORCE_BUCKETS
    BOOL useSplitTest = 1;
    int  testNumber = SPLIT_TEST_NO_ADS;
    
    mSplitTests = [[NSMutableDictionary alloc] initWithCapacity:SPLIT_TEST_NUM];
    
    for (int i = 0; i < SPLIT_TEST_NUM; i++)
    {
        NSNumber* number = [NSNumber numberWithInt:0];
        
        if (useSplitTest && (testNumber == i))
        {
            number = [NSNumber numberWithInt:1];
        }
        
        [mSplitTests setObject:number forKey:[NSString stringWithUTF8String:sSplitTestNames[i]]];
    }
    
    // Toggle this for testing first launch vs repeated launch functionality
    mFirstLaunch = FALSE;
#else
    static const char* sSplitTestBucketsFile = "SplitTestBuckets.plist";

    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsPath = [paths objectAtIndex:0];
    NSString* splitTestBucketsFilePath = [NSString stringWithFormat:@"%@/%s", documentsPath, sSplitTestBucketsFile];

    if ([[NSFileManager defaultManager] fileExistsAtPath:splitTestBucketsFilePath])
    {
        mSplitTests = (NSMutableDictionary*)[[NSDictionary alloc] initWithContentsOfFile:splitTestBucketsFilePath];
        BOOL valid = [self ValidateBuckets];
        
        if (!valid)
        {
            [mSplitTests writeToFile:splitTestBucketsFilePath atomically:YES];
        }
    }
    else
    {
        [self AssignBuckets];
        [mSplitTests writeToFile:splitTestBucketsFilePath atomically:YES];
        
        mFirstLaunch = TRUE;
    }
#endif
    
    [self DumpBuckets];
    
    return self;
}

-(void)dealloc
{
    [mSplitTests release];
    
    [super dealloc];
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"SplitTestingSystem has already been created");
    
    sInstance = [(SplitTestingSystem*)[SplitTestingSystem alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"SplitTestingSystem has already been destroyed");
    
    [sInstance release];
    sInstance = NULL;
}

+(SplitTestingSystem*)GetInstance
{
    return sInstance;
}

-(void)AssignBuckets
{
    if (SPLIT_TEST_NUM == 0)
    {
        return;
    }
    
    mSplitTests = [[NSMutableDictionary alloc] initWithCapacity:(SPLIT_TEST_NUM + 1)];
    
    for (int i = 0; i < SPLIT_TEST_NUM; i++)
    {
        NSNumber* bucketVal = [NSNumber numberWithBool:0];
        [mSplitTests setObject:bucketVal forKey:[NSString stringWithUTF8String:sSplitTestNames[i]]];
    }
    
    // 50/50 chance that the user gets put into a split test group.  If they do, they get a randomly assigned split test
    BOOL getSplitTest = arc4random_uniform(2);
    
    if (getSplitTest != 0)
    {
        int splitTestNum = arc4random_uniform(SPLIT_TEST_NUM);
        [mSplitTests setObject:[NSNumber numberWithInt:1] forKey:[NSString stringWithUTF8String:sSplitTestNames[splitTestNum]]];
    }
    
    [mSplitTests setObject:[[NeonMetrics GetInstance] GetVersion] forKey:[NSString stringWithUTF8String:sVersionName]];
}

-(BOOL)ValidateBuckets
{
    BOOL valid = TRUE;

    NSArray* allKeys = [mSplitTests allKeys];
    
    // First check if we have any keys that aren't current.  If so, remove them
    
    int numKeys = [allKeys count];
    
    for (int i = 0; i < numKeys; i++)
    {
        NSString* curKey = [allKeys objectAtIndex:i];
        BOOL keyFound = FALSE;
        
        if (strcmp([curKey UTF8String], sVersionName) == 0)
        {
            NSString* curVersion = [[NeonMetrics GetInstance] GetVersion];
            
            if ([(NSString*)[mSplitTests objectForKey:curKey] compare:curVersion] != NSOrderedSame)
            {
                [mSplitTests setObject:curVersion forKey:curKey];
                valid = FALSE;
                
                mFirstLaunch = TRUE;
            }
            
            continue;
        }
        
        for (int ref = 0; ref < SPLIT_TEST_NUM; ref++)
        {
            if (strcmp([curKey UTF8String], sSplitTestNames[ref]) == 0)
            {
                keyFound = TRUE;
                break;
            }
        }
        
        if (!keyFound)
        {
            valid = FALSE;
            [mSplitTests removeObjectForKey:curKey];
        }
    }
    
    // Now add keys that don't exist
    for (int i = 0; i < SPLIT_TEST_NUM; i++)
    {
        NSString* curKey = [NSString stringWithUTF8String:sSplitTestNames[i]];
        
        if ([mSplitTests objectForKey:curKey] == NULL)
        {
            int numVal = (arc4random() % 2);
            NSLog(@"%d", numVal);
            
            NSNumber* bucketVal = [NSNumber numberWithBool:numVal];
            [mSplitTests setObject:bucketVal forKey:curKey];
            
            valid = FALSE;
        }
    }
    
    return valid;
}

-(BOOL)GetSplitTestValue:(SplitTest)inSplitTest
{
    NSAssert((inSplitTest >= 0) && (inSplitTest < SPLIT_TEST_NUM), @"Invalid split test");
    
    NSNumber* key = [mSplitTests objectForKey:[NSString stringWithUTF8String:sSplitTestNames[inSplitTest]]];
    NSAssert(key != NULL, @"Split test key doesn't exist");
    
    return [key boolValue];
}

-(NSString*)GetSplitTestString:(SplitTest)inSplitTest
{
    NSAssert((inSplitTest >= 0) && (inSplitTest < SPLIT_TEST_NUM), @"Invalid split test");
    
    return [NSString stringWithUTF8String:sSplitTestNames[inSplitTest]];

}

-(void)DumpBuckets
{
#if !NEON_PRODUCTION
    for (int i = 0; i < SPLIT_TEST_NUM; i++)
    {
        NSString* keyName = [NSString stringWithUTF8String:sSplitTestNames[i]];
        NSNumber* keyValue = [mSplitTests objectForKey:keyName];
        
        NSLog(@"Split Test %@ = %@", keyName, keyValue);
    }
#endif
}

-(BOOL)GetFirstLaunch
{
    return mFirstLaunch;
}

@end