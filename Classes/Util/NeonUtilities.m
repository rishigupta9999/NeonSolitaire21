//
//  NeonUtilities.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "Neon21AppDelegate.h"
#import "NeonUtilities.h"
#import "NeonTypes.h"
#import "PNGUtilities.h"
#import "png.h"

#define BASE_HEIGHT	(320)
#define BASE_WIDTH	(480)

static BOOL sScreenIsRetina = FALSE;

#pragma mark - Error Handling

void NeonGLError()
{
#ifdef NEON_DEBUG
    GLenum texError = glGetError();

    if (texError != 0)
    {
        printf("OpenGL Error %x encountered\n", texError);
    }
#endif
}

void NeonALError()
{
#ifdef NEON_DEBUG
    ALenum error = alGetError();

    if (error != AL_NO_ERROR)
    {
        printf("OpenAL Error %x encountered\n", error);
    }
#endif
}

#pragma mark - Screen Capture

void DumpPPM(unsigned int* inImageData, const char* inFileName, int inWidth, int inHeight)
{
    NSString *prevWorkingDir = [[NSFileManager defaultManager] currentDirectoryPath];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:NSTemporaryDirectory()];
    
    FILE* file = fopen(inFileName, "w");
    
    static const int WRITE_BUFFER_LENGTH = 128;
    char writeBuffer[WRITE_BUFFER_LENGTH];
    
    snprintf(writeBuffer, WRITE_BUFFER_LENGTH, "P3\n%d %d\n255\n", inWidth, inHeight);
    fwrite(writeBuffer, 1, strlen(writeBuffer), file);
    
    for (int row = 0; row < inHeight; row++)
    {
        for (int col = 0; col < inWidth; col++)
        {
            u32 rgbaValue = inImageData[(inWidth * row) + col];
            
            rgbaValue = CFSwapInt32BigToHost(rgbaValue);
            
            u8  r, g, b;
            
            r = (rgbaValue >> 24) & 0xFF;
            g = (rgbaValue >> 16) & 0xFF;
            b = (rgbaValue >> 8) & 0xFF;
            
            snprintf(writeBuffer, WRITE_BUFFER_LENGTH, "%d %d %d\t", r, g, b);
            fwrite(writeBuffer, 1, strlen(writeBuffer), file);
        }
        
        fwrite("\n", 1, 1, file);
    }
            
    fclose(file);
    
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:prevWorkingDir];
}

void DumpPPMAlpha(unsigned char* inImageData, const char* inFileName, int inWidth, int inHeight)
{
    NSString *prevWorkingDir = [[NSFileManager defaultManager] currentDirectoryPath];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:@"/"];
    
    FILE* file = fopen(inFileName, "w");
    
    static const int WRITE_BUFFER_LENGTH = 128;
    char writeBuffer[WRITE_BUFFER_LENGTH];
    
    snprintf(writeBuffer, WRITE_BUFFER_LENGTH, "P3\n%d %d\n255\n", inWidth, inHeight);
    fwrite(writeBuffer, 1, strlen(writeBuffer), file);
    
    for (int row = 0; row < inHeight; row++)
    {
        for (int col = 0; col < inWidth; col++)
        {
            unsigned char alpha = inImageData[(inWidth * row) + col];
            
            snprintf(writeBuffer, WRITE_BUFFER_LENGTH, "%d %d %d\t", alpha, alpha, alpha);
            fwrite(writeBuffer, 1, strlen(writeBuffer), file);
        }
        
        fwrite("\n", 1, 1, file);
    }
            
    fclose(file);
    
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:prevWorkingDir];
}

void SaveScreen(NSString* inFilename)
{
    GLint viewport[4];
    
    NeonGLGetIntegerv(GL_VIEWPORT, viewport);
    
    int width = viewport[2];
    int height = viewport[3];
    
    u8* buffer = malloc(width * height * 4);
    
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    WritePNG(buffer, inFilename, width, height);
    
    free(buffer);
}

