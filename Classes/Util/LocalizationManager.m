//
//  LocalizationManager.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "LocalizationManager.h"

static LocalizationManager* sInstance = NULL;

// ISO 639-1
static const NSString *LANGUAGE_CHINESE		= @"zh-Hans";
static const NSString *LANGUAGE_KOREAN		= @"ja"; 
static const NSString *LANGUAGE_JAPANESE	= @"ko"; 

// PEFIGS Fonts: Latin: ( Portuguese + English + French + Italian + German + Spanish )
static const NSString* FONT_PEFIGS_NARROW   = @"Arial Narrow";
static const NSString* FONT_PEFIGS_NORMAL	= @"Arial";
static const NSString* FONT_PEFIGS_STYLISH	= @"Becker Black NF";

// CJK Fonts ( Chinese + Japanese + Korean )
// Unicode: Cryillic, WGL, Thai, Indic.
// Currently not supported.
static const NSString* FONT_CJK_NARROW      = @"Arial Narrow";      // Not a CJK Font
static const NSString* FONT_CJK_NORMAL		= @"Arial";             // Not a CJK Font
static const NSString* FONT_CJK_STYLISH		= @"Becker Black NF";   // Not a CJK Font

@implementation LocalizationManager

-(LocalizationManager*)Init
{
    NSArray		*preferredLangs = [NSLocale preferredLanguages];
	NSString	*mainLanguage	= (NSString*)[preferredLangs objectAtIndex:0];
    
	// Assume we are in a PEFIGS region
    mFonts[NEON_FONT_NARROW]    = (NSString*)FONT_PEFIGS_NARROW;
    mFonts[NEON_FONT_NORMAL]	= (NSString*)FONT_PEFIGS_NORMAL;
    mFonts[NEON_FONT_STYLISH]	= (NSString*)FONT_PEFIGS_STYLISH;
    
	// Are we in a CJK region instead?
    if (	[mainLanguage compare:(NSString*)LANGUAGE_CHINESE	]		== NSOrderedSame	||
			[mainLanguage compare:(NSString*)LANGUAGE_JAPANESE	]		== NSOrderedSame	||
			[mainLanguage compare:(NSString*)LANGUAGE_KOREAN	]		== NSOrderedSame	)
    {
		// Use the CJK font
        mFonts[NEON_FONT_NARROW]    = (NSString*)FONT_CJK_NARROW;
        mFonts[NEON_FONT_NORMAL]	= (NSString*)FONT_CJK_NORMAL;
        mFonts[NEON_FONT_STYLISH]	= (NSString*)FONT_CJK_STYLISH;
    }
	
	// TODO Form a system that uses a primary or secondary language that we have localized
    
    for (int curFont = 0; curFont < NEON_FONT_NUM; curFont++)
    {
        [mFonts[curFont] retain];
    }

    return self;
}

-(void)dealloc
{
    for (int curFont = 0; curFont < NEON_FONT_NUM; curFont++)
    {
        [mFonts[curFont] release];
    }
    
    [super dealloc];
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create LocalizationManager");
    sInstance = [(LocalizationManager*)[LocalizationManager alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to destroy a NULL LocalizationManager");
    [sInstance release];
    
    sInstance = NULL;
}

+(LocalizationManager*)GetInstance
{
    return sInstance;
}

-(NSString*)GetFontForType:(NeonFontType)inFontType
{
    NSAssert( ((inFontType >= NEON_FONT_NORMAL) && (inFontType < NEON_FONT_INVALID)), @"Out-of-range font type specified");
    return mFonts[inFontType];
}

@end