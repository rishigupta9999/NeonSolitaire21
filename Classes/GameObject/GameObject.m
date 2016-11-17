//
//  GameObject.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "GameObject.h"
#import "GameObjectManager.h"
#import "LightManager.h"
#import "GameStateMgr.h"

#define ANIMATION_QUEUE_SIZE    (3)

@implementation GameObjectAnimateNode

-(GameObjectAnimateNode*)Init
{
    mAnimateType = GAMEOBJECT_ANIMATE_INVALID;
    mPropertyType = GAMEOBJECT_PROPERTY_INVALID;
    memset(mData.mData, 0, sizeof(GameObjectAnimateData));
            
    return self;
}

-(void)dealloc
{
    if (mAnimateType == GAMEOBJECT_ANIMATE_PATH)
    {
        [mData.mPath release];
    }
    
    [super dealloc];
}

-(void)SetPropertyType:(GameObjectProperty)inProperty withPath:(Path*)inPath
{
    mAnimateType = GAMEOBJECT_ANIMATE_PATH;
    mPropertyType = inProperty;
    mData.mPath = inPath;
    
    [mData.mPath retain];
}

-(void)SetPropertyType:(GameObjectProperty)inProperty withVector:(Vector3*)inVector
{
    mAnimateType = GAMEOBJECT_ANIMATE_VECTOR;
    mPropertyType = inProperty;
    CloneVec3(inVector, &mData.mVector);
}

@end

@implementation GameObjectAction

@synthesize block = mBlock;
@synthesize queue = mQueue;

-(GameObjectAction*)init
{
    mBlock = NULL;
    mQueue = NULL;
    
    return self;
}

@end

@implementation GameObject

-(void)Init
{
    mOrtho = FALSE;
    mVisible = TRUE;
    mUsesLighting = FALSE;
    mProjected = FALSE;
    
    mLightingType = GAMEOBJECT_LIGHTING_TYPE_ALL;
    mLights = NULL;
    
    mIdentifier = 0;
    mStringIdentifier = NULL;
    mPuppet = NULL;
    
    mGameObjectState = GAMEOBJECT_ALIVE;
    
    mOwningCollection = NULL;
    mGameObjectBatch = NULL;
    
    mRenderBinId = RENDERBIN_BASE;
    
    SetIdentity(&mLTWTransform);
    
    [self SetPositionX:0 Y:0 Z:0];
    [self SetOrientationX:0 Y:0 Z:0];
    [self SetScaleX:1.0 Y:1.0 Z:1.0];
    
    mAlpha = 1.0;
    
    Set(&mPivot, 0.0, 0.0, 0.0);
    
    for (int i = 0; i < GAMEOBJECT_PROPERTY_NUM; i++)
    {
        mAnimationList[i] = [[NSMutableArray alloc] initWithCapacity:ANIMATION_QUEUE_SIZE];
    }
    
    mActionList = [[NSMutableArray alloc] initWithCapacity:0];
    
    mUserData = 0;
    
    mTimeStepType = GAMEOBJECT_TIMESTEP_VARIABLE;
    
    mOwningState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];
}

