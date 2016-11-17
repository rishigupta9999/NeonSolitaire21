//
//  LocalizationManager.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

typedef enum
{
    NEON_FONT_NARROW,
    NEON_FONT_NORMAL,
    NEON_FONT_STYLISH,
    NEON_FONT_NUM,
    NEON_FONT_INVALID = NEON_FONT_NUM
} NeonFontType;

@interface LocalizationManager : NSObject
{
    NSString* mFonts[NEON_FONT_NUM];
}

-(LocalizationManager*)Init;
-(void)dealloc;

+(void)CreateInstance;
+(void)DestroyInstance;
+(LocalizationManager*)GetInstance;

-(NSString*)GetFontForType:(NeonFontType)inFontType;

@end