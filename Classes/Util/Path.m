//
//  Path.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "Path.h"

#define DEFAULT_NUM_PATH_NODES  (4)
#define INVALID_NODE_INDEX      (-1)

@implementation PathNode
@end

@implementation BezierPathNode
@end

@implementation PathActionNode
@end

@implementation Path

-(Path*)Init
{
    mNodes = [[NSMutableArray alloc] initWithCapacity:DEFAULT_NUM_PATH_NODES];
    mActions = [[NSMutableArray alloc] initWithCapacity:0];
    
    // If the user calls reset, don't reset these.  Chances are they don't want to respecify these fields.
    mUserData = 0;
    mPeriodic = 0;
    mCallback = NULL;
    
    mDebugState = FALSE;
    
    mType = PATH_TYPE_INVALID;
    
    [self Reset];
    
    return self;
}

-(void)dealloc
{
    if (mCallback != NULL)
    {
        if ([self Finished] && ([mNodes count] > 0))
        {   
            NSAssert(mDispatchedFinishedEvent, @"Path is being deallocted, but its callback was never called");
        }
    }
    
    [mNodes release];
    [mActions release];
    
    [super dealloc];
}

-(Path*)InitWithPath:(Path*)inPath
{
    Path* newPath = [self Init];
    NSAssert(newPath != NULL, @"Path initialization can never return NULL.");
    newPath = newPath;
    
    [self Reset];
    
    // Copy all the simple instance variables
    mType = inPath->mType;
    mInterpolationMethod = inPath->mInterpolationMethod;
    mPeriodic = inPath->mPeriodic;
    mCallback = [inPath->mCallback retain];
    mUserData = inPath->mUserData;
    mFinalTime = inPath->mFinalTime;
    
    // Now copy all nodes
    for (PathNode* curPathNode in inPath->mNodes)
    {
        PathNode* newNode = NULL;
        
        switch(curPathNode->mInterpolationMethod)
        {
            case PATH_INTERPOLATION_LINEAR:
            {
                newNode = [PathNode alloc];
                break;
            }
            
            case PATH_INTERPOLATION_BEZIER:
            {
                newNode = [BezierPathNode alloc];
                BezierPathNode* destNode = (BezierPathNode*)newNode;
                BezierPathNode* srcNode = (BezierPathNode*)curPathNode;
                
                // Copy over bezier specific properties.  Common properties will be copied below.
                CloneVec2(&srcNode->mInTangent, &destNode->mInTangent);
                CloneVec2(&srcNode->mOutTangent, &destNode->mOutTangent);
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown path interpolation type");
                break;
            }
        }
        
        CloneVec4(&curPathNode->mValue, &newNode->mValue);
        newNode->mTime = curPathNode->mTime;
        newNode->mSpeed = curPathNode->mSpeed;
        newNode->mInterpolationMethod = curPathNode->mInterpolationMethod;
        
        [mNodes addObject:newNode];
        [newNode release];
    }
    
    // Copy all path actions
    for (PathActionNode* curPathAction in inPath->mActions)
    {
        PathActionNode* newPathAction = [PathActionNode alloc];
        
        newPathAction->mTime = curPathAction->mTime;
        newPathAction->mAction = curPathAction->mAction;
        
        [mActions addObject:newPathAction];
        [newPathAction release];
    }
        
    return self;
}

+(void)InitPathNodeParams:(PathNodeParams*)outParams
{
    outParams->mInterpolationMethod = PATH_INTERPOLATION_LINEAR;
    outParams->mTime = 0.0;
    
    memset(outParams->mPathTypeSpecificData.mLinearData.mPad, 0, sizeof(outParams->mPathTypeSpecificData.mLinearData));
}