-(void)dealloc
{
    for (int i = 0; i < GAMEOBJECT_PROPERTY_NUM; i++)
    {
        [mAnimationList[i] release];
        mAnimationList[i] = 0;
    }
    
    [mActionList release];
    
    [mStringIdentifier release];
    [mLights release];
    
    [super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    BOOL didWork = FALSE;
    
    for (int curProperty = 0; curProperty < GAMEOBJECT_PROPERTY_NUM; curProperty++)
    {
        NSMutableArray* curArray = mAnimationList[curProperty];
        
        if ([curArray count] > 0)
        {
            didWork = TRUE;
            break;
        }
    }
    
    if (!didWork)
    {
        if (mGameObjectState == GAMEOBJECT_DELETE_AFTER_OPERATIONS)
        {
            mGameObjectState = GAMEOBJECT_COMPLETED;
            [self Remove];
        }
        else
        {
            if ([mActionList count] > 0)
            {
                for (GameObjectAction* action in mActionList)
                {
                    dispatch_async(action.queue, action.block);
                    Block_release(action.block);
                }
                
                [mActionList removeAllObjects];
            }
        }
    }
    
    for (int curProperty = 0; curProperty < GAMEOBJECT_PROPERTY_NUM; curProperty++)
    {
        NSMutableArray* curArray = mAnimationList[curProperty];
        
        if ([curArray count] > 0)
        {
            GameObjectAnimateNode* curNode = [curArray objectAtIndex:0];
            
            switch(curNode->mPropertyType)
            {
                case GAMEOBJECT_PROPERTY_POSITION:
                {
                    switch(curNode->mAnimateType)
                    {
                        case GAMEOBJECT_ANIMATE_PATH:
                        {
                            [curNode->mData.mPath GetValueVec3:&mPosition];
                            
                            if ([curNode->mData.mPath Finished])
                            {
                                [curArray removeObject:curNode];
                            }
                            else
                            {
                                [curNode->mData.mPath Update:inTimeStep];
                            }
                            
                            break;
                        }
                        
                        case GAMEOBJECT_ANIMATE_VECTOR:
                        {
                            CloneVec3(&curNode->mData.mVector, &mPosition);
                            [curArray removeObject:curNode];
                            
                            break;
                        }
                    }
                    
                    break;
                }
                
                case GAMEOBJECT_PROPERTY_ORIENTATION:
                {
                    switch(curNode->mAnimateType)
                    {
                        case GAMEOBJECT_ANIMATE_PATH:
                        {
                            [curNode->mData.mPath GetValueVec3:&mOrientation];
                            
                            if ([curNode->mData.mPath Finished])
                            {
                                [curArray removeObject:curNode];
                            }
                            else
                            {
                                [curNode->mData.mPath Update:inTimeStep];
                            }
                            
                            break;
                        }
                        
                        case GAMEOBJECT_ANIMATE_VECTOR:
                        {
                            CloneVec3(&curNode->mData.mVector, &mOrientation);
                            [curArray removeObject:curNode];
                            
                            break;
                        }
                    }
                    
                    break;
                }
                
                case GAMEOBJECT_PROPERTY_SCALE:
                {
                    switch(curNode->mAnimateType)
                    {
                        case GAMEOBJECT_ANIMATE_PATH:
                        {
                            [curNode->mData.mPath GetValueVec3:&mScale];
                            
                            if ([curNode->mData.mPath Finished])
                            {
                                [curArray removeObject:curNode];
                            }
                            else
                            {
                                [curNode->mData.mPath Update:inTimeStep];
                            }
                            
                            break;
                        }
                        
                        case GAMEOBJECT_ANIMATE_VECTOR:
                        {
                            CloneVec3(&curNode->mData.mVector, &mScale);
                            [curArray removeObject:curNode];
                            
                            break;
                        }
                    }
                    
                    break;
                }
                
                case GAMEOBJECT_PROPERTY_ALPHA:
                {
                    switch(curNode->mAnimateType)
                    {
                        case GAMEOBJECT_ANIMATE_PATH:
                        {
                            [curNode->mData.mPath GetValueScalar:&mAlpha];
                            
                            Vector4 finalValue;
                            
                            [curNode->mData.mPath GetFinalValue:&finalValue];
                            
                            if ([curNode->mData.mPath Finished])
                            {
                                [curArray removeObject:curNode];
                            }
                            else
                            {
                                [curNode->mData.mPath Update:inTimeStep];
                            }
                            
                            break;
                        }
                        
                        case GAMEOBJECT_ANIMATE_VECTOR:
                        {
                            mAlpha = curNode->mData.mVector.mVector[x];
                            [curArray removeObject:curNode];
                            
                            break;
                        }
                    }

                    break;
                }
                
                default:
                {
                    NSAssert(FALSE, @"Unrecognized property type");
                    break;
                }
            }
        }
    }
    
    if (mPuppet != NULL)
    {
        [mPuppet Update:inTimeStep];
    }
}

-(void)Draw
{
    if (mAlpha != 0.0f)
    {
        if (mAlpha != 1.0f)
        {
            ModelRenderState renderState;
            [Model InitDefaultRenderState:&renderState];
            
            SetVec4(&renderState.mColor, 1.0f, 1.0f, 1.0f, mAlpha);
            
            [mPuppet SetRenderStateOverride:&renderState];
        }
        else
        {
            [mPuppet ClearRenderStateOverride];
        }
        
        [mPuppet Draw];
    }
}

-(void)DrawOrtho
{
    [mPuppet Draw];
}

-(void)DrawBoundingBox
{
    Box objectSpaceBox;
    
    BOOL validBox = [self GetObjectSpaceBoundingBox:&objectSpaceBox];
    
    if (validBox)
    {
        // 8 vertexes * 3 coordinates per vertex
        float vertexArray[24];
        
        for (int i = 0; i < 8; i++)
        {
            vertexArray[i * 3] = objectSpaceBox.mVertices[i].mVector[x];
            vertexArray[(i * 3) + 1] = objectSpaceBox.mVertices[i].mVector[y];
            vertexArray[(i * 3) + 2] = objectSpaceBox.mVertices[i].mVector[z];
        }
        
        // 8 vertex * 4 components per color
        float colorArray[32];
        
        for (int i = 0; i < 32; i++)
        {
            colorArray[i] = 1.0f;
        }
        
        u16 topIndices[8] = { 0, 1, 2, 3};
        u16 bottomIndices[8] = {4, 5, 6, 7};

        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_COLOR_ARRAY);
        
        glVertexPointer(3, GL_FLOAT, 0, vertexArray);
        glColorPointer(4, GL_FLOAT, 0, colorArray);
        
        // Draw top loop
        glDrawElements(GL_LINE_LOOP, 4, GL_UNSIGNED_SHORT, topIndices);
        
        // Draw bottom loop
        glDrawElements(GL_LINE_LOOP, 4, GL_UNSIGNED_SHORT, bottomIndices);
        
        // Connect the two loops
        u16 connectIndices[2];
        
        for (int i = 0; i < 4; i++)
        {
            connectIndices[0] = topIndices[i];
            connectIndices[1] = bottomIndices[i];
            
            glDrawElements(GL_LINE_LOOP, 2, GL_UNSIGNED_SHORT, connectIndices);
        }
        
        glDisableClientState(GL_VERTEX_ARRAY);
        glDisableClientState(GL_COLOR_ARRAY);

    }
}

