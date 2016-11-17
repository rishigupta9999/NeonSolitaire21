//
//  TextureManager.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "Texture.h"

@interface TextureManager :  NSObject
{
    dispatch_queue_t mLoadingQueue;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(TextureManager*)GetInstance;

-(void)Init;
-(void)Term;

-(Texture*)TextureWithName:(const NSString*)inName;
-(Texture*)TextureWithName:(const NSString*)inName textureParams:(TextureParams*)inParams;
-(dispatch_queue_t)GetLoadingQueue;

@end