-(void)Reset
{
    mTime = 0.0f;
    mType = PATH_TYPE_INVALID;
    mInterpolationMethod = PATH_INTERPOLATION_INVALID;
    mLastNodeVisited = 0;
    mLastActionVisited = INVALID_NODE_INDEX;
    mVisitTime = 0.0;
    mFinalTime = 0.0;
    
    mDispatchedFinishedEvent = FALSE;
    
    mPathState = PATH_STATE_PLAYING;
    
    [mNodes removeAllObjects];
    [mActions removeAllObjects];
}

-(void)AddNodeVec4:(Vector4*)inValue atTime:(CFTimeInterval)inTime
{
    PathNodeParams pathNodeParams;
    
    [Path InitPathNodeParams:&pathNodeParams];
    pathNodeParams.mTime = inTime;
    
    [self AddNodeVec4:inValue withParams:&pathNodeParams];
}

-(void)AddNodeVec3:(Vector3*)inValue atTime:(CFTimeInterval)inTime
{
    Vector4 tempVec;
    
    SetVec4From3(&tempVec, inValue, 0.0f);
    [self AddNodeVec4:&tempVec atTime:inTime];
}

-(void)AddNodeScalar:(float)inValue atTime:(CFTimeInterval)inTime
{
    Vector4 tempVec = { inValue, inValue, inValue, inValue };
    
    [self AddNodeVec4:&tempVec atTime:inTime];
}

-(void)AddNodeVec4:(Vector4*)inValue withParams:(PathNodeParams*)inParams
{    
    if (mType == PATH_TYPE_INVALID)
    {
        mType = PATH_TYPE_TIME;
    }
    else
    {
        NSAssert(mType == PATH_TYPE_TIME, @"Trying to add a time node to a velocity based path.  This won't work.");
        
        if (mType != PATH_TYPE_TIME)
        {
            return;
        }
    }
    
    if (mInterpolationMethod == PATH_INTERPOLATION_INVALID)
    {
        NSAssert(inParams->mInterpolationMethod != PATH_INTERPOLATION_INVALID, @"Invalid path interpolation method specified");
        mInterpolationMethod = inParams->mInterpolationMethod;
    }
    else
    {
        NSAssert(mInterpolationMethod == inParams->mInterpolationMethod, @"Trying to re-specify the path interpolation method.  This is not currently supported.");
        
        if (mInterpolationMethod != inParams->mInterpolationMethod)
        {
            return;
        }
    }
    
    // Create new node
    PathNode* newNode = NULL;
    
    switch(mInterpolationMethod)
    {
        case PATH_INTERPOLATION_LINEAR:
        {
            newNode = [PathNode alloc];
            break;
        }
        
        case PATH_INTERPOLATION_BEZIER:
        {
            newNode = [BezierPathNode alloc];
            BezierPathNode* bezierNode = (BezierPathNode*)newNode;
            
            CloneVec2(&inParams->mPathTypeSpecificData.mBezierData.mInTangent, &bezierNode->mInTangent);
            CloneVec2(&inParams->mPathTypeSpecificData.mBezierData.mOutTangent, &bezierNode->mOutTangent);
            
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown path interpolation type");
            break;
        }
    }
        
    [newNode autorelease];
    
    newNode->mSpeed = 0.0;

    
    CloneVec4(inValue, &newNode->mValue);
    newNode->mTime = inParams->mTime;
    newNode->mInterpolationMethod = inParams->mInterpolationMethod;
    
    // Find upper and lower bounds of where the node should go
    PathNode* upper = NULL;
    PathNode* lower = NULL;
    
    [self GetBoundingNodes:inParams->mTime Lower:&lower Upper:&upper];
    
    // Add the node to the list
    if (lower == NULL)
    {
        // First node in the list
        [mNodes insertObject:newNode atIndex:0];
        
        if ([mNodes count] == 1)
        {
            mFinalTime = inParams->mTime;
        }
    }
    else if (upper == NULL)
    {
        // Last node in the list
        [mNodes addObject:newNode];
        
        mFinalTime = inParams->mTime;
    }
    else
    {
        // Somewhere in the middle
        int index = [mNodes indexOfObject:lower];
        
        NSAssert(index != -1, @"lower bound is a garbage node.  Step through the GetBoundingNodes function.");
        
        [mNodes insertObject:newNode atIndex:(index + 1)];
    }
}

