//
//  ReflectiveModel.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "ReflectiveModel.h"
#import "ModelManager.h"
#import "GLExtensionManager.h"

#define REFLECTED_OBJECT_CAPACITY_DEFAULT   (4)

@implementation ReflectedObjectRecord

-(ReflectedObjectRecord*)Init
{
    mModel = NULL;
    SetIdentity(&mTransform);
    mReflectionIntensity = 1.0;
    
    return self;
}

@end

@implementation ReflectiveModel

-(ReflectiveModel*)InitWithData:(NSData*)inData
{
    [super InitWithData:inData];
    
    mReflectedObjects = [[NSMutableArray alloc] initWithCapacity:REFLECTED_OBJECT_CAPACITY_DEFAULT];
    
    mReflectionMatrixValid = FALSE;
    
    SetIdentity(&mReflectionMatrix);
    memset(mPlaneEquation, 0, sizeof(mPlaneEquation));

    return self;
}

-(void)dealloc
{
    [mReflectedObjects release];
    [super dealloc];
}

-(void)AddReflectedObject:(Model*)inModel
{
    ReflectedObjectRecord* record = [(ReflectedObjectRecord*)[ReflectedObjectRecord alloc] Init];
    
    record->mModel = inModel;
    [mReflectedObjects addObject:record];
    [record release];
}

-(void)AddReflectedObject:(Model*)inModel localTransform:(Matrix44*)inTransform
{
    ReflectedObjectRecord* record = [(ReflectedObjectRecord*)[ReflectedObjectRecord alloc] Init];
    
    record->mModel = inModel;
    CloneMatrix44(inTransform, &record->mTransform);
    [mReflectedObjects addObject:record];
    [record release];
}

-(void)SetReflectionIntensity:(float)inIntensity forModel:(Model*)inModel
{
    for (ReflectedObjectRecord* curRecord in mReflectedObjects)
    {
        if (curRecord->mModel == inModel)
        {
            curRecord->mReflectionIntensity = inIntensity;
            break;
        }
    }
}

-(void)Draw
{
    BOOL stencilSupported = [[GLExtensionManager GetInstance] GetUsingStencil];
    
    if (stencilSupported)
    {
        // Lazily generate the reflection matrix.  We can only do this when an owner object is set so we know bounding box (for mHeight
        // which we use for the clip plane to clip excess reflected geometry)
        
        if (!mReflectionMatrixValid)
        {
            return;
        }
        
        // Draw the object normally, but only populate the stencil buffer.  It contains 1s in fragments the model's geometry is.
        NeonGLDisable(GL_DEPTH_TEST);
        glEnable(GL_STENCIL_TEST);
        glClearStencil(0);
        glClear( GL_STENCIL_BUFFER_BIT );

        glStencilFunc( GL_NEVER, 1, 1 );
        glStencilOp( GL_REPLACE, GL_REPLACE, GL_REPLACE );
        
        glColorMask(FALSE, FALSE, FALSE, FALSE);
        [super Draw];
        glColorMask(TRUE, TRUE, TRUE, TRUE);
        glStencilFunc( GL_EQUAL, 1, 1 );
        glStencilOp( GL_KEEP, GL_KEEP, GL_KEEP );
        
        NeonGLEnable(GL_DEPTH_TEST);
        
        // Draw reflected objects, clipping them so they don't appear above the mirror.  Stencil test is on, so they won't appear outside the mirror either.
        glEnable( GL_CLIP_PLANE0 );
        glClipPlanef( GL_CLIP_PLANE0, mPlaneEquation );
        
        for (ReflectedObjectRecord* reflectedObjectRecord in mReflectedObjects)
        {
            Matrix44 transform;
            MatrixMultiply(&mReflectionMatrix, &reflectedObjectRecord->mTransform, &transform);
            
            ModelRenderState renderState;
            [Model InitDefaultRenderState:&renderState];
            
            SetVec4(&renderState.mColor, reflectedObjectRecord->mReflectionIntensity, reflectedObjectRecord->mReflectionIntensity, reflectedObjectRecord->mReflectionIntensity, reflectedObjectRecord->mReflectionIntensity);
            
            [reflectedObjectRecord->mModel SetRenderStateOverride:&renderState];
            
            [[ModelManager GetInstance] DrawModel:reflectedObjectRecord->mModel
                ownerObject:reflectedObjectRecord->mModel->mOwnerObject withTransform:&transform renderPassType:RENDER_PASS_REFLECTION];
            
            [reflectedObjectRecord->mModel ClearRenderStateOverride];
        }
        
        glDisable(GL_CLIP_PLANE0);
        glDisable(GL_STENCIL_TEST);
        
        // Finally draw the object itself, blending with the reflected objects.
        NeonGLEnable(GL_BLEND);
        NeonGLBlendFunc(GL_ONE, GL_ONE);
        
        [super Draw];
        
        NeonGLBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        NeonGLDisable(GL_BLEND);
        NeonGLEnable(GL_DEPTH_TEST);
    }
    else
    {
        // If there's no stencil buffer support on this device, then just draw the object like a normal SimpleModel
        [super Draw];
    }
}

-(void)SetReflectiveSurfaceTransform:(float)inYTranslate rotation:(float)inRotationDegrees
{
    
    // These matrices correspond to those in Tim Hall's article on OpenGL reflections
    // http://www.opengl.org/resources/code/samples/mjktips/TimHall_Reflections.txt
    Matrix44 mirrorT, mirrorTPrime, scaleZ;
    
    // Generate mirrorT
    Matrix44 translation;
    GenerateTranslationMatrix(0.0f, inYTranslate, 0.0f, &translation);
    
    Matrix44 rotation;
    GenerateRotationMatrix(inRotationDegrees, 1.0f, 0.0f, 0.0f, &rotation);
    
    MatrixMultiply(&rotation, &translation, &mirrorT);
    
    // Generate mirrorTPrime
    GenerateTranslationMatrix(0.0f, -inYTranslate, 0.0f, &translation);
    GenerateRotationMatrix(-inRotationDegrees, 1.0f, 0.0f, 0.0f, &rotation);

    MatrixMultiply(&translation, &rotation, &mirrorTPrime);
    
    GenerateScaleMatrix(1.0f, -1.0f, 1.0f, &scaleZ);
    
    MatrixMultiply(&mirrorT, &scaleZ, &mReflectionMatrix);
    MatrixMultiply(&mReflectionMatrix, &mirrorTPrime, &mReflectionMatrix);
                
    mReflectionMatrixValid = TRUE;
    
    mPlaneEquation[0] = -rotation.mMatrix[4];
    mPlaneEquation[1] = -rotation.mMatrix[5];
    mPlaneEquation[2] = rotation.mMatrix[6];
    mPlaneEquation[3] = -(mPlaneEquation[1] * inYTranslate);
    
    mReflectionMatrixValid = TRUE;
}

@end