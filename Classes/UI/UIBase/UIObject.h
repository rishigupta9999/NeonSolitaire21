//
//  UIObject.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "GameObject.h"
#import "PlacementValue.h"
#import "Color.h"
#import "ModelManagerTypes.h"

@class UIGroup;

typedef enum
{
    UIOBJECT_NONE = 0,
    UIOBJECT_PROJECTED_STATE_DIRTY = 1 << 0,
} UIOBJECT_DIRTY_BITS;

typedef enum
{
    VISIBILITY_STATE_CONSTANT,
    VISIBILITY_STATE_FADE_IN,
    VISIBILITY_STATE_FADE_OUT,
    VISIBILITY_STATE_FADE_TO_INACTIVE,
} VisibilityState;

typedef enum
{
    UI_OBJECT_STATE_ENABLED,        // Normal, visible
    UI_OBJECT_STATE_HIGHLIGHTED,    // Highlighted, visible
    UI_OBJECT_STATE_DISABLED,       // Doesn't respond to input, invisible
    UI_OBJECT_STATE_INACTIVE,       // Doesn't respond to input, visible
    UI_OBJECT_STATE_INVALID
} UIObjectState;

typedef enum
{
    UI_OBJECT_PLACEMENT_STATUS_UNINITIALIZED,
    UI_OBJECT_PLACEMENT_STATUS_CALCULATED
} UIObjectPlacementStatus;

typedef struct
{
    PlacementValue  mPlacement;
} UIObjectParams;

typedef struct
{
    NSString*       mTextureName;
    TexDataLifetime mTexDataLifetime;
} UIObjectTextureLoadParams;

@interface UIObject : GameObject<PathCallback>
{
    @protected
        PlacementValue          mPlacement;
        UIObjectPlacementStatus mPlacementStatus;
    
        VisibilityState mVisibilityState;
        
        Path*           mFadeInPath;
        Path*           mFadeOutPath;
        Path*           mFadeToInactivePath;
        Path*           mFadeToActivePath;
        
        u32             mFadeSpeed;
            
        u32             mDirtyBits;
    
    @private
        UIObjectState   mUIObjectState;
        UIObjectState   mUIObjectPrevState;
    
    @public
        BOOL            mForceTextureScale;
}

@property BOOL FadeWhenInactive;

-(void)InitWithUIGroup:(UIGroup*)inUIGroup;
-(void)dealloc;

+(void)InitDefaultParams:(UIObjectParams*)inParams;
-(void)SetPlacement:(PlacementValue*)inPlacement;

-(UIObjectState)GetState;
-(UIObjectState)GetPrevState;
-(void)SetState:(UIObjectState)inState;

-(void)SetProjected:(BOOL)inProjected;

-(u32)GetWidth;
-(u32)GetHeight;

-(void)GetLocalToWorldTransform:(Matrix44*)outTransform;
-(void)GetPosition:(Vector3*)outPosition;
-(void)GetPositionWithoutPlacement:(Vector3*)outPosition;

-(void)GetProjectedCoordsForTexture:(Texture*)inTexture coords:(Rect3D*)outCoords;
-(void)GetProjectedCoordsForTexture:(Texture*)inTexture border:(Vector2*)inBorder coords:(Rect3D*)outCoords;

-(void)Disable;
-(void)Enable;

-(void)SetActive:(BOOL)inActive;

-(void)InitFadePaths;

-(void)BuildFadeInPath;
-(void)BuildFadeOutPath;
-(void)BuildFadeToActivePath;
-(void)BuildFadeToInactivePath;

-(void)BeginPulse;
-(void)EndPulse;

-(void)PathEvent:(PathEvent)inEvent withPath:(Path*)inPath userData:(u32)inData;
-(void)StatusChanged:(UIObjectState)inState;

+(void)InitDefaultTextureLoadParams:(UIObjectTextureLoadParams*)outParams;
-(Texture*)LoadTextureWithParams:(UIObjectTextureLoadParams*)inParams;
-(void)RegisterTexture:(Texture*)inTexture;
-(void)UpdateTexture:(Texture*)inTexture;
-(BOOL)TextureRegistered:(Texture*)inTexture;

-(void)SetupViewportStart:(ModelManagerViewport)inStartViewport end:(ModelManagerViewport)inEndViewport;
-(void)SetupViewportEnd:(ModelManagerViewport)inEndViewport;

-(Texture*)GetUseTexture;

typedef enum
{
    QUAD_PARAMS_SCALE_NONE,
    QUAD_PARAMS_SCALE_X,
    QUAD_PARAMS_SCALE_Y,
    QUAD_PARAMS_SCALE_BOTH
} QuadParamsScale;

typedef struct
{
    Texture* mTexture;
    
    BOOL     mColorMultiplyEnabled;
    Color    mColor[4];
    
    BOOL     mBlendEnabled;
    
    Vector2  mTranslation;
    
    QuadParamsScale  mScaleType;
    Vector2  mScale;
        
    BOOL     mTexCoordEnabled;
    float    mTexCoords[8];
    
} QuadParams;

+(void)InitQuadParams:(QuadParams*)outQuadParams;
-(void)DrawQuad:(QuadParams*)inQuadParams withIdentifier:(const char*)inIdentifier;

-(void)SetFadeSpeed:(u32)inFadeSpeed;

@end