-(void)AddNodeVec3:(Vector3*)inValue withParams:(PathNodeParams*)inParams
{
    Vector4 tempVec;
    
    SetVec4From3(&tempVec, inValue, 0.0f);
    [self AddNodeVec4:&tempVec withParams:inParams];
}

-(void)AddNodeX:(float)inX y:(float)inY z:(float)inZ atTime:(CFTimeInterval)inTime
{
    Vector3 tempVec;
    
    tempVec.mVector[x] = inX;
    tempVec.mVector[y] = inY;
    tempVec.mVector[z] = inZ;
    
    [self AddNodeVec3:&tempVec atTime:inTime];
}

-(void)AddNodeScalar:(float)inValue withParams:(PathNodeParams*)inParams
{
    Vector4 tempVec = { inValue, inValue, inValue, inValue };
    
    [self AddNodeVec4:&tempVec withParams:inParams];
}

-(void)AddNodeVec4:(Vector4*)inValue atIndex:(u32)inIndex withSpeed:(float)inSpeed
{
    // Create new node
    PathNode* newNode = [[PathNode alloc] autorelease];

    if (mType == PATH_TYPE_INVALID)
    {
        mType = PATH_TYPE_SPEED;
    }
    else
    {
        NSAssert(mType == PATH_TYPE_SPEED, @"Trying to add a velocity node to a time based path.  This won't work.");
        
        if (mType != PATH_TYPE_SPEED)
        {
            return;
        }
    }
    
    // We only support linear interpolation for speed based paths.  One day when I feel like busting out the calculus textbook
    // (and there is need for it) we'll support bezier.
    if (mInterpolationMethod == PATH_INTERPOLATION_INVALID)
    {
        mInterpolationMethod = PATH_INTERPOLATION_LINEAR;
    }
    else
    {
        NSAssert(mInterpolationMethod == PATH_INTERPOLATION_LINEAR, @"Trying to add a linear node to a non-linear path.");
    }
    
    NSAssert(inIndex <= [mNodes count], @"Index specified is too high.");
    NSAssert( (inIndex >= [mNodes count]) , @"Trying to re-add a node at an index where a node already exists.");
    
    CloneVec4(inValue, &newNode->mValue);

    newNode->mSpeed = inSpeed;
    newNode->mTime = 0.0;
    newNode->mInterpolationMethod = PATH_INTERPOLATION_LINEAR;
    
    [mNodes insertObject:newNode atIndex:inIndex];
}

-(void)AddNodeVec3:(Vector3*)inValue atIndex:(u32)inIndex withSpeed:(float)inSpeed;
{
    Vector4 vec4Value;
    
    SetVec4From3(&vec4Value, inValue, 0.0f);
    
    [self AddNodeVec4:&vec4Value atIndex:inIndex withSpeed:inSpeed];
}

-(void)AddNodeScalar:(float)inValue atIndex:(u32)inIndex withSpeed:(float)inSpeed
{
    Vector4 vec4Value = { inValue, inValue, inValue, inValue };
    
    [self AddNodeVec4:&vec4Value atIndex:inIndex withSpeed:inSpeed];
}

-(void)GetBoundingNodes:(CFTimeInterval)inTime Lower:(PathNode**)outLower Upper:(PathNode**)outUpper
{
    // Insert into appropriate part of the list of nodes
    int numNodes = [mNodes count];
    
    PathNode* prevNode = NULL;
    PathNode* curNode = NULL;
    
    for (int i = 0; i < numNodes; i++)
    {
        curNode = [mNodes objectAtIndex:i];
        
        if (prevNode == NULL)
        {
            if (inTime < curNode->mTime)
            {
                *outLower = NULL;
                *outUpper = curNode;
                return;
            }
        }
        else
        {
            if ((prevNode->mTime <= inTime) && (inTime < curNode->mTime))
            {
                *outLower = prevNode;
                *outUpper = curNode;
                return;
            }
        }
        
        prevNode = curNode;
    }
    
    *outLower = curNode;
    *outUpper = NULL;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if (mPathState == PATH_STATE_PLAYING)
    {
        mTime += inTimeStep;

        [self EvaluatePath];
    }
}