+(void)InitDefaultRenderStateParams:(RenderStateParams*)outParams
{
    outParams->mRenderPassType = RENDER_PASS_NORMAL;
}

-(void)SetupRenderState:(RenderStateParams*)inParams
{
    if (mUsesLighting)
    {
#if USE_LIGHTING
        NeonGLEnable(GL_LIGHTING);
        
        switch([self GetLightingType])
        {
            case GAMEOBJECT_LIGHTING_TYPE_ALL:
            {
                [[LightManager GetInstance] EnableAllLights];
                break;
            }
            
            case GAMEOBJECT_LIGHTING_TYPE_LIST:
            {
                [[LightManager GetInstance] EnableLights:[self GetAffectingLights]];
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown lighting type");
                break;
            }
        }
#endif
    }
}

-(void)TeardownRenderState:(RenderStateParams*)inParams
{
    if (mUsesLighting)
    {
        NeonGLDisable(GL_LIGHTING);
    }
}

-(BOOL)GetWorldSpaceBoundingBox:(Box*)outBox
{
    BOOL validBox = FALSE;
    
    if ([self GetPuppet] != NULL)
    {
        validBox = TRUE;
        
        // Generate an axis aligned box in model's local space.
        BoxFromBoundingBox(&([self GetPuppet]->mBoundingBox), outBox);

        Matrix44 ltwTransform;
        
        [self GetLocalToWorldTransform:&ltwTransform];
        
        // Transform to world space
        
        for (int curVert = 0; curVert < 8; curVert++)
        {
            Vector4 destVector;
            TransformVector4x3(&ltwTransform, &outBox->mVertices[curVert], &destVector);
            SetVec3From4(&outBox->mVertices[curVert], &destVector);
        }
    }
    
    return validBox;
}