void SaveScreenRect(NSString* inFilename, int inWidth, int inHeight)
{
    GLint viewport[4];
    
    NeonGLGetIntegerv(GL_VIEWPORT, viewport);
        
    u8* buffer = malloc(inWidth * inHeight * 4);
    
    glReadPixels(0, 0, inWidth, inHeight, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    WritePNG(buffer, inFilename, inWidth, inHeight);
    
    free(buffer);
}

void SaveScreenRectMemory(unsigned char* inBuffer, int inWidth, int inHeight)
{
    glReadPixels(0, 0, inWidth, inHeight, GL_RGBA, GL_UNSIGNED_BYTE, inBuffer);
}

#pragma mark - OpenGL State Management

static void EnableIfTrue(GLenum inEnum, GLint inEnabled)
{
    if ((inEnum == GL_BLEND) || (inEnum == GL_DEPTH_TEST) || (inEnum == GL_TEXTURE_2D) || (inEnum == GL_CULL_FACE) || (inEnum == GL_LIGHTING))
    {
        if (inEnabled)
        {
            NeonGLEnable(inEnum);
        }
        else
        {
            NeonGLDisable(inEnum);
        }
    }
    else
    {
        if (inEnabled)
        {
            glEnable(inEnum);
        }
        else
        {
            glDisable(inEnum);
        }
    }
}

static void EnableClientStateIfTrue(GLenum inEnum, GLint inEnabled)
{
    if (inEnabled)
    {
        glEnableClientState(inEnum);
    }
    else
    {
        glDisableClientState(inEnum);
    }
}

void SaveGLState(GLState* inState)
{
    NeonGLGetIntegerv(GL_VIEWPORT, inState->mViewport);
    
    NeonGLGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &inState->mFB);
    
    NeonGLGetIntegerv(GL_BLEND_SRC, &inState->mSrcBlend);
    NeonGLGetIntegerv(GL_BLEND_DST, &inState->mDestBlend);
    NeonGLGetIntegerv(GL_BLEND, &inState->mBlendEnabled);
    
    NeonGLGetIntegerv(GL_DEPTH_TEST, &inState->mDepthTestEnabled);
    
    NeonGLGetIntegerv(GL_LIGHTING, &inState->mLightingEnabled);
    NeonGLGetIntegerv(GL_CULL_FACE, &inState->mCullingEnabled);
    
    NeonGLGetIntegerv(GL_TEXTURE_2D, &inState->mTextureEnabled);
    NeonGLGetIntegerv(GL_TEXTURE_BINDING_2D, &inState->mTextureBinding);
    glGetTexEnviv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, &inState->mTexEnvMode);
    
    NeonGLGetIntegerv(GL_MATRIX_MODE, &inState->mMatrixMode);
    
    inState->mVertexArrayEnabled = glIsEnabled(GL_VERTEX_ARRAY);
    inState->mColorArrayEnabled = glIsEnabled(GL_COLOR_ARRAY);
    inState->mTexCoordArrayEnabled = glIsEnabled(GL_TEXTURE_COORD_ARRAY);
    inState->mNormalArrayEnabled = glIsEnabled(GL_NORMAL_ARRAY);
}

void RestoreGLState(GLState* inState)
{
    NeonGLViewport(inState->mViewport[0], inState->mViewport[1], inState->mViewport[2], inState->mViewport[3]);
    
    NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, inState->mFB);
    
    NeonGLBlendFunc(inState->mSrcBlend, inState->mDestBlend);
    EnableIfTrue(GL_BLEND, inState->mBlendEnabled);

    EnableIfTrue(GL_DEPTH_TEST, inState->mDepthTestEnabled);
    
    EnableIfTrue(GL_TEXTURE_2D, inState->mTextureEnabled);
    NeonGLBindTexture(GL_TEXTURE_2D, inState->mTextureBinding);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, inState->mTexEnvMode);
    
    NeonGLMatrixMode(inState->mMatrixMode);
    
    EnableClientStateIfTrue(GL_VERTEX_ARRAY, inState->mVertexArrayEnabled);
    EnableClientStateIfTrue(GL_COLOR_ARRAY, inState->mColorArrayEnabled);
    EnableClientStateIfTrue(GL_TEXTURE_COORD_ARRAY, inState->mTexCoordArrayEnabled);
    EnableClientStateIfTrue(GL_NORMAL_ARRAY, inState->mNormalArrayEnabled);
    
    EnableIfTrue(GL_LIGHTING, inState->mLightingEnabled);
    
    EnableIfTrue(GL_CULL_FACE, inState->mCullingEnabled);
    glColor4f(1.0, 1.0, 1.0, 1.0);
    
    NeonGLError();
}

#pragma mark - OpenGL Color Utilities

u32  GetNumChannels(GLenum inFormat)
{   
    u32 numChannels = 0;
    
    switch(inFormat)
    {
        case GL_RGBA:
        {
            numChannels = 4;
            break;
        }
        
        case GL_RGB:
        {
            numChannels = 3;
            break;
        }
        
        case GL_LUMINANCE_ALPHA:
        {
            numChannels = 2;
            break;
        }
        
        case GL_LUMINANCE:
        case GL_ALPHA:
        {
            numChannels = 1;
            break;
        }
        
        default:
        {
            assert(FALSE);
            break;
        }
    }
    
    return numChannels;
}

u32  GetTypeSize(GLenum inFormat)
{
    u32 size = 0;
    
    switch(inFormat)
    {
        case GL_UNSIGNED_BYTE:
        {
            size = 1;
            break;
        }
        
        case GL_UNSIGNED_SHORT:
        {
            size = 2;
            break;
        }
        
        case GL_FLOAT:
        {
            size = 4;
            break;
        }
        
        default:
        {
            assert(FALSE);
            break;
        }
    }
    
    return size;
}

