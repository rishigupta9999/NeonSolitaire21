//
//  NeonUtilities.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#ifdef __cplusplus
extern "C"
{
#endif

#import "NeonMath.h"
#import "MessageChannel.h"

@class Neon21AppDelegate;
@class EAGLView;

#define MIN_FRAMEBUFFER_DIMENSION   (16)

// Pretty Printing
#define NEON_PRINT_TABS(x)  { for (int i = 0; i < x; i++) printf("\t"); }

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

// Error Handling
void NeonGLError();
void NeonALError();

// Screen Capture
void DumpPPM(unsigned int* inImageData, const char* inFileName, int inWidth, int inHeight);
void DumpPPMAlpha(unsigned char* inImageData, const char* inFileName, int inWidth, int inHeight);

void SaveScreen(NSString* inFilename);
void SaveScreenRect(NSString* inFilename, int inWidth, int inHeight);
void SaveScreenRectMemory(unsigned char* inBuffer, int inWidth, int inHeight);

typedef struct
{
    GLint   mViewport[4];
    GLint   mFB;
    GLint   mSrcBlend, mDestBlend;
    GLint   mBlendEnabled;
    GLint   mDepthTestEnabled;
    GLint   mCullingEnabled;
    GLint   mLightingEnabled;
    GLint   mTextureEnabled;
    GLint   mTextureBinding;
    GLint   mTexEnvMode;
    GLint   mMatrixMode;
    GLint   mVertexArrayEnabled, mColorArrayEnabled, mTexCoordArrayEnabled, mNormalArrayEnabled;
} GLState;

// OpenGL State Management
void SaveGLState(GLState* inState);
void RestoreGLState(GLState* inState);

// OpenGL Color Utilities
u32  GetNumChannels(GLenum inFormat);
u32  GetTypeSize(GLenum inFormat);

// Device Characteristics
u32  GetScreenVirtualWidth();
u32  GetScreenVirtualHeight();

u32  GetScreenAbsoluteWidth();
u32  GetScreenAbsoluteHeight();

u32		GetBaseHeight();
u32		GetBaseWidth();
float	GetBaseAspect();

BOOL	GetDevicePad();
BOOL    GetDeviceiPhoneTall();

void VirtualToScreenRect(Rect2D* inVirtual, Rect2D* outScreen);

void SetScreenRetina(BOOL inRetina);
BOOL GetScreenRetina();

float GetScreenScaleFactor();
float GetRetinaScaleFactor();
float GetContentScaleFactor();
float GetTextScaleFactor();

// String Formatting
NSString* NeonFormatTime(CFTimeInterval inTime, int inSecondsSigDigs);

// Global Accessors
MessageChannel*     GetGlobalMessageChannel();
Neon21AppDelegate*  GetAppDelegate();
EAGLView*           GetEAGLView();

// Timer
void            NeonStartTimer();
CFTimeInterval  NeonEndTimer();

#ifdef __cplusplus
}
#endif