-(BOOL)GetObjectSpaceBoundingBox:(Box*)outBox
{
    BOOL validBox = FALSE;
    
    if (mPuppet != NULL)
    {
        validBox = TRUE;
        
        // Generate an axis aligned box in model's local space.
        BoxFromBoundingBox(&mPuppet->mBoundingBox, outBox);
    }
    
    return validBox;
}

-(void)GetLocalToWorldTransform:(Matrix44*)outTransform
{
    Matrix44 translate, negativePivot, pivot;
    Matrix44 rotateX, rotateY, rotateZ;
    Matrix44 scale;
    Matrix44 netTransform;
    
    GenerateTranslationMatrix(  mPosition.mVector[x],
                                mPosition.mVector[y],
                                mPosition.mVector[z],
                                &translate );
                                
    GenerateTranslationMatrix(  mPivot.mVector[x],
                                mPivot.mVector[y],
                                mPivot.mVector[z],
                                &pivot );

                                
    GenerateTranslationMatrix(  -mPivot.mVector[x],
                                -mPivot.mVector[y],
                                -mPivot.mVector[z],
                                &negativePivot );
                                
    GenerateScaleMatrix(mScale.mVector[x], mScale.mVector[y], mScale.mVector[z], &scale);
    
    GenerateRotationMatrix(mOrientation.mVector[x], 1.0f, 0.0f, 0.0f, &rotateX);
    GenerateRotationMatrix(mOrientation.mVector[y], 0.0f, 1.0f, 0.0f, &rotateY);
    GenerateRotationMatrix(mOrientation.mVector[z], 0.0f, 0.0f, 1.0f, &rotateZ);
    
    SetIdentity(&netTransform);
    
    MatrixMultiply(&netTransform, &mLTWTransform, &netTransform);
    MatrixMultiply(&netTransform, &translate, &netTransform);
    MatrixMultiply(&netTransform, &pivot, &netTransform);
    MatrixMultiply(&netTransform, &scale, &netTransform);
    MatrixMultiply(&netTransform, &rotateX, &netTransform);
    MatrixMultiply(&netTransform, &rotateY, &netTransform);
    MatrixMultiply(&netTransform, &rotateZ, &netTransform);
    MatrixMultiply(&netTransform, &negativePivot, &netTransform);

    CloneMatrix44(&netTransform, outTransform);
}

-(void)TransformLocalToWorld:(Vector3*)inVec result:(Vector3*)outVec
{
    Matrix44 ltwTransform;
    
    [self GetLocalToWorldTransform:&ltwTransform];
    
    Vector4 vec4Result;
    TransformVector4x3(&ltwTransform, inVec, &vec4Result);
    SetVec3From4(outVec, &vec4Result);
}

-(int)GetRenderBinId
{
    return mRenderBinId;
}

-(BOOL)GetVisible
{
    return mVisible;
}

-(void)SetVisible:(BOOL)inVisible
{
    mVisible = inVisible;
}

-(BOOL)GetProjected
{
    return mProjected;
}

-(void)SetProjected:(BOOL)inProjected
{
    mProjected = inProjected;
}

-(void)SetPosition:(Vector3*)inPosition
{
    [self SetProperty:GAMEOBJECT_PROPERTY_POSITION withVector:inPosition];
}

