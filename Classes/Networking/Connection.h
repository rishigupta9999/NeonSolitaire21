//
//  Connection.h
//  NeonEngineDebugger
//
//  Created by Rishi Gupta on 3/14/14.
//  Copyright (c) 2014 Neon Games LLC. All rights reserved.
//

#import "BonjourBrowser.h"

@protocol ConnectionDelegate
-(void)ReceivedNetworkPacket:(NSDictionary*)message viaConnection:(Connection*)connection;
@end

@interface Connection : NSObject
{
    id<ConnectionDelegate> mDelegate;

    CFReadStreamRef     mReadStream;
    CFWriteStreamRef    mWriteStream;
    
    BOOL                mReadStreamOpen;
    BOOL                mWriteStreamOpen;
    
    int                 mPacketBodySize;
    
    ServiceEntry*       mServiceEntry;
    
    NSMutableData*      mIncomingDataBuffer;
    NSMutableData*      mOutgoingDataBuffer;
    
    CFSocketNativeHandle    mConnectedSocketHandle;
}

@property(nonatomic, retain) id<ConnectionDelegate> Delegate;

-(Connection*)initWithServiceEntry:(ServiceEntry*)inServiceEntry;
-(Connection*)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle;
-(void)SetupSocketStreams;

-(void)dealloc;
-(void)Close;

-(void)SendNetworkPacket:(NSDictionary*)packet;
-(void)ReadFromStreamIntoIncomingBuffer;
-(void)WriteOutgoingBufferToStream;

-(void)ReadStreamHandleEvent:(CFStreamEventType)event;
-(void)WriteStreamHandleEvent:(CFStreamEventType)event;

@end
