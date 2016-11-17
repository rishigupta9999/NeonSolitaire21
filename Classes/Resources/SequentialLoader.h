//
//  SequentialLoader.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

@class SequentialLoader;

@protocol SequentialLoaderProtocol

-(NSObject*)PreloadObjectWithIndex:(int)inIndex forLoader:(SequentialLoader*)inLoader;
-(void)ProcessLoadedObject:(NSObject*)inObject atIndex:(int)inIndex forLoader:(SequentialLoader*)inLoader;
-(void)UnloadObject:(NSObject*)inObject atIndex:(int)inIndex forLoader:(SequentialLoader*)inLoader;

-(int)AddRef:(NSObject*)inObject;
-(int)DecRef:(NSObject*)inObject;

@end

@interface SequentialLoaderObjectRecord : NSObject
{
    NSObject*   mObject;
    int         mIndex;
    NSObject<SequentialLoaderProtocol>* mCallback;
    SequentialLoader*   mLoader;
}

-(SequentialLoaderObjectRecord*)Init;
-(SequentialLoaderObjectRecord*)InitWithRecord:(SequentialLoaderObjectRecord*)inRecord;
-(void)dealloc;

-(int)GetIndex;
-(NSObject*)GetObject;

-(void)ReplaceWithContentsOfRecord:(SequentialLoaderObjectRecord*)inRecord;
-(void)SetObject:(NSObject*)inObject forIndex:(int)inIndex withCallback:(NSObject<SequentialLoaderProtocol>*)inCallback loader:(SequentialLoader*)inLoader;
-(void)Invalidate;

@end

typedef struct
{
    NSMutableArray* mIndices;
    int             mWindowSize;
    int             mStartingIndex;
    
    NSObject<SequentialLoaderProtocol>* mCallback;
} SequentialLoaderParams;

@interface SequentialLoader : NSObject
{
    NSMutableArray*         mObjects;
    NSMutableArray*         mObjectReferenceCache;
    int*                    mDesiredIndexList;
    
    int                     mNumObjects;
    
    int                     mCurIndex;
    
    SequentialLoaderParams  mParams;
}

-(SequentialLoader*)InitWithParams:(SequentialLoaderParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(SequentialLoaderParams*)outParams;

-(void)SetIndex:(int)inIndex;
-(int)GetIndex;

-(NSObject*)GetObjectAtWindowPosition:(int)inPosition;

-(void)EvaluateLoads;
-(void)CalculateNewIndices;

@end