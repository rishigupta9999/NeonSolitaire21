//
//  PNGTexture.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "Texture.h"
#import "png.h"

@interface PNGTexture : Texture
{
}

-(Texture*)InitWithData:(NSData*)inData textureParams:(TextureParams*)inParams;
-(Texture*)InitWithMipMapData:(NSMutableArray*)inData textureParams:(TextureParams*)inParams;

-(void)LoadPNGBytes:(unsigned char*)inBytes;
-(void)LoadPNGData:(NSData*)inData;

-(void)dealloc;

@end
