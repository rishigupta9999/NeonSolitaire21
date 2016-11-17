//
//  LightManager.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "Light.h"
#import "DebugManager.h"

#define NUM_OPENGL_LIGHTS   (8)

@interface LightManager : NSObject<DebugMenuCallback>
{
    NSMutableArray* mLights;
    
    int mMinGLIdentifier;
    int mMaxGLIdentifier;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(LightManager*)GetInstance;

-(LightManager*)Init;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)UpdateLights;

-(Light*)CreateLight;

// TODO: Scan any GameObjects that are using this light and update them.
-(void)RemoveLight:(Light*)inLight;

-(int)GetNumLights;
-(Light*)GetLight:(int)inLightIndex;

-(void)DebugMenuItemPressed:(NSString*)inName;

-(void)EnableAllLights;
-(void)EnableLights:(NSArray*)inLights;

@end