//
//  CompanionEntity.m
//  Neon21
//
//  Copyright 2010 Neon Games. All rights reserved.
//

#import "GameStateMgr.h"

#import "CompanionEntity.h"
#import "CompanionRenderManager.h"
#import "ModelManager.h"
#import "Model.h"
#import "ResourceManager.h"
#import "TextureManager.h"

#import "AnimationController.h"
#import "Animation.h"
#import "AnimationTransformer.h"

static const char* sCompanionAnimations[COMPANION_ANIMATION_NUM] = {    "CompanionIdle.ANIM",
                                                                        "CompanionFatIdle.ANIM",
                                                                        "CompanionHappy.ANIM",
                                                                        "CompanionHappyBig.ANIM",
                                                                        "CompanionSad.ANIM",
                                                                        "CompanionWalk.ANIM" };
																		
static const char* sCompanionAbilityAnimations[CompID_MAX] = {			"NULL",
																		"CompanionHappy.ANIM",
																		"AmberAction.ANIM",
																		"BettyAction.ANIM",
																		"CathyAction.ANIM",
																		"JohnnyAction.ANIM",
																		"PandaAction.ANIM",
																		"VutAction.ANIM",
																		"IgunaqAction.ANIM",
																		"CappoAction.ANIM" };
                                                                        
#define COMPANION_ANIMATION_TRANSITION_TIME (0.5f)
#define COMPANION_GLOW_PEAK_INTENSITY       (0.5f)
#define COMPANION_GLOW_SPEED                (3.0f)

@implementation CompanionEntity

-(CompanionEntity*)InitWithCompanionID:(CompanionID)inCompanionID position:(CompanionPosition)inPosition
{
    [super Init];
    
    [[(GameState*)[[GameStateMgr GetInstance] GetActiveState] GetMessageChannel] AddListener:self];
    [GetGlobalMessageChannel() AddListener:self];

    mCompanionID = inCompanionID;
    mCompanionPosition = inPosition;
    
    mRenderBinId = RENDERBIN_COMPANIONS;
    
    CompanionRenderInfo* renderInfo = [[CompanionRenderManager GetInstance] getCompanionRenderInfo:mCompanionID];
    
    Vector3 companionPosition;
    Vector3 companionOrientation;
    
    [[CompanionRenderManager GetInstance] getCompanionPlacement:inPosition forId:inCompanionID position:&companionPosition orientation:&companionOrientation];
    
    mPuppet = [[ModelManager GetInstance] ModelWithName:[NSString stringWithUTF8String:renderInfo->mModelFilename] owner:self];
    [mPuppet BindSkeletonWithFilename:[NSString stringWithUTF8String:renderInfo->mSkeletonFilename]];
    [mPuppet retain];
    
    TextureParams textureParams;
    [Texture InitDefaultParams:&textureParams];
    
    textureParams.mTexDataLifetime = TEX_DATA_DISPOSE;
    Texture* companionTexture = [[TextureManager GetInstance] TextureWithName:[NSString stringWithUTF8String:renderInfo->mTextureFilename]
                                                              textureParams:&textureParams];
                                                              
    [mPuppet SetTexture:companionTexture];
        
    [self SetPosition:&companionPosition];
    [self SetOrientation:&companionOrientation];
    
    [self SetScaleX:renderInfo->mScale Y:renderInfo->mScale Z:renderInfo->mScale];
    
    Plane clipPlane;
    [[CompanionRenderManager GetInstance] getCompanionClipPlane:&clipPlane forId:inCompanionID];
    
    if (fabsf(clipPlane.mDistance) > EPSILON)
    {
        [mPuppet SetClipPlaneEnabled:TRUE];
        [mPuppet SetClipPlane:&clipPlane];
    }
    
    mUsesLighting = TRUE;
    
    mAnimationController = NULL;
    mCompanionState = COMPANION_STATE_INVALID;
    
    [self InitAnimation];
    
    mGlowPath = [(Path*)[Path alloc] Init];
    mGlowState = COMPANION_GLOW_OFF;
    
    mPulseState = COMPANION_PULSE_OFF;
    mNumPulses = 0;
    
    return self;
}

