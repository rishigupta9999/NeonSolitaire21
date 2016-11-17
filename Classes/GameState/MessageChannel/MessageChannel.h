//
//  MessageChannel.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

typedef struct
{
    u32     mId;
    void*   mData;
} Message;

@protocol MessageChannelListener

-(void)ProcessMessage:(Message*)inMsg;

@end

@interface MessageChannel : NSObject
{
    NSMutableArray* mListeners;
    int             mProcessingCount;
    NSMutableArray* mRemoveQueue;
    NSMutableArray* mAddQueue;
}

-(MessageChannel*)Init;
-(void)dealloc;

-(void)BroadcastMessageSync:(Message*)inMsg;
-(void)SendEvent:(u32)inMsgId withData:(void*)inData;
-(void)AddListener:(NSObject<MessageChannelListener>*)inListener;
-(void)RemoveListener:(NSObject<MessageChannelListener>*)inListener;

@end