-(void)Pause
{
    mPathState = PATH_STATE_PAUSED;
}

-(void)Play
{
    mPathState = PATH_STATE_PLAYING;
}

-(void)InsertPauseAtTime:(CFTimeInterval)inTime
{
    if (mType == PATH_TYPE_INVALID)
    {
        mType = PATH_TYPE_TIME;
    }
    
    if (mType == PATH_TYPE_TIME)
    {
        [self AddAction:PATH_ACTION_PAUSE atTime:inTime];
    }
    else
    {
        NSAssert(FALSE, @"Can only call this function for time based paths.");
    }
}

-(PathType)GetPathType
{
    return mType;
}
 
-(void)EvaluatePath
{
    if (mType == PATH_TYPE_TIME)
    {
        int actionCount = [mActions count];
        
        for (int curActionIndex = 0; curActionIndex < actionCount; curActionIndex++)
        {
            PathActionNode* curActionNode = [mActions objectAtIndex:curActionIndex];
            
            if ((mTime > curActionNode->mTime) && (mLastActionVisited < curActionIndex))
            {
                mLastActionVisited = curActionIndex;
                [self PerformAction:curActionNode];
                break;
            }
        }
        
        if (mTime > mFinalTime)
        {
            if (mPeriodic)
            {            
                mTime -= mFinalTime;                
            }
            else if (!mDispatchedFinishedEvent)
            {
                [self DispatchEvent:PATH_EVENT_COMPLETED];
                mDispatchedFinishedEvent = TRUE;
            }
        }
    }
    else if (mType == PATH_TYPE_SPEED)
    {
        if (mLastNodeVisited == ([mNodes count] - 1))
        {               
            if (mPeriodic)
            {
                mLastNodeVisited = 0;
                [self DispatchEvent:PATH_EVENT_CYCLED];
            }
            else if (!mDispatchedFinishedEvent)
            {
                [self DispatchEvent:PATH_EVENT_COMPLETED];
                mDispatchedFinishedEvent = TRUE;
            }
        }
    }
    else
    {
        NSAssert(FALSE, @"Unknown path type");
    }
    
}

-(void)GetValueVec4:(Vector4*)outInterpolatedValue
{
    switch(mType)
    {
        case PATH_TYPE_TIME:
        {
            [self GetValueVec4Time:outInterpolatedValue];
            break;
        }
        
        case PATH_TYPE_SPEED:
        {
            [self GetValueVec4Speed:outInterpolatedValue];
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Trying to get a value for a path that has an unknown type.");
            break;
        }
    }
}

-(void)GetValueVec3:(Vector3*)outInterpolatedValue
{
    Vector4 tempVec;
    
    [self GetValueVec4:&tempVec];
    SetVec3From4(outInterpolatedValue, &tempVec);
}

-(void)GetValueScalar:(float*)outInterpolatedValue
{
    Vector4 tempVec;
    
    [self GetValueVec4:&tempVec];
    
    *outInterpolatedValue = tempVec.mVector[x];
}