-(void)ReinitWithPosition:(CompanionPosition)inPosition
{    
    mCompanionPosition = inPosition;

    Vector3 companionPosition;
    Vector3 companionOrientation;
    
    [[CompanionRenderManager GetInstance] getCompanionPlacement:inPosition forId:mCompanionID position:&companionPosition orientation:&companionOrientation];
    
    [self SetPosition:&companionPosition];
    [self SetOrientation:&companionOrientation];
}

-(void)dealloc
{
    [mAnimationController release];
    [mPuppet release];
    mPuppet = NULL;
    
    [mGlowPath release];
    
    [super dealloc];
}

-(void)Remove
{
    [[(GameState*)[[GameStateMgr GetInstance] GetActiveState] GetMessageChannel] RemoveListener:self];
    [GetGlobalMessageChannel() RemoveListener:self];
    
    [super Remove];
}

-(void)InitAnimation
{
    Skeleton* skeleton = [mPuppet GetSkeleton];
    
    mAnimationController = [(AnimationController*)[AnimationController alloc] InitWithSkeleton:skeleton];
    
    NSNumber* testAnimHandle = NULL;
    
    Companion** companionArray = [CompanionManager GetCompanionInfoArray];

    switch(companionArray[mCompanionID]->companionSize)
    {
        case COMPANION_SIZE_NORMAL:
        {
            testAnimHandle = [[ResourceManager GetInstance] LoadAssetWithName:[self GetAnimationFilename:COMPANION_ANIMATION_IDLE]];
            break;
        }
        
        case COMPANION_SIZE_FAT:
        {
            testAnimHandle = [[ResourceManager GetInstance] LoadAssetWithName:[self GetAnimationFilename:COMPANION_ANIMATION_FAT_IDLE]];
            break;
        }
    }
    
    NSData* animData = [[ResourceManager GetInstance] GetDataForHandle:testAnimHandle];
    
    AnimationTransitionParams animationTransitionParams;
    [AnimationController InitDefaultTransitionParams:&animationTransitionParams];
    
    animationTransitionParams.mTransitionToTime = 0.0f;
    animationTransitionParams.mLoop = TRUE;
    
    [mAnimationController SetTargetAnimationClipData:animData params:&animationTransitionParams];
    
    AnimationClip* curClip = [mAnimationController GetActiveAnimationClip];
    float clipDuration = [curClip GetDuration];
    float startTime = RandFloat(0.0f, clipDuration);
    
    AnimationClip_SetTime(curClip, startTime);
    
    [[ResourceManager GetInstance] UnloadAssetWithHandle:testAnimHandle];
    
    mCompanionState = COMPANION_STATE_IDLE;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if ((mGlowState == COMPANION_GLOW_TRANSITION_ON) || (mGlowState == COMPANION_GLOW_TRANSITION_OFF))
    {
        [mGlowPath Update:inTimeStep];
        [mGlowPath GetValueScalar:&mPuppet->mGlowAmount];
        
        if ([mGlowPath Finished])
        {
            switch (mGlowState)
            {
                case COMPANION_GLOW_TRANSITION_OFF:
                {
                    mGlowState = COMPANION_GLOW_OFF;
                    [mPuppet SetGlowEnabled:FALSE];
                    
                    if (mPulseState == COMPANION_PULSE_ON)
                    {
                        mNumPulses--;
                        
                        if (mNumPulses == 0.0f)
                        {
                            mPulseState = COMPANION_PULSE_OFF;
                        }
                        else
                        {
                            [self SetGlowEnabled:TRUE];
                        }
                    }
                    
                    break;
                }
                
                case COMPANION_GLOW_TRANSITION_ON:
                {
                    if (mPulseState == COMPANION_PULSE_ON)
                    {
                        [self SetGlowEnabled:FALSE];
                    }
                    else
                    {
                        mGlowState = COMPANION_GLOW_ON;
                    }
                    
                    break;
                }
                
                default:
                {
                    break;
                }
            }
        }
    }
    
    [mAnimationController Update:inTimeStep];
    [super Update:inTimeStep];
    
    if ([mAnimationController StackDepth] == 0)
    {
        if ([mAnimationController GetBlendMode] == ANIMATION_CONTROLLER_BLEND_LEFT)
        {
            mCompanionState = COMPANION_STATE_IDLE;
        }
    }
}

