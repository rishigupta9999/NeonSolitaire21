//
//  GameObject.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "NeonMath.h"
#import "Model.h"
#import "RenderBin.h"
#import "Path.h"

@class GameObjectCollection;
@class GameObjectBatch;
@class GameObject;
@class Light;
@class GameState;

typedef enum
{
    GAMEOBJECT_PROPERTY_POSITION,
    GAMEOBJECT_PROPERTY_ORIENTATION,
    GAMEOBJECT_PROPERTY_SCALE,
    GAMEOBJECT_PROPERTY_ALPHA,
    GAMEOBJECT_PROPERTY_NUM,
    GAMEOBJECT_PROPERTY_INVALID = GAMEOBJECT_PROPERTY_NUM
} GameObjectProperty;

typedef enum
{
    GAMEOBJECT_ANIMATE_INVALID,
    GAMEOBJECT_ANIMATE_PATH,
    GAMEOBJECT_ANIMATE_VECTOR
} GameObjectAnimateType;

typedef enum
{
    GAMEOBJECT_ALIVE,
    GAMEOBJECT_DELETE_AFTER_OPERATIONS,
    GAMEOBJECT_DELETE_AFTER_UPDATE,
    GAMEOBJECT_COMPLETED
} GameObjectState;

typedef enum
{
    GAMEOBJECT_TIMESTEP_VARIABLE,
    GAMEOBJECT_TIMESTEP_CONSTANT,
    GAMEOBJECT_TIMESTEP_MAX
} TimeStepType;

typedef enum
{
    GAMEOBJECT_LIGHTING_TYPE_ALL,
    GAMEOBJECT_LIGHTING_TYPE_LIST
} GameObjectLightingType;

typedef union
{
    Path*                   mPath;
    Vector3                 mVector;
    u8                      mData[sizeof(Vector3)];
} GameObjectAnimateData;

@interface GameObjectAnimateNode : NSObject
{
    @public
        GameObjectAnimateType   mAnimateType;
        GameObjectProperty      mPropertyType;
        GameObjectAnimateData   mData;
}

-(GameObjectAnimateNode*)Init;
-(void)dealloc;

-(void)SetPropertyType:(GameObjectProperty)inProperty withPath:(Path*)inPath;
-(void)SetPropertyType:(GameObjectProperty)inProperty withVector:(Vector3*)inPath;

@end

typedef enum
{
    RENDER_PASS_NORMAL,
    RENDER_PASS_REFLECTION
} RenderPassType;

typedef struct
{
    RenderPassType  mRenderPassType;
} RenderStateParams;

@interface GameObjectAction : NSObject
{
}

@property           dispatch_block_t  block;
@property(assign)   dispatch_queue_t  queue;

-(GameObjectAction*)init;

@end

@interface GameObject : NSObject
{
    @public
        Matrix44        mLTWTransform;  // Defaults to identity.  Entities can operate in a local coordinate system, and before the object is rendered,
                                        // a local to world transform will be applied
        
        BOOL            mOrtho;
        BOOL            mUsesLighting;
        
        u32             mIdentifier;
        
        GameObjectState mGameObjectState;
        TimeStepType    mTimeStepType;
	
		RenderBinId     mRenderBinId;
    
        Vector3         mPivot;
        
    @protected
        Model*          mPuppet;
        BOOL            mProjected;

        Vector3         mPosition;
        Vector3         mOrientation;   // Euler XYZ.  Processing order is x, y then z
        Vector3         mScale;
        float           mAlpha;
        BOOL            mVisible;
        
        u32             mUserData;
        
        GameObjectBatch*        mGameObjectBatch;
        GameObjectCollection*   mOwningCollection;
        
        GameObjectLightingType      mLightingType;
        NSMutableArray*             mLights;
        
        NSMutableArray* mAnimationList[GAMEOBJECT_PROPERTY_NUM];
                
        NSString*       mStringIdentifier;
        
        GameState*      mOwningState;
    
        NSMutableArray* mActionList;
}