-(void)SetPositionX:(float)inX Y:(float)inY Z:(float)inZ
{
    Vector3 position;
    
    Set(&position, inX, inY, inZ);
    
    [self SetProperty:GAMEOBJECT_PROPERTY_POSITION withVector:&position];
}

-(void)SetOrientation:(Vector3*)inOrientation
{
    [self SetProperty:GAMEOBJECT_PROPERTY_ORIENTATION withVector:inOrientation];
}

-(void)SetOrientationX:(float)inX Y:(float)inY Z:(float)inZ
{
    Vector3 orientation;
    
    Set(&orientation, inX, inY, inZ);
    
    [self SetProperty:GAMEOBJECT_PROPERTY_ORIENTATION withVector:&orientation];
}

-(void)GetPosition:(Vector3*)outPosition
{
    [self GetProperty:GAMEOBJECT_PROPERTY_POSITION withVector:outPosition];
}

-(void)GetPositionWorld:(Vector3*)outPosition current:(BOOL)inCurrent
{
    Vector3 intermediate;
    
    if (inCurrent)
    {
        [self GetPropertyCurrent:GAMEOBJECT_PROPERTY_POSITION withVector:&intermediate];
    }
    else
    {
        [self GetProperty:GAMEOBJECT_PROPERTY_POSITION withVector:&intermediate];
    }
    
    Vector4 result;
    TransformVector4x3(&mLTWTransform, &intermediate, &result);
    
    SetVec3From4(outPosition, &result);
}

-(void)GetOrientation:(Vector3*)outOrientation
{
    [self GetProperty:GAMEOBJECT_PROPERTY_ORIENTATION withVector:outOrientation];
}

-(void)SetScale:(Vector3*)inScale
{
    [self SetProperty:GAMEOBJECT_PROPERTY_SCALE withVector:inScale];
}

-(void)SetScaleX:(float)inX Y:(float)inY Z:(float)inZ	// KK - GAMEOBJECT_PROPERTY_SCALE to scale the card.
{
    Vector3 scale;
    
    Set(&scale, inX, inY, inZ);
    
    [self SetProperty:GAMEOBJECT_PROPERTY_SCALE withVector:&scale];
}

-(void)GetScale:(Vector3*)outScale
{
    [self GetProperty:GAMEOBJECT_PROPERTY_SCALE withVector:outScale];
}

-(void)SetAlpha:(float)inAlpha
{
    Vector3 alpha;
    
    Set(&alpha, inAlpha, inAlpha, inAlpha);
    
    [self SetProperty:GAMEOBJECT_PROPERTY_ALPHA withVector:&alpha];
}

-(void)GetAlpha:(float*)outAlpha
{
    Vector3 alpha;
    
    [self GetProperty:GAMEOBJECT_PROPERTY_ALPHA withVector:&alpha];
    
    *outAlpha = alpha.mVector[x];
}

-(float)GetAlpha
{
    float retAlpha;
    
    [self GetAlpha:&retAlpha];
    
    return retAlpha;
}

-(void)GetProperty:(GameObjectProperty)inProperty withVector:(Vector3*)outValue
{
    NSAssert(((inProperty >= 0) && (inProperty < GAMEOBJECT_PROPERTY_INVALID)), @"Property type is invalid");
    
    NSMutableArray* array = mAnimationList[inProperty];
    
    if ([array count] > 0)
    {
        GameObjectAnimateNode* node = [array objectAtIndex:([array count] - 1)];
        
        switch(node->mAnimateType)
        {
            case GAMEOBJECT_ANIMATE_PATH:
            {
                Vector4 finalValue;
                
                [node->mData.mPath GetFinalValue:&finalValue];
                
                Set(outValue, finalValue.mVector[x], finalValue.mVector[y], finalValue.mVector[z]);
                break;
            }
            
            case GAMEOBJECT_ANIMATE_VECTOR:
            {
                CloneVec3(&node->mData.mVector, outValue);
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown animate type.  An animation node must not have been added through the correct mechanisms.");
                break;
            }
        }
    }
    else
    {
        [self GetPropertyCurrent:inProperty withVector:outValue];
    }
}

