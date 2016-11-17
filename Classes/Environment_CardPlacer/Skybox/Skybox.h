//
//  Skybox.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "GameObject.h"

typedef enum
{
    SKYBOX_PLUS_X,
    SKYBOX_MINUS_X,
    SKYBOX_PLUS_Y,
    SKYBOX_MINUS_Y,
    SKYBOX_PLUS_Z,
    SKYBOX_MINUS_Z,
    SKYBOX_NUM
} SkyboxFaces;

typedef struct
{
    NSString*   mFiles[SKYBOX_NUM];
    BOOL        mTranslateFace[SKYBOX_NUM];
    BOOL        mTranslateAxis[3];
} SkyboxParams;

@interface Skybox : GameObject
{
    Texture*        mTextures[SKYBOX_NUM];
    SkyboxParams    mParams;
}

-(Skybox*)InitWithParams:(SkyboxParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(SkyboxParams*)outParams;

-(void)Draw;

@end