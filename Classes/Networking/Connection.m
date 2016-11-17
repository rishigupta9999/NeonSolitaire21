//
//  Connection.m
//  NeonEngineDebugger
//
//  Created by Rishi Gupta on 3/14/14.
//  Copyright (c) 2014 Neon Games LLC. All rights reserved.
//

#import "Connection.h"

void readStreamEventHandler(CFReadStreamRef stream, CFStreamEventType eventType, void *info)
{
    Connection* connection = (Connection*)info;
    [connection ReadStreamHandleEvent:eventType];
}

void writeStreamEventHandler(CFWriteStreamRef stream, CFStreamEventType eventType, void *info)
{
    Connection* connection = (Connection*)info;
    [connection WriteStreamHandleEvent:eventType];
}

@implementation Connection

@synthesize Delegate = mDelegate;

-(Connection*)initWithServiceEntry:(ServiceEntry*)inServiceEntry
{
    [self Clean];
    
    mServiceEntry = inServiceEntry;
    
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (CFStringRef)mServiceEntry->mHostName, (unsigned int)mServiceEntry->mPort, &mReadStream, &mWriteStream);
    [self SetupSocketStreams];
    
    return self;
}

-(id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle
{
    [self Clean];

    mConnectedSocketHandle = nativeSocketHandle;
    
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, mConnectedSocketHandle, &mReadStream, &mWriteStream);
    [self SetupSocketStreams];

    return self;
}