-(void)GetPropertyCurrent:(GameObjectProperty)inProperty withVector:(Vector3*)outValue
{
    switch(inProperty)
    {
        case GAMEOBJECT_PROPERTY_POSITION:
        {
            CloneVec3(&mPosition, outValue);
            break;
        }
        
        case GAMEOBJECT_PROPERTY_ORIENTATION:
        {
            CloneVec3(&mOrientation, outValue);
            break;
        }
        
        case GAMEOBJECT_PROPERTY_SCALE:
        {
            CloneVec3(&mScale, outValue);
            break;
        }
        
        case GAMEOBJECT_PROPERTY_ALPHA:
        {
            Set(outValue, mAlpha, mAlpha, mAlpha);
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown property type.");
            break;
        }
    }
}

-(void)AnimateProperty:(GameObjectProperty)inProperty withPath:(Path*)inPath
{
    NSAssert(inPath != NULL, @"Attempting to animate with a NULL path");
    [self AnimateProperty:inProperty withPath:inPath replace:FALSE];
}

-(void)AnimateProperty:(GameObjectProperty)inProperty withPath:(Path*)inPath replace:(BOOL)inReplace
{
    NSAssert(((inProperty >= 0) && (inProperty < GAMEOBJECT_PROPERTY_NUM)), @"Invalid property specified");
    
    GameObjectAnimateNode* newNode = [(GameObjectAnimateNode*)[GameObjectAnimateNode alloc] Init];
    
    [newNode SetPropertyType:inProperty withPath:inPath];
    
    if (inReplace)
    {
        [mAnimationList[inProperty] removeAllObjects];
    }
    
    [mAnimationList[inProperty] addObject:newNode];
    [newNode release];
}

-(BOOL)PropertyIsAnimating:(GameObjectProperty)inProperty
{
    int numAnimations = [mAnimationList[inProperty] count];
    
    for (int i = 0; i < numAnimations; i++)
    {
        GameObjectAnimateNode* animationNode = [mAnimationList[inProperty] objectAtIndex:i];
        
        if (animationNode->mAnimateType == GAMEOBJECT_ANIMATE_PATH)
        {
            Path* path = animationNode->mData.mPath;
            
            if ([path GetPeriodic])
            {
                continue;
            }
            
            return TRUE;
        }
        
        return TRUE;
    }
    
    return FALSE;
}

-(BOOL)AnyPropertyIsAnimating
{
    BOOL retVal = FALSE;
    
    for (int curProperty = 0; curProperty < GAMEOBJECT_PROPERTY_NUM; curProperty++)
    {
        if ([self PropertyIsAnimating:curProperty])
        {
            retVal = TRUE;
            break;
        }
    }
    
    return retVal;
}

-(void)CancelAnimationForProperty:(GameObjectProperty)inProperty
{
    [mAnimationList[inProperty] removeAllObjects];
}

-(void)SetProperty:(GameObjectProperty)inProperty withVector:(Vector3*)inVector
{
    NSAssert(((inProperty >= 0) && (inProperty < GAMEOBJECT_PROPERTY_NUM)), @"Invalid property specified");

    // If this object isn't animation, set the property directly and get out.  Otherwise we'll need to queue an operation.
    if ([mAnimationList[inProperty] count] == 0)
    {
        switch(inProperty)
        {
            case GAMEOBJECT_PROPERTY_POSITION:
            {
                CloneVec3(inVector, &mPosition);
                break;
            }
            
            case GAMEOBJECT_PROPERTY_ORIENTATION:
            {   
                CloneVec3(inVector, &mOrientation);
                break;
            }
            
            case GAMEOBJECT_PROPERTY_SCALE:
            {
                CloneVec3(inVector, &mScale);
                break;
            }
            
            case GAMEOBJECT_PROPERTY_ALPHA:
            {
                mAlpha = inVector->mVector[x];
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown property");
                break;
            }
        }
    }
    else
    {
        GameObjectAnimateNode* newNode = [(GameObjectAnimateNode*)[GameObjectAnimateNode alloc] Init];
        
        [newNode SetPropertyType:inProperty withVector:inVector];
        
        [mAnimationList[inProperty] addObject:newNode];
        [newNode release];
    }
}