-(NSString*)GetAnimationFilename:(CompanionAnimationType)inAnimationType
{
    NSAssert((inAnimationType >= 0) && (inAnimationType < COMPANION_ANIMATION_NUM), @"Invalid animation type specified");
    return [NSString stringWithUTF8String:sCompanionAnimations[inAnimationType]];
}

-(NSString*)GetAbilityAnimationFilename
{
	NSAssert((mCompanionID > 0) && (mCompanionID < CompID_MAX), @"Invalid companion ID");
	return [NSString stringWithUTF8String:sCompanionAbilityAnimations[mCompanionID]];
}

-(void)ProcessMessage:(Message*)inMsg
{
    CompanionAnimationType newAnim  = COMPANION_ANIMATION_INVALID;
    NSString* newAnimFilename       = NULL;
    Flow *gameFlow                  = [Flow GetInstance];

    switch(inMsg->mId)
    {
        case EVENT_CONCLUSION_BANKRUPT:
        {
            if ( [gameFlow IsInRun21] )
            {
                switch(mCompanionPosition)
                {                    
                    case COMPANION_POSITION_PLAYER:
                    {
                        newAnim = COMPANION_ANIMATION_SAD;
                        break;
                    }
                }
            }
            
            break;
        }
        
        case EVENT_CONCLUSION_BROKETHEBANK:
        {
            switch(mCompanionPosition)
            {
                case COMPANION_POSITION_PLAYER:
                {
                    if ( [gameFlow IsInRun21] || [gameFlow IsInRainbow])
                    {
                        newAnim = COMPANION_ANIMATION_BIG_HAPPY;
                    }                
                    break;
                }
            }
            
            break;
        }
        
        case EVENT_RUN21_BUST:
        {
            // Dealer doesn't react in tutorial or marathon mode
            if ([[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21)
            {
                switch(mCompanionPosition)
                {                    
                    case COMPANION_POSITION_DEALER:
                    {
                        newAnimFilename = [self GetAbilityAnimationFilename];
                        break;
                    }
                }
            }
            
            break;
        }
        
        case EVENT_RUN21_CHARLIE:
        {
            if ( [gameFlow IsInRun21] )
            {
                switch(mCompanionPosition)
                {                    
                    case COMPANION_POSITION_PLAYER:
                    {
                        newAnim = COMPANION_ANIMATION_HAPPY;
                        break;
                    }
                }
            }
            
            break;
        }
            
        //Begin Rainbow Events
        case EVENT_RAINBOW_ROUND_LOSE:
        {
            switch (mCompanionPosition)
            {
                case COMPANION_POSITION_DEALER:
                {
                    newAnim = COMPANION_ANIMATION_HAPPY;
                    break;
                }
                case COMPANION_POSITION_PLAYER:
                {
                    newAnim = COMPANION_ANIMATION_SAD;
                    break;
                }
            }
            break;
        }
        case EVENT_RAINBOW_ROUND_WIN:
        {
            switch (mCompanionPosition)
            {
                case COMPANION_POSITION_DEALER:
                {
                    newAnim = COMPANION_ANIMATION_SAD;
                    break;
                }
                case COMPANION_POSITION_PLAYER:
                {
                    newAnim = COMPANION_ANIMATION_HAPPY;
                    break;
                }
            }
            break;
        }
        case EVENT_RAINBOW_ROUND_PUSH:
        {
            newAnim = COMPANION_ANIMATION_SAD;
            break;
        }
        case EVENT_RAINBOW_GAME_LOSE:
        {
            switch(mCompanionPosition)
            {
                case COMPANION_POSITION_PLAYER:
                {
                    newAnim = COMPANION_ANIMATION_SAD;
                    break;
                }
            }
            break;
        }
    }
    
    if ((newAnim != COMPANION_ANIMATION_INVALID) || (newAnimFilename != NULL))
    {
        NSString* filename = (newAnimFilename != NULL) ? (newAnimFilename) : ([self GetAnimationFilename:newAnim]);
        NSNumber* testAnimHandle = [[ResourceManager GetInstance] LoadAssetWithName:filename];
        NSData* animData = [[ResourceManager GetInstance] GetDataForHandle:testAnimHandle];

        AnimationTransitionParams animationTransitionParams;
        [AnimationController InitDefaultTransitionParams:&animationTransitionParams];
        
        animationTransitionParams.mTransitionToTime = COMPANION_ANIMATION_TRANSITION_TIME;
        animationTransitionParams.mTransitionFromTime = COMPANION_ANIMATION_TRANSITION_TIME;
        animationTransitionParams.mLoop = FALSE;
        
        [mAnimationController PushTargetAnimationClipData:animData params:&animationTransitionParams];
        
        [[ResourceManager GetInstance] UnloadAssetWithHandle:testAnimHandle];
        
        mCompanionState = COMPANION_STATE_OTHER;
    }
}

-(void)PerformAction:(CompanionAction)inAction
{
    switch(inAction)
    {
        case COMPANION_ACTION_WALK_FROM_TABLE_LEFT:
        {
            NSNumber* testAnimHandle = [[ResourceManager GetInstance] LoadAssetWithName:[self GetAnimationFilename:COMPANION_ANIMATION_WALK]];
            NSData* animData = [[ResourceManager GetInstance] GetDataForHandle:testAnimHandle];
        
            AnimationTransitionParams animationTransitionParams;
            [AnimationController InitDefaultTransitionParams:&animationTransitionParams];
            
            animationTransitionParams.mTransitionToTime = COMPANION_ANIMATION_TRANSITION_TIME;
            animationTransitionParams.mTransitionFromTime = COMPANION_ANIMATION_TRANSITION_TIME;
            animationTransitionParams.mLoop = FALSE;
            
            [mAnimationController PushTargetAnimationClipData:animData params:&animationTransitionParams];
            
            [[ResourceManager GetInstance] UnloadAssetWithHandle:testAnimHandle];

            break;
        }
        
        case COMPANION_ACTION_WALK_FROM_TABLE_RIGHT:
        {
            NSNumber* testAnimHandle = [[ResourceManager GetInstance] LoadAssetWithName:[self GetAnimationFilename:COMPANION_ANIMATION_WALK]];
            NSData* animData = [[ResourceManager GetInstance] GetDataForHandle:testAnimHandle];
        
            AnimationTransitionParams animationTransitionParams;
            [AnimationController InitDefaultTransitionParams:&animationTransitionParams];
            
            animationTransitionParams.mTransitionToTime = COMPANION_ANIMATION_TRANSITION_TIME;
            animationTransitionParams.mTransitionFromTime = COMPANION_ANIMATION_TRANSITION_TIME;
            animationTransitionParams.mLoop = FALSE;
            
            [mPuppet->mSkeleton SetSkeletonTransform:SKELETON_TRANSFORM_MIRROR_X];
            
            [mAnimationController PushTargetAnimationClipData:animData params:&animationTransitionParams];
            
            [[ResourceManager GetInstance] UnloadAssetWithHandle:testAnimHandle];
            break;
        }
        
        case COMPANION_ACTION_WALK_TO_TABLE_LEFT:
        {
            NSNumber* testAnimHandle = [[ResourceManager GetInstance] LoadAssetWithName:[self GetAnimationFilename:COMPANION_ANIMATION_WALK]];
            NSData* animData = [[ResourceManager GetInstance] GetDataForHandle:testAnimHandle];
        
            AnimationTransitionParams animationTransitionParams;
            [AnimationController InitDefaultTransitionParams:&animationTransitionParams];
            
            AnimationClip* sourceClip = [(AnimationClip*)[AnimationClip alloc] InitWithData:animData skeleton:mPuppet->mSkeleton];
            
            AnimationTransformerModifierList* modifierList = [self BuildTransformerParams];
            
            ReverseAnimationTransformerAngleOffset* mirrorTransformer = 
                [(ReverseAnimationTransformerAngleOffset*)[ReverseAnimationTransformerAngleOffset alloc] InitWithModifierList:modifierList];
                
            [modifierList release];
                
            AnimationClip* mirroredClip = [(AnimationClip*)[AnimationClip alloc] InitWithAnimationClip:sourceClip transformer:mirrorTransformer];
            [mirrorTransformer release];

            animationTransitionParams.mTransitionToTime = 0.0f;
            animationTransitionParams.mTransitionFromTime = COMPANION_ANIMATION_TRANSITION_TIME;
            animationTransitionParams.mLiveBlend = TRUE;
            animationTransitionParams.mLoop = FALSE;
                                                
            [mAnimationController PushTargetAnimationClip:mirroredClip skeleton:mPuppet->mSkeleton params:&animationTransitionParams];
            
            [[ResourceManager GetInstance] UnloadAssetWithHandle:testAnimHandle];
            break;
        }
        
        case COMPANION_ACTION_WALK_TO_TABLE_RIGHT:
        {
            NSNumber* testAnimHandle = [[ResourceManager GetInstance] LoadAssetWithName:[self GetAnimationFilename:COMPANION_ANIMATION_WALK]];
            NSData* animData = [[ResourceManager GetInstance] GetDataForHandle:testAnimHandle];
        
            AnimationTransitionParams animationTransitionParams;
            [AnimationController InitDefaultTransitionParams:&animationTransitionParams];
            
            AnimationClip* sourceClip = [(AnimationClip*)[AnimationClip alloc] InitWithData:animData skeleton:mPuppet->mSkeleton];
            
            AnimationTransformerModifierList* modifierList = [self BuildTransformerParams];
            
            ReverseAnimationTransformerAngleOffset* mirrorTransformer = 
                [(ReverseAnimationTransformerAngleOffset*)[ReverseAnimationTransformerAngleOffset alloc] InitWithModifierList:modifierList];
                
            [modifierList release];
                
            AnimationClip* mirroredClip = [(AnimationClip*)[AnimationClip alloc] InitWithAnimationClip:sourceClip transformer:mirrorTransformer];
            [mirrorTransformer release];

            animationTransitionParams.mTransitionToTime = 0.0f;
            animationTransitionParams.mTransitionFromTime = COMPANION_ANIMATION_TRANSITION_TIME;
            animationTransitionParams.mLiveBlend = TRUE;
            animationTransitionParams.mLoop = FALSE;
            
            [mPuppet->mSkeleton SetSkeletonTransform:SKELETON_TRANSFORM_MIRROR_X];
                                                
            [mAnimationController PushTargetAnimationClip:mirroredClip skeleton:mPuppet->mSkeleton params:&animationTransitionParams];
            
            [[ResourceManager GetInstance] UnloadAssetWithHandle:testAnimHandle];
            break;
        }
		
		case COMPANION_ACTION_ABILITY:
		{
            NSNumber* testAnimHandle = [[ResourceManager GetInstance] LoadAssetWithName:[self GetAbilityAnimationFilename]];
            NSData* animData = [[ResourceManager GetInstance] GetDataForHandle:testAnimHandle];
        
            AnimationTransitionParams animationTransitionParams;
            [AnimationController InitDefaultTransitionParams:&animationTransitionParams];
            
            animationTransitionParams.mTransitionToTime = COMPANION_ANIMATION_TRANSITION_TIME;
            animationTransitionParams.mTransitionFromTime = COMPANION_ANIMATION_TRANSITION_TIME;
            animationTransitionParams.mLoop = FALSE;
            
            [mAnimationController PushTargetAnimationClipData:animData params:&animationTransitionParams];
            
            [[ResourceManager GetInstance] UnloadAssetWithHandle:testAnimHandle];

            break;
		}
    }
    
    mCompanionState = COMPANION_STATE_OTHER;
}

-(AnimationTransformerModifierList*)BuildTransformerParams
{
    AnimationTransformerModifierList* modifierList = [(AnimationTransformerModifierList*)[AnimationTransformerModifierList alloc] Init];
    
    AnimationTransformerModifier* phaseOne = [(AnimationTransformerModifier*)[AnimationTransformerModifier alloc] Init];
    AnimationTransformerModifier* phaseTwo = [(AnimationTransformerModifier*)[AnimationTransformerModifier alloc] Init];
    
    phaseOne->mTargetJoint = [mPuppet->mSkeleton GetJointAtIndex:JOINT_ROOT];
    phaseTwo->mTargetJoint = [mPuppet->mSkeleton GetJointAtIndex:JOINT_ROOT];
    
    // Animation is unmodified for the first 0.5 seconds (while the companion is getting off the table)
    Set(&phaseOne->mModifier, 0.0f, 0.0f, 0.0f);
    SetVec2(&phaseOne->mTimeRange, 0.0f, 0.50f);
    
    // Afterwards, we flip the companion around.  Slight tilt to correct some coordinate system craziness.
    Set(&phaseTwo->mModifier, 140.0f, -20.0f, 0.0f);
    SetVec2(&phaseTwo->mTimeRange, 0.50f, FLT_MAX);
    
    [modifierList AddTransformerModifier:phaseOne];
    [modifierList AddTransformerModifier:phaseTwo];
    
    return modifierList;
}

-(CompanionState)GetCompanionState
{
    return mCompanionState;
}

-(void)SetGlowEnabled:(BOOL)inEnabled
{
    float currentGlow = 0.0f;
    float finalGlow = inEnabled ? COMPANION_GLOW_PEAK_INTENSITY : 0.0f;
    
    // Short circuit trivial cases
    if (((mGlowState == COMPANION_GLOW_OFF) && (!inEnabled)) || ((mGlowState == COMPANION_GLOW_ON) && (inEnabled)))
    {
        return;
    }
    
    if ([mGlowPath GetPathType] != PATH_TYPE_INVALID)
    {
        [mGlowPath GetValueScalar:&currentGlow];
    }
    else
    {
        NSAssert(mGlowState == COMPANION_GLOW_OFF, @"Path is invalid, but the companion is glowing.");
        finalGlow = COMPANION_GLOW_PEAK_INTENSITY;
    }
    
    [mGlowPath Reset];
    
    mGlowState = inEnabled ? COMPANION_GLOW_TRANSITION_ON : COMPANION_GLOW_TRANSITION_OFF;
    
    [mGlowPath AddNodeScalar:currentGlow atIndex:0 withSpeed:COMPANION_GLOW_SPEED];
    [mGlowPath AddNodeScalar:finalGlow atIndex:1 withSpeed:COMPANION_GLOW_SPEED];
    
    [mPuppet SetGlowEnabled:TRUE];
}

-(void)Pulse:(int)inNumPulses
{
    NSAssert(mGlowState == COMPANION_GLOW_OFF, @"We don't support pulsing companions that are already glowing");
    NSAssert(mPulseState == COMPANION_PULSE_OFF, @"We don't support pulsing companions already in a pulse");
    
    mPulseState = COMPANION_PULSE_ON;
    
    [self SetGlowEnabled:TRUE];
    
    mNumPulses = inNumPulses;
}

-(CompanionPulseState)GetPulseState
{
    return mPulseState;
}

-(void)SetupRenderState:(RenderStateParams*)inRenderStateParams
{
    NeonGLEnable(GL_CULL_FACE);
    
    CompanionRenderInfo* renderInfo = [[CompanionRenderManager GetInstance] getCompanionRenderInfo:mCompanionID];

    if (inRenderStateParams->mRenderPassType == RENDER_PASS_REFLECTION)
    {
        if (renderInfo->mClockwiseWinding)
        {
            glCullFace(GL_FRONT);
        }
        else
        {
            glCullFace(GL_BACK);
        }
    }
    else
    {
        if (renderInfo->mClockwiseWinding)
        {
            glCullFace(GL_BACK);
        }
        else
        {
            glCullFace(GL_FRONT);
        }
    }
    
    NeonGLEnable(GL_DEPTH_TEST);
    
    [super SetupRenderState:inRenderStateParams];
}

-(void)TeardownRenderState:(RenderStateParams*)inRenderStateParams
{
    if (inRenderStateParams->mRenderPassType == RENDER_PASS_REFLECTION)
    {
        glCullFace(GL_BACK);
    }
    
    NeonGLDisable(GL_CULL_FACE);
    
    [super TeardownRenderState:inRenderStateParams];
}

@end
