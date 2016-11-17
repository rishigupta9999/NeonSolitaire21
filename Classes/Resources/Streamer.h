//
//  Streamer.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

typedef enum
{
    STREAMER_TYPE_DATA,
    STREAMER_TYPE_FILE,
    STREAMER_TYPE_MAX
} StreamerType;

typedef struct
{
    StreamerType    mType;

    union
    {
        FILE*       mFileHandle;
        NSData*     mData;
    };
    
} StreamerParams;

@interface Streamer : NSObject
{
    StreamerParams  mParams;
    
    u32             mOffset;
    unsigned char*  mDataBuffer;
}

-(Streamer*)InitWithParams:(StreamerParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(StreamerParams*)outParams;

-(void)StreamInto:(void*)outData size:(u32)inNumBytes;
-(unsigned char*)GetCurrentDataPointer;

-(BOOL)Finished;

-(void)SeekRelative:(u32)inOffsetBytes;
-(u32)BytesRemaining;

@end