-(void)GetValueVec4Time:(Vector4*)outInterpolatedValue
{
    int count = [mNodes count];
    
    if (count == 0)
    {
        SetVec4(outInterpolatedValue, 0.0f, 0.0f, 0.0f, 0.0f);
        return;
    }

    PathNode* lower = NULL;
    PathNode* upper = NULL;
        
    [self GetBoundingNodes:mTime Lower:&lower Upper:&upper];
    
    if (lower == NULL)
    {
        PathNode* first = [mNodes objectAtIndex:0];
        
        if (first == NULL)
        {
            SetVec4(outInterpolatedValue, 0.0f, 0.0f, 0.0f, 0.0f);
        }
        else
        {
            CloneVec4(&first->mValue, outInterpolatedValue);
        }
    }
    else if (upper == NULL)
    {
        PathNode* last = [mNodes objectAtIndex:(count - 1)];
        
        if (last == NULL)
        {
            SetVec4(outInterpolatedValue, 0.0f, 0.0f, 0.0f, 0.0f);
        }
        else
        {
            CloneVec4(&last->mValue, outInterpolatedValue);
        }
    }
    else
    {
        switch(mInterpolationMethod)
        {
            case PATH_INTERPOLATION_LINEAR:
            {
                Vector4 differenceVector;

                Sub4(&upper->mValue, &lower->mValue, &differenceVector);
                Scale4(&differenceVector, (mTime - lower->mTime) / (upper->mTime - lower->mTime));
                Add4(&lower->mValue, &differenceVector, outInterpolatedValue);

                break;
            }
            
            case PATH_INTERPOLATION_BEZIER:
            {
                
                BezierPathNode* bezierPathLower = (BezierPathNode*)lower;
                BezierPathNode* bezierPathUpper = (BezierPathNode*)upper;
                
                float P0X = lower->mTime;
                float P1X = upper->mTime;
                float P0Y = bezierPathLower->mValue.mVector[x];
                float P1Y = bezierPathUpper->mValue.mVector[x];
                float C0X = bezierPathLower->mOutTangent.mVector[x];
                float C1X = bezierPathUpper->mInTangent.mVector[x];
                float C0Y = bezierPathLower->mOutTangent.mVector[y];
                float C1Y = bezierPathUpper->mInTangent.mVector[y];
                
                if (mDebugState)
                {
                    printf("%f, %f\n", P0X, P1X);
                }
                
                float s = ApproximateCubicBezierParameter(mTime, P0X, C0X, C1X, P1X);
                float sSquared = s * s;
                float sCubed = sSquared * s;
                
                float value =   (P0Y * pow((1 - s), 3)) +
                                (3 * C0Y * s * pow((1 - s), 2)) +
                                (3 * C1Y * sSquared * (1 - s) ) +
                                P1Y * sCubed;
                                
                outInterpolatedValue->mVector[x] = value;
                outInterpolatedValue->mVector[y] = value;
                outInterpolatedValue->mVector[z] = value;
                outInterpolatedValue->mVector[w] = value;
                
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"");
                break;
            }
        }
    }
}

-(void)GetValueVec4Speed:(Vector4*)outInterpolatedValue
{
    PathNode* lastNode = [mNodes objectAtIndex:mLastNodeVisited];
    
    int nextNodeIndex = mLastNodeVisited + 1;
    float timeRemaining = mTime - mVisitTime;
    
    while(true)
    {
        PathNode* nextNode = NULL;
        
        if (nextNodeIndex < [mNodes count])
        {
            nextNode = [mNodes objectAtIndex:nextNodeIndex];
        }
        else
        {
            CloneVec4(&lastNode->mValue, outInterpolatedValue);
            break;
        }
        
        Vector4 differenceVector;
        float   totalTime;
        
        Sub4(&nextNode->mValue, &lastNode->mValue, &differenceVector);
        
        totalTime = Length4(&differenceVector) / lastNode->mSpeed;
        
        // If timeRemaining is smaller than totalTime, that means that we
        // fall within these two nodes.  Otherwise advance.
        if (timeRemaining < totalTime)
        {
            Normalize4(&differenceVector);
            Scale4(&differenceVector, lastNode->mSpeed * timeRemaining);
            Add4(&differenceVector, &lastNode->mValue, outInterpolatedValue);
            
            break;
        }
        else
        {
            mLastNodeVisited++;
            mVisitTime += totalTime;
            timeRemaining -= totalTime;
        }
        
        lastNode = nextNode;
        nextNodeIndex++;
    }
    
    if ((!mPeriodic) && (!mDispatchedFinishedEvent) && (mLastNodeVisited == ([mNodes count] - 1)))
    {
        [self DispatchEvent:PATH_EVENT_COMPLETED];
        mDispatchedFinishedEvent = TRUE;
    }
}