-(void)SetupSocketStreams
{
    // Indicate that we want socket to be closed whenever streams are closed
    CFReadStreamSetProperty(mReadStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(mWriteStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);

    // We will be handling the following stream events
    CFOptionFlags registeredEvents = kCFStreamEventOpenCompleted | kCFStreamEventHasBytesAvailable | kCFStreamEventCanAcceptBytes | kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred;
  
    // Setup stream context - reference to 'self' will be passed to stream event handling callbacks
    CFStreamClientContext ctx = {0, self, NULL, NULL, NULL};

    // Specify callbacks that will be handling stream events
    CFReadStreamSetClient(mReadStream, registeredEvents, readStreamEventHandler, &ctx);
    CFWriteStreamSetClient(mWriteStream, registeredEvents, writeStreamEventHandler, &ctx);
  
    // Schedule streams with current run loop
    CFReadStreamScheduleWithRunLoop(mReadStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFWriteStreamScheduleWithRunLoop(mWriteStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);

    CFReadStreamOpen(mReadStream);
    CFWriteStreamOpen(mWriteStream);
}

-(void)Clean
{
    // Create buffers
    mIncomingDataBuffer = [[NSMutableData alloc] init];
    mOutgoingDataBuffer = [[NSMutableData alloc] init];

    mReadStreamOpen = FALSE;
    mWriteStreamOpen = FALSE;
    
    mPacketBodySize = -1;
}

-(void)dealloc
{
    [mServiceEntry release];
    
    [super dealloc];
}

- (void)Close
{
    // Cleanup read stream
    if (mReadStream != nil)
    {
        CFReadStreamUnscheduleFromRunLoop(mReadStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFReadStreamClose(mReadStream);
        CFRelease(mReadStream);
        mReadStream = NULL;
    }
  
    // Cleanup write stream
    if (mWriteStream != nil)
    {
        CFWriteStreamUnscheduleFromRunLoop(mWriteStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFWriteStreamClose(mWriteStream);
        CFRelease(mWriteStream);
        mWriteStream = NULL;
    }
  
    // Cleanup buffers
    [mIncomingDataBuffer release];
    mIncomingDataBuffer = NULL;

    [mOutgoingDataBuffer release];
    mOutgoingDataBuffer = NULL;

    // Stop net service?
    if (mServiceEntry.NetService != nil)
    {
        [mServiceEntry.NetService stop];
    }
}

-(void)SendNetworkPacket:(NSDictionary*)packet
{
  // Encode packet
  NSData* rawPacket = [NSKeyedArchiver archivedDataWithRootObject:packet];
  
  // Write header: length of raw packet
  int packetLength = (int)[rawPacket length];
  [mOutgoingDataBuffer appendBytes:&packetLength length:sizeof(int)];
  
  // Write body: encoded NSDictionary
  [mOutgoingDataBuffer appendData:rawPacket];
  
  // Try to write to stream
  [self WriteOutgoingBufferToStream];
}

-(void)ReadFromStreamIntoIncomingBuffer
{
    // Temporary buffer to read data into
    UInt8 buf[1024];

    // Try reading while there is data
    while(CFReadStreamHasBytesAvailable(mReadStream))
    {
        CFIndex len = CFReadStreamRead(mReadStream, buf, sizeof(buf));
        
        if (len <= 0)
        {
            // Either stream was closed or error occurred. Close everything up and treat this as "connection terminated"
            [self Close];
            return;
        }

        [mIncomingDataBuffer appendBytes:buf length:len];
    }

    // Try to extract packets from the buffer.
    //
    // Protocol: header + body
    //  header: an integer that indicates length of the body
    //  body: bytes that represent encoded NSDictionary

    // We might have more than one message in the buffer - that's why we'll be reading it inside the while loop
    
    while(YES)
    {
        // Did we read the header yet?
        if (mPacketBodySize == -1)
        {
            // Do we have enough bytes in the buffer to read the header?
            if ( [mIncomingDataBuffer length] >= sizeof(int) )
            {
                // extract length
                memcpy(&mPacketBodySize, [mIncomingDataBuffer bytes], sizeof(int));

                // remove that chunk from buffer
                NSRange rangeToDelete = {0, sizeof(int)};
                [mIncomingDataBuffer replaceBytesInRange:rangeToDelete withBytes:NULL length:0];
            }
            else
            {
                // We don't have enough yet. Will wait for more data.
                break;
            }
        }
    
        // We should now have the header. Time to extract the body.
        if ([mIncomingDataBuffer length] >= mPacketBodySize)
        {
            // We now have enough data to extract a meaningful packet.
            NSData* raw = [NSData dataWithBytes:[mIncomingDataBuffer bytes] length:mPacketBodySize];
            NSDictionary* packet = [NSKeyedUnarchiver unarchiveObjectWithData:raw];
            [mDelegate ReceivedNetworkPacket:packet viaConnection:self];
            
            // Remove that chunk from buffer
            NSRange rangeToDelete = {0, mPacketBodySize};
            [mIncomingDataBuffer replaceBytesInRange:rangeToDelete withBytes:NULL length:0];

            // We have processed the packet. Resetting the state.
            mPacketBodySize = -1;
        }
        else
        {
            // Not enough data yet. Will wait.
            break;
        }
    }
}

-(void)WriteOutgoingBufferToStream
{
    // Is connection open?
    if (!mReadStreamOpen || !mWriteStreamOpen)
    {
        // No, wait until everything is operational before pushing data through
        return;
    }

    // Do we have anything to write?
    if ([mOutgoingDataBuffer length] == 0)
    {
        return;
    }
  
    // Can stream take any data in?
    if (!CFWriteStreamCanAcceptBytes(mWriteStream))
    {
        return;
    }
  
    // Write as much as we can
    CFIndex writtenBytes = CFWriteStreamWrite(mWriteStream, [mOutgoingDataBuffer bytes], [mOutgoingDataBuffer length]);

    if (writtenBytes == -1)
    {
        // Error occurred. Close everything up.
        [self Close];
        return;
    }

    NSRange range = {0, writtenBytes};
    [mOutgoingDataBuffer replaceBytesInRange:range withBytes:NULL length:0];
}

-(void)ReadStreamHandleEvent:(CFStreamEventType)event
{
    if (event == kCFStreamEventOpenCompleted)
    {
        mReadStreamOpen = YES;
    }
    else if (event == kCFStreamEventHasBytesAvailable)
    {
        // Read as many bytes from the stream as possible and try to extract meaningful packets
        [self ReadFromStreamIntoIncomingBuffer];
    }
    
    // Connection has been terminated or error encountered (we treat them the same way)
    else if (event == kCFStreamEventEndEncountered || event == kCFStreamEventErrorOccurred)
    {
        [self Close];
    }
}

-(void)WriteStreamHandleEvent:(CFStreamEventType)event
{
    if (event == kCFStreamEventOpenCompleted)
    {
        mWriteStreamOpen = YES;
    }
    else if (event == kCFStreamEventCanAcceptBytes)
    {
        [self WriteOutgoingBufferToStream];
    }
    // Connection has been terminated or error encountered (we treat them the same way)
    else if (event == kCFStreamEventEndEncountered || event == kCFStreamEventErrorOccurred)
    {
        [self Close];
    }
}

@end