-(void)Init;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Draw;
-(void)DrawOrtho;
-(void)DrawBoundingBox;

+(void)InitDefaultRenderStateParams:(RenderStateParams*)outParams;
-(void)SetupRenderState:(RenderStateParams*)inParams;
-(void)TeardownRenderState:(RenderStateParams*)inParams;

-(BOOL)GetWorldSpaceBoundingBox:(Box*)outBox;
-(BOOL)GetObjectSpaceBoundingBox:(Box*)outBox;

-(void)GetLocalToWorldTransform:(Matrix44*)outTransform;
-(void)TransformLocalToWorld:(Vector3*)inVec result:(Vector3*)outVec;

-(BOOL)GetVisible;
-(void)SetVisible:(BOOL)inVisible;

-(BOOL)GetProjected;
-(void)SetProjected:(BOOL)inProjected;

-(void)SetPosition:(Vector3*)inPosition;
-(void)SetPositionX:(float)inX Y:(float)inY Z:(float)inZ;
-(void)GetPosition:(Vector3*)outPosition;
-(void)GetPositionWorld:(Vector3*)outPosition current:(BOOL)inCurrent;

-(void)SetOrientation:(Vector3*)inOrientation;
-(void)SetOrientationX:(float)inX Y:(float)inY Z:(float)inZ;
-(void)GetOrientation:(Vector3*)outOrientation;

-(void)SetScale:(Vector3*)inScale;
-(void)SetScaleX:(float)inX Y:(float)inY Z:(float)inZ;
-(void)GetScale:(Vector3*)outScale;

-(void)SetAlpha:(float)inAlpha;
-(void)GetAlpha:(float*)outAlpha;
-(float)GetAlpha;

// GetProperty and GetPropertyCurrent have the same behavior if a property is not animating.
// The different behavior during animation is described below:
//
// GetProperty will return the final value of the property.  For example, if obtaining the
// position, GetProperty will return what the position will be when all current animations
// affecting the position are completed. Repeated calls during an animation will return the
// same result.
//
// GetPropertyCurrent returns the current value.  So if a property is animating, repeated
// calls on different frames will yield varying results as the property changes over the
// course of the animation.

-(void)GetProperty:(GameObjectProperty)inProperty withVector:(Vector3*)outValue;
-(void)GetPropertyCurrent:(GameObjectProperty)inProperty withVector:(Vector3*)outValue;

-(void)SetProperty:(GameObjectProperty)inProperty withVector:(Vector3*)inVector;
-(void)AnimateProperty:(GameObjectProperty)inProperty withPath:(Path*)inPath;
-(void)AnimateProperty:(GameObjectProperty)inProperty withPath:(Path*)inPath replace:(BOOL)inReplace;

-(BOOL)PropertyIsAnimating:(GameObjectProperty)inProperty;
-(BOOL)AnyPropertyIsAnimating;

-(void)CancelAnimationForProperty:(GameObjectProperty)inProperty;

-(void)SetUserData:(u32)inUserData;
-(u32)GetUserData;

-(int)GetRenderBinId;

-(GameObject*)Remove;
-(GameObject*)RemoveAfterOperations;

-(void)SetOwningCollection:(GameObjectCollection*)inCollection;
-(GameObjectCollection*)GetOwningCollection;

-(void)SetStringIdentifier:(NSString*)inIdentifier;
-(NSString*)GetStringIdentifier;

-(void)SetLightingType:(GameObjectLightingType)inLightingType;
-(GameObjectLightingType)GetLightingType;

-(void)AddAffectingLight:(Light*)inLight;
-(void)RemoveAffectingLight:(Light*)inLight;
-(NSMutableArray*)GetAffectingLights;

-(GameObjectBatch*)GetGameObjectBatch;
-(void)SetGameObjectBatch:(GameObjectBatch*)inGameObjectBatch;

-(GameState*)GetOwningState;

-(Model*)GetPuppet;

-(void)PerformAfterOperationsInQueue:(dispatch_queue_t)inQueue block:(dispatch_block_t)inBlock;

@end