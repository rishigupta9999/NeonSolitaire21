//
//  ReflectiveModel.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "SimpleModel.h"

@interface ReflectedObjectRecord : NSObject
{
    @public
        Model*   mModel;
        Matrix44 mTransform;
        float    mReflectionIntensity;
}

-(ReflectedObjectRecord*)Init;

@end

@interface ReflectiveModel : SimpleModel
{
    NSMutableArray* mReflectedObjects;
    Matrix44        mReflectionMatrix;
    
    BOOL            mReflectionMatrixValid;
    
    float           mPlaneEquation[4];
}

-(ReflectiveModel*)InitWithData:(NSData*)inData;
-(void)dealloc;

-(void)SetReflectiveSurfaceTransform:(float)inYTranslate rotation:(float)inRotationDegrees;
-(void)AddReflectedObject:(Model*)inModel;
-(void)AddReflectedObject:(Model*)inModel localTransform:(Matrix44*)inTransform;
-(void)SetReflectionIntensity:(float)inIntensity forModel:(Model*)inModel;
-(void)Draw;

@end