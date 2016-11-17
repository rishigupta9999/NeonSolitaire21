//
//  GameObjectSystem.m
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "GameObjectManager.h"
#import "ModelManager.h"
#import "NeonButton.h"
#import "Event.h"

static const int GAME_OBJECT_LIST_INITIAL_SIZE = 512;

#define CONSTANT_TIME_STEP  (1.0 / 60.0)

@implementation GameObjectCollection

-(GameObjectCollection*)Init
{
    NeonArrayParams params;
    NeonArray_InitParams(&params);
    
    params.mInitialNumElements = GAME_OBJECT_LIST_INITIAL_SIZE;
    params.mElementSize = sizeof(GameObject*);
    
    mGameObjectList = NeonArray_Create(&params);
    mUpdating = FALSE;
    
    [GetGlobalMessageChannel() AddListener:self];
    
    return self;
}

-(void)dealloc
{
    NeonArray_Destroy(mGameObjectList);
    [super dealloc];
}

-(void)Remove
{
    [GetGlobalMessageChannel() RemoveListener:self];
}

-(void)Add:(GameObject*)inObject withRenderBin:(RenderBinId)inRenderBinId
{
    int numObjects = NeonArray_GetNumElements(mGameObjectList);
    
    inObject->mRenderBinId = inRenderBinId;

#if NEON_DEBUG
    for (int i = 0; i < numObjects; i++)
    {
        GameObject* curObject = *(GameObject**)NeonArray_GetElementAtIndexFast(mGameObjectList, i);
        NSAssert(curObject != inObject, @"Attempting to double-add an object");
    }
#endif
    // Insertion sort by renderbin priority
    
    BOOL objectInserted = FALSE;
    
    for (int i = 0; i < numObjects; i++)
    {
        RenderBinId testObjRenderBinId = [*(GameObject**)NeonArray_GetElementAtIndexFast(mGameObjectList, i) GetRenderBinId];
        
        int newObjPriority = [[ModelManager GetInstance] GetRenderBinWithId:inRenderBinId]->mPriority;
        int testObjPriority = [[ModelManager GetInstance] GetRenderBinWithId:testObjRenderBinId]->mPriority;
                
        if (newObjPriority < testObjPriority)
        {
            NeonArray_InsertElementAtIndex(mGameObjectList, &inObject, i);            
            objectInserted = TRUE;
            break;
        }
    }
    
    if (!objectInserted)
    {
        NeonArray_InsertElementAtEnd(mGameObjectList, &inObject);
    }
    
    [inObject SetOwningCollection:self];
    
    [inObject retain];
}

-(void)Add:(GameObject*)inObject
{
    [self Add:inObject withRenderBin:[inObject GetRenderBinId]];
}

-(void)Remove:(GameObject*)inObject
{
	// Early exit, nothing to do.
	if (inObject == NULL)
	{
		return;
	}
	
    if (!mUpdating)
    {
        NSAssert(inObject->mGameObjectState != GAMEOBJECT_DELETE_AFTER_OPERATIONS, @"Object being removed during animation");

        //[mGameObjectList removeObject:inObject];
        //
        // I'm leaving the above code as a pitfall example.  It is valid for inObject to be invalid, removing an object
        // should just involve comparing pointers (whether the pointers are valid or invalid is irrelevant).  However, the
        // [NSMutableArray removeObject:] function retains the object passed in.  So if inObject is invalid, this causes a crash.
        
        int count = NeonArray_GetNumElements(mGameObjectList);
                
        for (int i = 0; i < count; i++)
        {
            if (*(GameObject**)NeonArray_GetElementAtIndexFast(mGameObjectList, i) == inObject)
            {
                [inObject SetOwningCollection:NULL];

                NeonArray_RemoveElementAtIndex(mGameObjectList, i);
                [inObject release];
                break;
            }
        }
    }
    else
    {
        inObject->mGameObjectState = GAMEOBJECT_DELETE_AFTER_UPDATE;
    }
}

-(GameObject*)GetObject:(int)inIndex
{
    return *(GameObject**)NeonArray_GetElementAtIndexFast(mGameObjectList, inIndex);
}

-(int)GetSize
{
    return NeonArray_GetNumElements(mGameObjectList);
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    int numObjects = [self GetSize];
    
    mUpdating = TRUE;
    
    for (int i = 0; i < numObjects; i++)
    {
        GameObject* obj = [self GetObject:i];
        BOOL objectDeleted = GameObjectCollection_UpdateObject(self, obj, inTimeStep);
        
        if (objectDeleted)
        {
            i--;
            numObjects--;
        }
    }
    
    mUpdating = FALSE;
}

-(GameObject*)FindObjectWithHash:(u32)inHash
{
    GameObject* retVal = NULL;
    
    int numObjects = [self GetSize];
        
    for (int i = 0; i < numObjects; i++)
    {
        GameObject* curObj = [self GetObject:i];
        
        if (curObj->mIdentifier == inHash)
        {
            retVal = curObj;
            break;
        }
    }
    
    return retVal;
}

-(u32)GetNumVisible3DObjects
{
    int numObjects = [self GetSize];
    
    u32 num3DObjects = 0;
        
    for (int i = 0; i < numObjects; i++)
    {
        GameObject* obj = [self GetObject:i];
        
        if (((!obj->mOrtho) || ([obj GetProjected])) && ([obj GetVisible]))
        {
            num3DObjects++;
        }
    }
    
    return num3DObjects;
}

-(u32)GenerateHash:(const char*)inString
{
    // djb2 hash - see http://www.cse.yorku.ca/~oz/hash.html for reference
    
    unsigned long hash = 5381;
    int c;

    while ((c = *inString++))
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */

    return hash;
}

-(NSUInteger)FindObject:(GameObject*)inObject
{
    return NeonArray_IndexOfElement(mGameObjectList, &inObject);
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_LIGHT_REMOVED:
        {
            int numObjects = [self GetSize];
                
            for (int i = 0; i < numObjects; i++)
            {
                GameObject* obj = [self GetObject:i];
                
                [obj RemoveAffectingLight:inMsg->mData];
            }
            
            break;
        }
    }
}

#if FUNCTION_DISPATCH_OPTIMIZATION
BOOL GameObjectCollection_UpdateObject(GameObjectCollection* inCollection, GameObject* inObject, CFTimeInterval inTimeStep)
{
    CFTimeInterval timeStep = inTimeStep;
    
    if (inObject->mTimeStepType == GAMEOBJECT_TIMESTEP_CONSTANT)
    {
        timeStep = CONSTANT_TIME_STEP;
    }
    
    [inObject Update:timeStep];
    
    if (inObject->mGameObjectState == GAMEOBJECT_DELETE_AFTER_UPDATE)
    {
        BOOL objFound = NeonArray_RemoveElement(inCollection->mGameObjectList, &inObject);
        inObject->mGameObjectState = GAMEOBJECT_COMPLETED;
        
        if (objFound)
        {
            [inObject SetOwningCollection:NULL];
            [inObject release];
        }
        
        return TRUE;
    }
    
    return FALSE;
}
#endif

@end
