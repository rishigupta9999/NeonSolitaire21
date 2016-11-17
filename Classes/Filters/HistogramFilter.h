//
//  HistogramFilter.h
//
//  Copyright 2013 Neon Games. All rights reserved.
//

#import "Filter.h"

typedef struct
{
    Texture*    mTexture;
    int         mNumBucketsPerChannel;
} HistogramFilterParams;

@interface HistogramFilter : Filter
{
    Texture*    mTexture;
    
    int     mNumBucketsPerChannel;
    int     mMaxBucketIndex;
    int*    mBuckets;
    
    int     mMaxR;
    int     mMaxG;
    int     mMaxB;
}

-(HistogramFilter*)Init;
-(void)SetParams:(HistogramFilterParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(HistogramFilterParams*)outParams;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)GetMaxColors:(Vector3*)outColors;

@end