//
//  WAVSoundSource.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "WAVSoundSource.h"
#import "Streamer.h"

@implementation WAVSoundSource

-(SoundSource*)InitWithData:(NSData*)inData params:(SoundSourceParams*)inParams
{
    [super InitWithData:inData params:inParams];
    
    memset(&mFormatChunk, 0, sizeof(WAVFormatChunk));
    memset(&mDataChunk, 0, sizeof(WAVDataChunk));
    mPCMData = NULL;
    
    StreamerParams streamerParams;
    [Streamer InitDefaultParams:&streamerParams];
    
    streamerParams.mType = STREAMER_TYPE_DATA;
    streamerParams.mData = inData;
    
    Streamer* wavStreamer = [(Streamer*)[Streamer alloc] InitWithParams:&streamerParams];
    
    [wavStreamer StreamInto:&mHeader size:sizeof(WAVFileHeader)];
    
    mHeader.mChunkId = CFSwapInt32BigToHost(mHeader.mChunkId);
    NSAssert(mHeader.mChunkId == 'RIFF', @"RIFF was not found in the header of the WAV file");
    
    mHeader.mChunkSize = CFSwapInt32LittleToHost(mHeader.mChunkSize);
    
    mHeader.mFormat = CFSwapInt32BigToHost(mHeader.mFormat);
    NSAssert(mHeader.mFormat == 'WAVE', @"WAVE was not the format of the WAV file");
    
    while(![wavStreamer Finished])
    {
        u32 curSubChunkId = 0;
        
        if ([wavStreamer BytesRemaining] < sizeof(u32))
        {
            break;
        }
        
        [wavStreamer StreamInto:&curSubChunkId size:sizeof(u32)];
        
        curSubChunkId = CFSwapInt32BigToHost(curSubChunkId);
        
        switch(curSubChunkId)
        {
            case 'fmt ':
            {
                [self ParseFormatChunk:wavStreamer];
                break;
            }
            
            case 'data':
            {
                [self ParseDataChunk:wavStreamer];
                break;
            }
            
            default:
            {
                // Unknown chunk, just skip ahead to the next chunk
                
                u32 chunkSize = 0;
                [wavStreamer StreamInto:&chunkSize size:sizeof(u32)];
                
                chunkSize = CFSwapInt32LittleToHost(chunkSize);
                
                [wavStreamer SeekRelative:chunkSize];
                break;
            } 
        }
    }
    
    mSampleRate = mFormatChunk.mSampleRate;
    mBitsPerSample = mFormatChunk.mBitsPerSample;
    mNumSamples = mDataChunk.mDataChunkSize / (mFormatChunk.mNumChannels * (mFormatChunk.mBitsPerSample / 8));
    mNumChannels = mFormatChunk.mNumChannels;
            
    if (mFormatChunk.mNumChannels == 2)
    {
        if (mBitsPerSample == 16)
        {
            mFormat = AL_FORMAT_STEREO16;
        }
        else if (mBitsPerSample == 8)
        {
            mFormat = AL_FORMAT_STEREO8;
        }
        else
        {
            NSAssert(FALSE, @"Unexpected value for bits per sample");
        }
    }
    else if (mFormatChunk.mNumChannels == 1)
    {
        if (mBitsPerSample == 16)
        {
            mFormat = AL_FORMAT_MONO16;
        }
        else if (mBitsPerSample == 8)
        {
            mFormat = AL_FORMAT_MONO8;
        }
        else
        {
            NSAssert(FALSE, @"Unexpected value for bits per sample");
        }
    }
    else
    {
        NSAssert(FALSE, @"Unexpected number of channels");
    }
    
    [self CreateALBuffer:mPCMData size:mDataChunk.mDataChunkSize];

    [wavStreamer release];
    
    return self;
}

-(void)ParseFormatChunk:(Streamer*)inStreamer
{
    u32 subChunkSize = 0;
    [inStreamer StreamInto:&subChunkSize size:sizeof(u32)];
    
    subChunkSize = CFSwapInt32LittleToHost(subChunkSize);
    NSAssert(subChunkSize == 16, @"Only PCM WAV files are supported.  So 16 bytes should follow in the chunk");
    
    [inStreamer StreamInto:&mFormatChunk size:sizeof(WAVFormatChunk)];
 
    mFormatChunk.mAudioFormat = CFSwapInt16LittleToHost(mFormatChunk.mAudioFormat);
    NSAssert(mFormatChunk.mAudioFormat == WAV_FILE_FORMAT_PCM, @"Only PCM uncompressed WAV files are supported");
    
    mFormatChunk.mNumChannels = CFSwapInt16LittleToHost(mFormatChunk.mNumChannels);
    NSAssert( (mFormatChunk.mNumChannels == 1) || (mFormatChunk.mNumChannels == 2), @"Only 1 or 2 channel sound is supported");
    
    mFormatChunk.mSampleRate = CFSwapInt32LittleToHost(mFormatChunk.mSampleRate);
    
    mFormatChunk.mByteRate = CFSwapInt32LittleToHost(mFormatChunk.mByteRate);
    mFormatChunk.mBlockAlign = CFSwapInt16LittleToHost(mFormatChunk.mBlockAlign);
    
    mFormatChunk.mBitsPerSample = CFSwapInt16LittleToHost(mFormatChunk.mBitsPerSample);

    NSAssert(mFormatChunk.mByteRate == (mFormatChunk.mSampleRate * mFormatChunk.mNumChannels * (mFormatChunk.mBitsPerSample / 8)),
                @"Byte rate is inconsistent with sample rate, number of channels, and sample size");
    NSAssert(mFormatChunk.mBlockAlign == (mFormatChunk.mNumChannels * (mFormatChunk.mBitsPerSample / 8)),
                @"Block align is inconsistent with number of channels and sample size");
}

-(void)ParseDataChunk:(Streamer*)inStreamer
{
    [inStreamer StreamInto:&mDataChunk size:(sizeof(WAVDataChunk))];
    mDataChunk.mDataChunkSize = CFSwapInt32LittleToHost(mDataChunk.mDataChunkSize);
    
    mPCMData = [inStreamer GetCurrentDataPointer];
    [inStreamer SeekRelative:mDataChunk.mDataChunkSize];
}

@end