//
//  SequentialLoader.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "SequentialLoader.h"

#define DEFAULT_WINDOW_SIZE (1)
#define INDEX_INVALID       (-1)

@implementation SequentialLoaderObjectRecord

-(SequentialLoaderObjectRecord*)Init
{
    mObject = NULL;
    mIndex = INDEX_INVALID;
    mCallback = NULL;
    mLoader = NULL;
    
    return self;
}

-(SequentialLoaderObjectRecord*)InitWithRecord:(SequentialLoaderObjectRecord*)inRecord
{
    mObject = [inRecord->mObject retain];
    
    if (mObject != NULL)
    {
        [inRecord->mCallback AddRef:mObject];
    }
    
    mIndex = inRecord->mIndex;
    mCallback = inRecord->mCallback;
    
    return self;
}

-(void)dealloc
{
    [mObject release];
    
    if (mObject != NULL)
    {
        int newRef = [mCallback DecRef:mObject];
        
        if (newRef == 0)
        {
            [mCallback UnloadObject:mObject atIndex:mIndex forLoader:mLoader];
        }
    }
        
    [super dealloc];
}

-(int)GetIndex
{
    return mIndex;
}

-(NSObject*)GetObject
{
    return mObject;
}

-(void)SetObject:(NSObject*)inObject forIndex:(int)inIndex withCallback:(NSObject<SequentialLoaderProtocol>*)inCallback loader:(SequentialLoader*)inLoader
{    
    if (mObject != NULL)
    {
        NSAssert(inCallback == mCallback, @"Mismatched callbacks.  This is weird");

        [mObject release];
        int newRef = [inCallback DecRef:mObject];
        
        if (newRef == 0)
        {
            [inCallback UnloadObject:mObject atIndex:mIndex forLoader:mLoader];
        }
    }
    
    mObject = inObject;
    [mObject retain];
    
    if (inObject != NULL)
    {
        [inCallback AddRef:mObject];
    }
    
    mIndex = inIndex;
    
    mCallback = inCallback;
    mLoader = inLoader;
}

-(void)Invalidate
{
    [self SetObject:NULL forIndex:INDEX_INVALID withCallback:mCallback loader:mLoader];
}

-(void)ReplaceWithContentsOfRecord:(SequentialLoaderObjectRecord*)inRecord
{
    NSAssert(inRecord->mCallback == mCallback, @"Mismatched callbacks.  This is weird");

    [self Invalidate];
    
    mObject = [inRecord->mObject retain];
    
    if (mObject != NULL)
    {
        [mCallback AddRef:inRecord->mObject];
    }
    
    mIndex = inRecord->mIndex;
    mCallback = inRecord->mCallback;
}

@end

@implementation SequentialLoader

-(SequentialLoader*)InitWithParams:(SequentialLoaderParams*)inParams
{
    memcpy(&mParams, inParams, sizeof(SequentialLoaderParams));
    [mParams.mIndices retain];
    [mParams.mCallback retain];
    
#if NEON_DEBUG
    for (NSNumber* curIndex in mParams.mIndices)
    {
        if ([curIndex intValue] < 0)
        {
            NSAssert(FALSE, @"A negative index was passed in.  All SequentialLoader indices must be positive.");
        }
    }
#endif
        
    mNumObjects = (mParams.mWindowSize * 2) + 1;
    mObjects = [[NSMutableArray alloc] initWithCapacity:mNumObjects];
    mObjectReferenceCache = [[NSMutableArray alloc] initWithCapacity:mNumObjects];
    
    mDesiredIndexList = (int*)malloc(sizeof(int) * mNumObjects);
    
    for (int i = 0; i < mNumObjects; i++)
    {
        SequentialLoaderObjectRecord* newRecord = [(SequentialLoaderObjectRecord*)[SequentialLoaderObjectRecord alloc] Init];
        
        [newRecord SetObject:NULL forIndex:INDEX_INVALID withCallback:mParams.mCallback loader:self];
        [mObjects addObject:newRecord];
        
        [newRecord release];
    }
    
    [self SetIndex:mParams.mStartingIndex];
    
    return self;
}

-(void)dealloc
{
    [mParams.mIndices release];
    [mParams.mCallback release];
    
    [mObjects release];
    [mObjectReferenceCache release];
    
    free(mDesiredIndexList);
    
    [super dealloc];
}

+(void)InitDefaultParams:(SequentialLoaderParams*)outParams
{
    outParams->mIndices = NULL;
    outParams->mWindowSize = DEFAULT_WINDOW_SIZE;
    outParams->mStartingIndex = 0;
    outParams->mCallback = NULL;
}

-(void)SetIndex:(int)inIndex
{
    mCurIndex = inIndex;
    
    [self EvaluateLoads];
}

-(int)GetIndex
{
    return mCurIndex;
}

-(NSObject*)GetObjectAtWindowPosition:(int)inPosition
{
    SequentialLoaderObjectRecord* record = [mObjects objectAtIndex:inPosition];
    
    return [record GetObject];
}

-(void)EvaluateLoads
{
    // Calculate image indices we should load.
    [self CalculateNewIndices];
    
    for (int i = 0; i < mNumObjects; i++)
    {
        SequentialLoaderObjectRecord* dup = [(SequentialLoaderObjectRecord*)[SequentialLoaderObjectRecord alloc] InitWithRecord:[mObjects objectAtIndex:i]];
        [mObjectReferenceCache addObject:dup];
        [dup release];
    }
    
    for (int newPosition = 0; newPosition < mNumObjects; newPosition++)
    {
        if ((mDesiredIndexList[newPosition] >= 0) && (mDesiredIndexList[newPosition] < [mParams.mIndices count]))
        {
            // Check and see if this image is presently loaded.  If so, don't reload it,
            // just re-assign it to the appropriate position
            
            BOOL objectFound = FALSE;
            
            for (SequentialLoaderObjectRecord* objectRecord in mObjectReferenceCache)
            {
                if ([objectRecord GetIndex] == mDesiredIndexList[newPosition])
                {
                    objectFound = TRUE;

                    SequentialLoaderObjectRecord* oldRecord = [mObjects objectAtIndex:newPosition];                    
                    [oldRecord ReplaceWithContentsOfRecord:objectRecord];
                    
                    [mParams.mCallback ProcessLoadedObject:[oldRecord GetObject] atIndex:[oldRecord GetIndex] forLoader:self];
                    
                    break;
                }
            }
            
            if (!objectFound)
            {
                SequentialLoaderObjectRecord* oldRecord = [mObjects objectAtIndex:newPosition];
                                
                NSObject* newObject = [mParams.mCallback PreloadObjectWithIndex:mDesiredIndexList[newPosition] forLoader:self];
                [oldRecord SetObject:newObject forIndex:mDesiredIndexList[newPosition] withCallback:mParams.mCallback loader:self];
            }
        }
        else
        {
            SequentialLoaderObjectRecord* oldRecord = [mObjects objectAtIndex:newPosition];
            [oldRecord Invalidate];
        }
    }
    
    [mObjectReferenceCache removeAllObjects];
}

-(void)CalculateNewIndices
{
    for (int newPosition = 0; newPosition < mNumObjects; newPosition++)
    {
        // Assign the index of the image that we want to load for this image position
        mDesiredIndexList[newPosition] = mCurIndex + (newPosition - (mNumObjects / 2));
    }
}

@end