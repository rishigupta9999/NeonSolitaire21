//
//  JPEGTexture.h
//  Neon21
//
//  Copyright Neon Games 2012. All rights reserved.
//

#import "Texture.h"
#import "png.h"

@interface JPEGTexture : Texture
{
}

-(Texture*)PreinitWithData:(NSData*)inData textureParams:(TextureParams*)inParams;
-(Texture*)CompleteInit;

-(Texture*)InitWithData:(NSData*)inData textureParams:(TextureParams*)inParams;
-(Texture*)InitWithMipMapData:(NSMutableArray*)inData textureParams:(TextureParams*)inParams;

-(void)dealloc;

@end
