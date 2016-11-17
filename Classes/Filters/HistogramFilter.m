//
//  HistogramFilter.m
//
//  Copyright 2013 Neon Games. All rights reserved.
//

#import "HistogramFilter.h"
#import "Texture.h"

#define NUM_BUCKETS_DEFAULT     (4)

@implementation HistogramFilter

-(HistogramFilter*)Init
{
    mBuckets = NULL;
    mMaxBucketIndex = 0;
    mTexture = NULL;
    mNumBucketsPerChannel = 0;
    
    mMaxR = 0;
    mMaxG = 0;
    mMaxB = 0;
    
    return self;
}

-(void)SetParams:(HistogramFilterParams*)inParams
{
    if ((inParams->mNumBucketsPerChannel >= 256) || ((inParams->mNumBucketsPerChannel & (inParams->mNumBucketsPerChannel - 1)) != 0))
    {
        NSAssert(FALSE, @"Number of buckets must be smaller than 256 and a power of 2");
    }
    
    if (inParams->mNumBucketsPerChannel != mNumBucketsPerChannel)
    {
        free(mBuckets);
        mBuckets = (int*)malloc(sizeof(int) * inParams->mNumBucketsPerChannel * inParams->mNumBucketsPerChannel * inParams->mNumBucketsPerChannel);
    }
    
    mNumBucketsPerChannel = inParams->mNumBucketsPerChannel;
    
    memset(mBuckets, 0, sizeof(int) * inParams->mNumBucketsPerChannel * inParams->mNumBucketsPerChannel * inParams->mNumBucketsPerChannel);
    
    mMaxBucketIndex = 0;
    mTexture = inParams->mTexture;
    
    mMaxR = 0;
    mMaxG = 0;
    mMaxB = 0;
    
    NSAssert(mTexture->mType == GL_UNSIGNED_BYTE, @"Unsupported type");
    NSAssert(mTexture->mFormat == GL_RGBA || mTexture->mFormat == GL_RGB, @"Unsupported color format");
}

-(void)dealloc
{    
    free(mBuckets);
    
    [super dealloc];
}

+(void)InitDefaultParams:(HistogramFilterParams*)outParams
{
    outParams->mTexture = NULL;
    outParams->mNumBucketsPerChannel = NUM_BUCKETS_DEFAULT;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    int width = [mTexture GetRealWidth];
    int height = [mTexture GetRealHeight];
    
    int numChannels = GetNumChannels(mTexture->mFormat);
    
    int bucketRange = 256 / mNumBucketsPerChannel;
    
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            unsigned char* texelBase = &mTexture->mTexBytes[((y * width) + x) * numChannels];
            
            unsigned char r = texelBase[0];
            unsigned char g = texelBase[1];
            unsigned char b = texelBase[2];
            
            int rIndex = r / bucketRange;
            int gIndex = g / bucketRange;
            int bIndex = b / bucketRange;
            
            int bucketIndex = (bIndex * mNumBucketsPerChannel * mNumBucketsPerChannel) + (rIndex * mNumBucketsPerChannel) + gIndex;
            
            if (bucketIndex != 0)
            {
                mBuckets[bucketIndex]++;
            }
                        
            if (mBuckets[bucketIndex] > mBuckets[mMaxBucketIndex])
            {
                mMaxBucketIndex = bucketIndex;
                
                mMaxR = rIndex;
                mMaxG = gIndex;
                mMaxB = bIndex;
            }
        }
    }
}

-(void)GetMaxColors:(Vector3*)outColors
{
    outColors->mVector[0] = (float)mMaxR / (float)(mNumBucketsPerChannel - 1);
    outColors->mVector[1] = (float)mMaxG / (float)(mNumBucketsPerChannel - 1);
    outColors->mVector[2] = (float)mMaxB / (float)(mNumBucketsPerChannel - 1);
}

@end