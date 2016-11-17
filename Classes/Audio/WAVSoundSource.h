//
//  WAVSoundSource.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "SoundSource.h"

typedef struct
{
    u16 mAudioFormat;
    u16 mNumChannels;
    u32 mSampleRate;
    u32 mByteRate;
    u16 mBlockAlign;
    u16 mBitsPerSample;
} WAVFormatChunk;

typedef struct
{
    u32 mDataChunkSize;
} WAVDataChunk;

typedef struct
{
    u32 mChunkId;
    u32 mChunkSize;
    u32 mFormat;
} WAVFileHeader;

typedef enum
{
    WAV_FILE_FORMAT_PCM = 1
} WAVFileFormat;

@class Streamer;

@interface WAVSoundSource : SoundSource
{
    WAVFileHeader   mHeader;
    WAVFormatChunk  mFormatChunk;
    WAVDataChunk    mDataChunk;
    u8*             mPCMData;
}

-(SoundSource*)InitWithData:(NSData*)inData params:(SoundSourceParams*)inParams;
-(void)ParseFormatChunk:(Streamer*)inStreamer;
-(void)ParseDataChunk:(Streamer*)inStreamer;

@end