#pragma mark - Device Characteristics

u32 GetScreenVirtualWidth()
{
    return BASE_WIDTH;
}

u32 GetScreenVirtualHeight()
{
	return BASE_HEIGHT;
}

u32 GetScreenAbsoluteWidth()
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    return rect.size.height;
}

u32 GetScreenAbsoluteHeight()
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    return rect.size.width;
}

u32 GetBaseHeight()
{
	return BASE_HEIGHT;
}

u32 GetBaseWidth()
{
	return BASE_WIDTH;
}

float GetBaseAspect()
{
	return ((float)BASE_WIDTH / (float)BASE_HEIGHT);
}

BOOL GetDevicePad()
{
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return FALSE;
#endif
}

BOOL GetDeviceiPhoneTall()
{
#ifdef UI_USER_INTERFACE_IDIOM
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        if (GetScreenAbsoluteWidth() > 480)
        {
            return TRUE;
        }
    }
#endif
    return FALSE;
}

void VirtualToScreenRect(Rect2D* inVirtual, Rect2D* outScreen)
{
    outScreen->mYMin = inVirtual->mXMin;
    outScreen->mYMax = inVirtual->mXMax;
    
    outScreen->mXMin = GetScreenVirtualHeight() - inVirtual->mYMax;
    outScreen->mXMax = GetScreenVirtualHeight() - inVirtual->mYMin;
}

BOOL GetScreenRetina()
{
    return sScreenIsRetina;
}

void SetScreenRetina(BOOL inRetina)
{
    sScreenIsRetina = inRetina;
}

float GetScreenScaleFactor()
{
    return sScreenIsRetina ? 2.0f : 1.0f;
}

float GetRetinaScaleFactor()
{
	return 2.0f;
}

float GetContentScaleFactor()
{
	if (sScreenIsRetina || GetDevicePad())
	{
		return 2.0f;
	}
	
	return 1.0f;
}

float GetTextScaleFactor()
{
    float scaleFactor = 1.0f;
    
    if (sScreenIsRetina)
    {
        scaleFactor *= 2.0f;
    }
    
    if (GetDevicePad())
    {
        scaleFactor *= 2.0f;
    }
    
    return scaleFactor;
}

#pragma mark - String Formatting

NSString* NeonFormatTime(CFTimeInterval inTime, int inSecondsSigDigs)
{
    static const float DAYS_DIVISOR = (60.0f * 60.0f * 24.0f);
    static const float HOURS_DIVISOR = (60.0f * 60.0f);
    static const float MINUTES_DIVISOR = 60.0f;
    
    int days = (int)(inTime / DAYS_DIVISOR);
    int hours = (int)((inTime - ((float)days * DAYS_DIVISOR)) / HOURS_DIVISOR);
    int minutes = (int)((inTime - ((float)days * DAYS_DIVISOR) + ((float)hours * HOURS_DIVISOR)) / MINUTES_DIVISOR);
    float seconds = inTime - (((float)days * DAYS_DIVISOR) + ((float)hours * HOURS_DIVISOR) + ((float)minutes * MINUTES_DIVISOR));
    
    NSString* retString = NULL;
    
    if (days > 0)
    {
        retString = [NSString stringWithFormat:@"%d:%d:%d:%f", days, hours, minutes, seconds];
    }
    else if (hours > 0)
    {
        retString = [NSString stringWithFormat:@"%d:%d:%f", hours, minutes, seconds];
    }
    else
    {
        int leftDigits = ClampInt(inSecondsSigDigs, 0, 2);
        int rightDigits = LClampInt(inSecondsSigDigs - 2, 0);
        
        // So it seems that stringWithFormat will do some rounding.  So 59.95 seconds could be rounded to 60 seconds
        // which is not what we want.  So truncate the excess bits here.  For example, if we only want 2 significant
        // digits, we would truncate the 0.95 from seconds.
        
        float multiplier = powf(10.0, rightDigits);
        int truncSeconds = (int)(seconds * multiplier);
        seconds = (float)truncSeconds / multiplier;

        retString = [NSString stringWithFormat:@"%d:%0*.*f", minutes, leftDigits, rightDigits, seconds];
    }
    
    return retString;
}

#pragma mark - Global Accessors

MessageChannel* GetGlobalMessageChannel()
{
    return ((Neon21AppDelegate*)[[UIApplication sharedApplication] delegate])->mGlobalMessageChannel;
}

Neon21AppDelegate* GetAppDelegate()
{
    return (Neon21AppDelegate*)[[UIApplication sharedApplication] delegate];
}

EAGLView* GetEAGLView()
{
    return GetAppDelegate().glView;
}

#pragma mark - Timers

static CFTimeInterval sStartTime = 0;

void NeonStartTimer()
{
    sStartTime = CACurrentMediaTime();
}

CFTimeInterval NeonEndTimer()
{
    return CACurrentMediaTime() - sStartTime;
}
