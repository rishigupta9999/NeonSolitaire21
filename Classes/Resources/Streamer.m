//
//  Streamer.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "Streamer.h"

@implementation Streamer

-(Streamer*)InitWithParams:(StreamerParams*)inParams
{
    memcpy(&mParams, inParams, sizeof(StreamerParams));
    
    mOffset = 0;
    mDataBuffer = NULL;
    
    switch(mParams.mType)
    {
        case STREAMER_TYPE_DATA:
        {
            [mParams.mData retain];
            mDataBuffer = (unsigned char*)[mParams.mData bytes];
            break;
        }
        
        case STREAMER_TYPE_FILE:
        {
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown streamer type.");
            break;
        }
    }
    
    return self;
}

-(void)dealloc
{
    switch(mParams.mType)
    {
        case STREAMER_TYPE_DATA:
        {
            [mParams.mData release];
            break;
        }
        
        default:
        {
            break;
        }
    }

    [super dealloc];
}

+(void)InitDefaultParams:(StreamerParams*)outParams
{
    outParams->mType = STREAMER_TYPE_DATA;
    outParams->mData = NULL;
}

-(void)StreamInto:(void*)outData size:(u32)inNumBytes
{
    switch(mParams.mType)
    {
        case STREAMER_TYPE_DATA:
        {
            memcpy(outData, mDataBuffer + mOffset, inNumBytes);
            mOffset += inNumBytes;
            
#if NEON_DEBUG
            NSAssert(mOffset <= [mParams.mData length], @"Attempting to read past end of buffer.");
#endif
            break;
        }
        
        case STREAMER_TYPE_FILE:
        {
            fread(outData, 1, inNumBytes, mParams.mFileHandle);
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown streamer type.");
            break;
        }
    }
}

-(BOOL)Finished
{
    NSAssert(mParams.mType == STREAMER_TYPE_DATA, @"Can only call Finished on an NSData type streamer");
    
    return (mOffset >= [mParams.mData length]);
}

-(unsigned char*)GetCurrentDataPointer
{
    NSAssert(mParams.mType == STREAMER_TYPE_DATA, @"Can only call GetCurrentDataPointer on an NSData type streamer");
    
    return (mDataBuffer + mOffset);
}

-(void)SeekRelative:(u32)inOffsetBytes
{
    NSAssert(mParams.mType == STREAMER_TYPE_DATA, @"Can only call SeekRelative on an NSData type streamer");

    mOffset += inOffsetBytes;
    
    NSAssert((mOffset >= 0) && (mOffset <= [mParams.mData length]), @"This seek causes the pointer to go before the beginning of the file, or past the end");
}

-(u32)BytesRemaining
{
    NSAssert(mParams.mType == STREAMER_TYPE_DATA, @"Can only call BytesRemaining on an NSData type streamer");
    
    return [mParams.mData length] - mOffset;
}

@end