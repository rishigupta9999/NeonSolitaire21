//
//  SplitTestingSystem.h
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

typedef enum
{
    SPLIT_TEST_NUM
} SplitTest;

@interface SplitTestingSystem : NSObject
{
    NSMutableDictionary* mSplitTests;
    BOOL                 mFirstLaunch;
}

-(SplitTestingSystem*)Init;
-(void)dealloc;

+(void)CreateInstance;
+(void)DestroyInstance;
+(SplitTestingSystem*)GetInstance;

-(void)AssignBuckets;
-(BOOL)ValidateBuckets;
-(void)DumpBuckets;

-(BOOL)GetSplitTestValue:(SplitTest)inSplitTest;
-(NSString*)GetSplitTestString:(SplitTest)inSplitTest;

-(BOOL)GetFirstLaunch;

@end