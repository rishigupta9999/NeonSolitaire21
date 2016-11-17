//
//  DebugManager.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "TextureButton.h"
#import "Connection.h"

@class GameState;

@protocol DebugMenuCallback

-(void)DebugMenuItemPressed:(NSString*)inName;

@end

@interface DebugMenuItem : NSObject
{
    @public
        NSString*                       mName;
        NSObject<DebugMenuCallback>*    mCallback;
        Button*                         mButton;
}

-(DebugMenuItem*)Init;
-(void)dealloc;

@end

typedef enum
{
    PICK_RAY_IDLE,
    PICK_RAY_ANIMATING,
    PICK_RAY_WAITING_TO_EXPIRE
} PickRayState;

@interface DebugManager : NSObject <ButtonListenerProtocol, DebugMenuCallback, NSNetServiceDelegate, MessageChannelListener, ConnectionDelegate>
{
    @public
        float           mElapsedTime;
        
        TextureButton*  mDebugButton;
        BOOL            mDebugMenuActive;
        
        NSMutableArray* mMenuItems;
        
        int             mDebugDepth;
        
        PickRayState    mPickRayState;
        Vector4         mPickRayStart;
        Vector4         mPickRayDirectionVector;
        float           mPickRayTime;
        
        BOOL            mDrawPickRays;
    
        NSNetService*   mNetService;
        CFSocketRef     mListeningSocket;
        uint16_t        mListeningPort;
        Connection*     mClientConnection;
}


// Class methods that manage creation and access
+(void)CreateInstance;
+(void)DestroyInstance;
+(DebugManager*)GetInstance;

-(void)Init;
-(void)Term;
-(void)TerminateBonjourService;

-(void)CreateServer;
-(void)HandleClientConnectedWithSocket:(CFSocketNativeHandle)inSocket;
-(void)ReceivedNetworkPacket:(NSDictionary*)message viaConnection:(Connection*)connection;

-(void)netService:(NSNetService*)sender didNotPublish:(NSDictionary*)errorDict;

-(void)DrawString:(NSString*)str locX:(int)in_X locY:(int)in_Y;
-(void)DrawString:(NSString*)str locX:(int)in_X locY:(int)in_Y size:(int)inSize red:(float)inRed blue:(float)inBlue green:(float)inGreen;

-(void)DrawOrtho:(CFTimeInterval)inTimeStep;

-(void)ProcessMessage:(Message*)inMsg;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

-(void)DebugMenuToggle;
-(void)RegisterDebugMenuItem:(NSString*)inName WithCallback:(NSObject<DebugMenuCallback>*)inCallback;
-(void)UnregisterDebugMenuItem:(NSString*)inName;

-(void)ToggleDebugGameState:(id)inStateType;
-(BOOL)DebugGameStateActive;

-(void)SpawnPickRay:(Vector4*)inRay;
-(void)DrawPickRay;

@end