-(void)DebugDumpNodes
{
    int count = [mNodes count];
    
    for (int i = 0; i < count; i++)
    {
        PathNode* curNode = [mNodes objectAtIndex:i];
        
        printf("Node %d, time %f, speed %f\n", i, curNode->mTime, curNode->mSpeed);
    }
}

-(BOOL)Finished
{
    if ([mNodes count] == 0)
    {
        return TRUE;
    }
    
    if (mPeriodic)
    {
        return FALSE;
    }
    
    switch(mType)
    {
        case PATH_TYPE_TIME:
        {
            PathNode* last = [mNodes objectAtIndex:([mNodes count] - 1)];
            
            return (mTime >= last->mTime);
        }
        
        case PATH_TYPE_SPEED:
        {
            return (mLastNodeVisited == ([mNodes count] - 1));
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown path type.");
            return TRUE;
        }
    }
}

-(PathState)GetPathState
{
    return mPathState;
}

-(void)GetFinalValue:(Vector4*)outFinalValue
{
    if ([mNodes count] == 0)
    {
        SetVec4(outFinalValue, 0.0, 0.0, 0.0, 1.0);
        return;
    }
    
    PathNode* finalNode = [mNodes objectAtIndex:([mNodes count] - 1)];
    
    CloneVec4(&finalNode->mValue, outFinalValue);
}

-(CFTimeInterval)GetFinalTime
{
    NSAssert(mType == PATH_TYPE_TIME, @"Speed based paths have no concept of a final time");
    
    return mFinalTime;
}

-(CFTimeInterval)GetTimeRemaining
{
    NSAssert(mType == PATH_TYPE_TIME, @"Speed based paths have no concept of time remaining");
    
    return (mFinalTime - mTime);
}

-(void)SetPeriodic:(BOOL)inPeriodic
{
    mPeriodic = inPeriodic;
}

-(BOOL)GetPeriodic
{
    return mPeriodic;
}

-(CFTimeInterval)GetTime
{
    return mTime;
}

-(void)SetTime:(CFTimeInterval)inTime
{
    NSAssert(mType == PATH_TYPE_TIME, @"Speed based paths have no concept of time");
    mTime = inTime;
    
    [self EvaluatePath];
}

-(void)SetCallback:(NSObject<PathCallback>*)inCallback withData:(u32)inUserData
{
    mCallback = inCallback;
    mUserData = inUserData;
}

-(u32)GetUserData
{
    return mUserData;
}

-(void)SetUserData:(u32)inUserData
{
    mUserData = inUserData;
}

-(void)DispatchEvent:(PathEvent)inEvent
{
    if (mCallback != NULL)
    {
        [mCallback PathEvent:inEvent withPath:self userData:mUserData];
    }
}

-(void)AddAction:(PathAction)inAction atTime:(CFTimeInterval)inTime
{
    PathActionNode* newNode = [PathActionNode alloc];
    
    newNode->mAction = inAction;
    newNode->mTime = inTime;
    
    [mActions addObject:newNode];
    [newNode release];
}

-(void)PerformAction:(PathActionNode*)inActionNode
{
    switch(inActionNode->mAction)
    {
        case PATH_ACTION_PAUSE:
        {
            // We could have slightly gone over the pause time.  Eg: Old time was 0.65, timeStep is 0.1, and pause time is 0.7.
            // If we just pause normally, we'll have paused at 0.75 (slightly after the pause time).  So clamp the path's time at the pause time.
            mTime = inActionNode->mTime;
            
            [self Pause];
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown path action");
            break;
        }
    }
}

-(void)SetDebugState:(BOOL)inDebugState
{
    mDebugState = inDebugState;
}

@end