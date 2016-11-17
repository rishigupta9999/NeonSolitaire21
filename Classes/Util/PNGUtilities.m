//
//  PNGUtilities.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "PNGUtilities.h"
#import "png.h"

#import "ResourceManager.h"

typedef struct
{
    unsigned char*  mBuffer;
    u32             mBufferOffset;
    u32             mBufferSize;
} PNGContext;

static PNGContext* sCurPNGContext = NULL;

static BOOL VerifyHeader(void* inBuffer)
{
    BOOL valid = !png_sig_cmp(inBuffer, 0, 8);
    return valid;
}

static void CreatePNGContext()
{
    assert(sCurPNGContext == NULL);
    
    sCurPNGContext = malloc(sizeof(PNGContext));
    
    sCurPNGContext->mBuffer = NULL;
    sCurPNGContext->mBufferOffset = 0;
    sCurPNGContext->mBufferSize = 0;
}

static void PngReadFunction(png_struct* inPngPtr, png_byte* outData, png_size_t inLength)
{
    PNGContext* context = (PNGContext*)(png_get_io_ptr(inPngPtr));
    memcpy(outData, context->mBuffer + context->mBufferOffset, inLength);
    
    context->mBufferOffset += inLength;
}

BOOL ReadPNG(NSString* inFilename, PNGInfo* outInfo)
{
    NSNumber* handle = NULL;
    
    if ([inFilename isAbsolutePath])
    {
        handle = [[ResourceManager GetInstance] LoadAssetWithPath:inFilename];
    }
    else
    {
        handle = [[ResourceManager GetInstance] LoadAssetWithName:inFilename];
    }
    
    NSData* data = [[ResourceManager GetInstance] GetDataForHandle:handle];
    
    BOOL retVal = ReadPNGData(data, outInfo);
    
    [[ResourceManager GetInstance] UnloadAssetWithHandle:handle];
    
    return retVal;
}

BOOL ReadPNGData(NSData* inData, PNGInfo* outInfo)
{
    void* buffer = (void*)[inData bytes];
    
    return ReadPNGBytes(buffer, outInfo);
}

BOOL ReadPNGBytes(unsigned char* inBytes, PNGInfo* outInfo)
{    
    void* buffer = inBytes;
    
    // Verify the header information
    BOOL valid = VerifyHeader(buffer);
    
    if (!valid)
    {
        return FALSE;
    }

    // Create the read struct that libpng uses for maintaing its state information
    png_struct* readStruct = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    
    // Create the info struct that libpng uses for other state information
    png_info* infoStruct = png_create_info_struct(readStruct);
    png_info* endInfoStruct = png_create_info_struct(readStruct);
    
    PNGContext context;
    
    context.mBuffer = buffer;
    context.mBufferOffset = 0;
    context.mBufferSize = 0;

    // We don't want the png library doing file IO for us.  We'll supply it with data as it needs.
    png_set_read_fn(readStruct, &context, PngReadFunction);
    
    // Actually read the png
    png_read_png(readStruct, infoStruct, PNG_TRANSFORM_IDENTITY, NULL);
    
    assert(png_get_bit_depth(readStruct, infoStruct) == 8);
    
    int imageWidth = png_get_image_width(readStruct, infoStruct);
    int imageHeight = png_get_image_height(readStruct, infoStruct);
    
    int bytesPerPixel = png_get_rowbytes(readStruct, infoStruct) / imageWidth;
    
    assert((bytesPerPixel == 3 || bytesPerPixel == 4));
    
    // Now let's save it in RGBA format suitable for OpenGL
    int size = sizeof(u8) * 4 * png_get_image_width(readStruct, infoStruct) * png_get_image_height(readStruct, infoStruct);
    
    outInfo->mImageData = malloc(size);
    
    u8** rowPointers = png_get_rows(readStruct, infoStruct);
    
    outInfo->mHeight = imageHeight;
    outInfo->mWidth = imageWidth;
    
    for (int curRow = 0; curRow < imageHeight; curRow++)
    {
        for (int curCol = 0; curCol < imageWidth; curCol++)
        {
            int writeIndex = ((curRow * imageWidth) + (curCol)) * 4;
            int readIndex = curCol * bytesPerPixel;
            
            u8  r = (rowPointers[curRow])[readIndex++];
            u8  g = (rowPointers[curRow])[readIndex++];
            u8  b = (rowPointers[curRow])[readIndex++];
            u8  a = 0xFF;
            
            if (bytesPerPixel == 4)
            {
                a = (rowPointers[curRow])[readIndex++];
            }
            
            outInfo->mImageData[writeIndex++] = r;
            outInfo->mImageData[writeIndex++] = g;
            outInfo->mImageData[writeIndex++] = b;
            outInfo->mImageData[writeIndex] = a;
            
        }
    }
    
    if (setjmp(png_jmpbuf(readStruct)))
    {
        assert(FALSE);
        return FALSE;
    }
    
    // Have the png library free the memory associated with this read struct
    png_destroy_read_struct(&readStruct, &infoStruct, &endInfoStruct);
            
    return TRUE;
}