-(GameObject*)RemoveAfterOperations
{
    mGameObjectState = GAMEOBJECT_DELETE_AFTER_OPERATIONS;
    
    return self;
}

-(GameObject*)Remove
{
    NSAssert(mGameObjectState != GAMEOBJECT_DELETE_AFTER_OPERATIONS, @"Object being removed during animation");

    [mOwningCollection Remove:self];
    
    return self;
}

-(void)SetOwningCollection:(GameObjectCollection*)inCollection
{
    if (inCollection != NULL)
    {
        NSAssert(mOwningCollection == NULL, @"A game object can't belong to more than one collection");
    }
    
    mOwningCollection = inCollection;
}

-(GameObjectCollection*)GetOwningCollection
{
    return mOwningCollection;
}

-(void)SetUserData:(u32)inUserData
{
    mUserData = inUserData;
}

-(u32)GetUserData
{
    return mUserData;
}

-(void)SetStringIdentifier:(NSString*)inIdentifier
{
    [mStringIdentifier release];
    mStringIdentifier = inIdentifier;
    [mStringIdentifier retain];
}

-(NSString*)GetStringIdentifier
{
    return mStringIdentifier;
}

-(void)SetLightingType:(GameObjectLightingType)inLightingType
{
    if (inLightingType != mLightingType)
    {
        switch(inLightingType)
        {
            case GAMEOBJECT_LIGHTING_TYPE_ALL:
            {
                [mLights release];
                mLights = NULL;
                break;
            }
            
            case GAMEOBJECT_LIGHTING_TYPE_LIST:
            {
                mLights = [[NSMutableArray alloc] initWithCapacity:NUM_OPENGL_LIGHTS];
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown lighting type");
            }
        }
        
        mLightingType = inLightingType;
    }
}

-(GameObjectLightingType)GetLightingType
{
    return mLightingType;
}

-(void)AddAffectingLight:(Light*)inLight
{
    NSAssert(mLightingType == GAMEOBJECT_LIGHTING_TYPE_LIST, @"Only make sense to call this when the lighting type is GAMEOBJECT_LIGHTING_TYPE_LIST");
    
    [mLights addObject:inLight];
}

-(void)RemoveAffectingLight:(Light*)inLight
{
    if (mLightingType == GAMEOBJECT_LIGHTING_TYPE_LIST)
    {
        for (Light* curLight in mLights)
        {
            if (curLight == inLight)
            {
                [mLights removeObject:curLight];
                break;
            }
        }
    }
}

-(NSMutableArray*)GetAffectingLights
{
    return mLights;
}

-(void)SetGameObjectBatch:(GameObjectBatch*)inGameObjectBatch
{
    [mGameObjectBatch release];
    mGameObjectBatch = inGameObjectBatch;
    [mGameObjectBatch retain];
}

-(GameObjectBatch*)GetGameObjectBatch
{
    return mGameObjectBatch;
}

-(GameState*)GetOwningState
{
    return mOwningState;
}

-(Model*)GetPuppet
{
    return mPuppet;
}

-(void)PerformAfterOperationsInQueue:(dispatch_queue_t)inQueue block:(dispatch_block_t)inBlock
{
    GameObjectAction* newAction = [[GameObjectAction alloc] init];
    
    newAction.block = Block_copy(inBlock);
    newAction.queue = inQueue;
    
    [mActionList addObject:newAction];
    [newAction autorelease];
}

@end