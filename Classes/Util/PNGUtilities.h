//
//  PNGUtilities.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#ifdef __cplusplus
extern "C"
{
#endif

#import "Texture.h"

typedef struct
{
    u32     mWidth;
    u32     mHeight;
    u8*     mImageData;
} PNGInfo;

BOOL ReadPNG(NSString* inFilename, PNGInfo* outInfo);
BOOL ReadPNGBytes(unsigned char* inBytes, PNGInfo* outInfo);
BOOL ReadPNGData(NSData* inData, PNGInfo* outInfo);

void WritePNG(unsigned char* inImageData, NSString* inFilename, int inWidth, int inHeight);
void WritePNGMemory(unsigned char* inImageData, int inWidth, int inHeight, unsigned char** outPNGData, u32* outPNGDataSize);

#ifdef __cplusplus
}
#endif