static void WritePNGMemoryCallback(png_structp inPngPtr, png_bytep inPngData, png_size_t inDataSize)
{
    memcpy(sCurPNGContext->mBuffer + sCurPNGContext->mBufferOffset, inPngData, inDataSize);
    sCurPNGContext->mBufferOffset += inDataSize;
}

static void FlushPNGMemoryCallback(png_structp inPngPtr)
{
}

static void InitWritePNG(FILE* inOutputFile, png_structp* outPngPtr, png_infop* outInfoPtr)
{
    *outPngPtr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    
    png_structp png_ptr = *outPngPtr;
        
    if (png_ptr == NULL)
    {
        fclose(inOutputFile);
        
        printf("Could not allocate write struct.  Nothing was generated.\n");
        return;
    }

    *outInfoPtr = png_create_info_struct(png_ptr);
    
    png_infop info_ptr = *outInfoPtr;
    
    if (info_ptr == NULL)
    {
       png_destroy_write_struct(&png_ptr, (png_infopp)NULL);
       fclose(inOutputFile);
       
       printf("Could not allocate write info struct.  Nothing was generated.\n");
       return;
    }
    
    if (setjmp(png_jmpbuf(png_ptr)))
    {
       png_destroy_write_struct(&png_ptr, &info_ptr);
       fclose(inOutputFile);
       
       printf("LibPng encountered an internal error.  Hopefully it generated some useful error messages.\n");
       return;
    }

    if (inOutputFile != NULL)
    {
        png_init_io(png_ptr, inOutputFile);
    }
    else
    {
        png_set_write_fn(*outPngPtr, NULL, WritePNGMemoryCallback, FlushPNGMemoryCallback);
        assert(sCurPNGContext == NULL);
        
        CreatePNGContext();
    }
}

static void EndWritePNG(png_structp* inPngPtr, png_infop* inInfoPtr)
{
    png_write_end(*inPngPtr, *inInfoPtr);
    png_destroy_write_struct(inPngPtr, inInfoPtr);
}

void WritePNG(unsigned char* inImageData, NSString* inFilename, int inWidth, int inHeight)
{
    NSString *prevWorkingDir = [[NSFileManager defaultManager] currentDirectoryPath];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:@"~/"];
    
    FILE* file = fopen([inFilename UTF8String], "w");

    // Couldn't open file for writing
    assert(file != NULL);

    png_structp png_ptr = NULL;
    png_infop info_ptr = NULL;
        
    InitWritePNG(file, &png_ptr, &info_ptr);
        
    png_byte** imageData = malloc(sizeof(png_byte*) * inHeight);
    
    png_set_IHDR(   png_ptr, info_ptr,
                    inWidth, inHeight, 8, PNG_COLOR_TYPE_RGB_ALPHA,
                    PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT,
                    PNG_FILTER_TYPE_DEFAULT );
    
    for (int y = 0; y < inHeight; y++)
    {
        imageData[y] = malloc(sizeof(png_byte) * inWidth * 4);
        
        memcpy(imageData[y], &((int*)inImageData)[inWidth * y], inWidth * 4);
    }
        
    png_set_rows(png_ptr, info_ptr, imageData);
    png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, NULL);
    
    for (int y = 0; y < inHeight; y++)
    {
        free(imageData[y]);
    }
        
    free(imageData);
    EndWritePNG(&png_ptr, &info_ptr);
    
    fclose(file);
    
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:prevWorkingDir];
}

void WritePNGMemory(unsigned char* inImageData, int inWidth, int inHeight, unsigned char** outPNGData, u32* outPNGDataSize)
{
    png_structp png_ptr = NULL;
    png_infop info_ptr = NULL;
            
    InitWritePNG(NULL, &png_ptr, &info_ptr);
    
    // Create a buffer double the size of raw RGBA data.  Pretty sure we won't exceed this
    int memoryBufferSize = (inWidth * inHeight * 4) * 2;
    
    sCurPNGContext->mBuffer = malloc(memoryBufferSize);
    sCurPNGContext->mBufferSize = memoryBufferSize;
        
    png_byte** imageData = malloc(sizeof(png_byte*) * inHeight);
    
    png_set_IHDR(   png_ptr, info_ptr,
                    inWidth, inHeight, 8, PNG_COLOR_TYPE_RGB_ALPHA,
                    PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT,
                    PNG_FILTER_TYPE_DEFAULT );
    
    for (int y = 0; y < inHeight; y++)
    {
        imageData[y] = malloc(sizeof(png_byte) * inWidth * 4);
        
        memcpy(imageData[y], &((int*)inImageData)[inWidth * y], inWidth * 4);
    }
        
    png_set_rows(png_ptr, info_ptr, imageData);
    png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, NULL);
    
    for (int y = 0; y < inHeight; y++)
    {
        free(imageData[y]);
    }
        
    free(imageData);
    EndWritePNG(&png_ptr, &info_ptr);
    
    *outPNGData = sCurPNGContext->mBuffer;
    *outPNGDataSize = sCurPNGContext->mBufferOffset;
    
    free(sCurPNGContext);
    sCurPNGContext = NULL;
}