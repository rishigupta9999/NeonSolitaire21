//
//  Light.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "NeonMath.h"

typedef struct
{
    BOOL    mDirectional;
    Vector3 mVector;        // This is the direction if this is a directional light.  Position if a position light
    
    Vector3 mAmbientRGB;
    Vector3 mDiffuseRGB;
    Vector3 mSpecularRGB;
    
    Vector3 mSpotDirection; // The direction of the spotlight, default is (0, 0, -1)
    float   mSpotCutoff;    // The half-angle of the cone, default is 180 degrees (so 360 degree light)
    float   mSpotExponent;  // How concentrated the light is, default is zero.  More than zero means more concentrated towards the center of the cone.
    
    float   mConstantAttenuation;   // Default is 1.0
    float   mLinearAttenuation;     // Default is 0.0
    float   mQuadraticAttenuation;  // Default is 0.0
} LightParams;

@interface Light : NSObject
{
    @public
        int     mGLIdentifier;
        BOOL    mEnabled;
    
    @private
        LightParams mParams;
}

-(Light*)InitWithIdentifier:(int)inIdentifier;
-(void)dealloc;
-(LightParams*)GetParams;
-(void)ApplyParams;

-(void)SetLightActive:(BOOL)inActive;
-(BOOL)GetLightActive;

+(void)InitDefaultParams:(LightParams*)inParams;

@end