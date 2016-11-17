//
//  GameObjectSystem.h
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "GameObject.h"
#import "NeonArray.h"

@interface GameObjectCollection : NSObject<MessageChannelListener>
{
    NeonArray*      mGameObjectList;
    BOOL            mUpdating;
}

-(GameObjectCollection*)Init;
-(void)dealloc;

-(void)Add:(GameObject*)inObject;
-(void)Add:(GameObject*)inObject withRenderBin:(RenderBinId)inRenderBinId;

-(void)Remove:(GameObject*)inObject;
-(GameObject*)GetObject:(int)inIndex;
-(int)GetSize;
-(NSUInteger)FindObject:(GameObject*)inObject;
-(u32)GetNumVisible3DObjects;

-(void)Update:(CFTimeInterval)inTimeStep;

-(GameObject*)FindObjectWithHash:(u32)inHash;
-(u32)GenerateHash:(const char*)inString;

-(void)ProcessMessage:(Message*)inMsg;

@end

BOOL GameObjectCollection_UpdateObject(GameObjectCollection* inCollection, GameObject* inObject, CFTimeInterval inTimeStep);