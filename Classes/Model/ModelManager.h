//
//  ModelManager.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "ModelManagerTypes.h"
#import "Model.h"
#import "GameObject.h"
#import "DebugManager.h"
#import "RenderBin.h"

@class GameObjectManager;

@interface ModelManager : NSObject <DebugMenuCallback>
{
    BOOL                    mShowBoundingBoxes;
    BOOL                    mDrawingEnabled;
    ModelManagerDrawingMode mDrawingMode;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(ModelManager*)GetInstance;

+(void)InitDefaultParams:(ModelParams*)outParams;
+(void)InitDefaultDrawParams:(ModelManagerDrawParams*)outParams;

-(void)DebugMenuItemPressed:(NSString*)inName;

-(void)Init;

-(void)SetupWorldCamera;
-(void)TeardownWorldCamera;

-(void)SetupUICamera;
-(void)TeardownUICamera;

-(void)SetupOrthoCamera;
-(void)TeardownOrthoCamera;

-(void)SetupViewport:(ModelManagerViewport)inViewportType;

-(void)Draw;
-(void)DrawWithParams:(ModelManagerDrawParams*)inParams;

-(void)DrawObject:(GameObject*)inObject;
-(void)DrawModel:(Model*)inModel ownerObject:(GameObject*)inOwnerObject withTransform:(Matrix44*)inTransform renderPassType:(RenderPassType)inPassType;

-(void)dealloc;

-(Model*)ModelWithParams:(ModelParams*)inParams;
-(Model*)ModelWithName:(NSString*)inName owner:(GameObject*)inOwner;

-(RenderBin*)GetRenderBinWithId:(RenderBinId)inId;
-(void)SetDrawingEnabled:(BOOL)inEnabled;
-(void)SetDrawingMode:(ModelManagerDrawingMode)inDrawingMode;
-(ModelManagerDrawingMode)GetDrawingMode;

-(void)GetModelManagerViewMatrix:(Matrix44*)outMatrix;

-(BOOL)ShouldDrawObject:(GameObject*)inObject withParams:(ModelManagerDrawParams*)inParams;

-(int)GetPriorityForRenderBin:(RenderBinId)inRenderBinId;

@end