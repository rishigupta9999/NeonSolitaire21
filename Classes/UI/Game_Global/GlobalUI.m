//
//  GlobalUI.m
//  Neon Engine
//
//  Copyright Neon Games LLC - 2011

#import "GlobalUI.h"

static const char *sNeonFontPrefixes[NEONFONT_NUM] = 
{
	"neonblue_",		// NEONFONT_BLUE
	"neonyellow_",		// NEONFONT_YELLOW
};

@implementation GlobalUI

-(void)uiAlloc
{
	[self InitFonts];
}
-(void)dealloc
{
	[self DeallocFonts];
	[self DeallocUserInterface];
	[super dealloc];
}

-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    NSAssert(FALSE, @"This must be overridden by subclasses");
    return FALSE;
}

-(void)InitFont:(ENeonFontColor)fontID;
{
	char fontFileName			[maxIconFileName];
	char curString				[maxIconFileName];
	
	mCharMap[fontID] = [(CharMap*)[CharMap alloc] Init];
	
    for (int digit = 0; digit <= 9; digit++)
    {
		snprintf( curString, maxIconFileName, "%i", digit );
		snprintf( fontFileName, maxIconFileName, "%s%i.papng", sNeonFontPrefixes[fontID], digit );
		
        [mCharMap[fontID] SetData:[NSString stringWithUTF8String:fontFileName] forGlyph:curString type:CHARMAP_ENTRY_STRING];
    }
    
	snprintf( fontFileName, maxIconFileName, "%sX.papng", sNeonFontPrefixes[fontID]);
    [mCharMap[fontID] SetData:[NSString stringWithUTF8String:fontFileName] forGlyph:"$" type:CHARMAP_ENTRY_STRING];
}

-(void)InitFonts
{
	for ( ENeonFontColor fontID = NEONFONT_FIRST; fontID < NEONFONT_NUM; fontID++ )
	{
		[self InitFont:fontID];
	}
}

-(void)DeallocFonts
{
	for ( ENeonFontColor fontID = NEONFONT_FIRST; fontID < NEONFONT_NUM; fontID++ )
	{
		[mCharMap[fontID] release];
	}
}

-(void)DeallocUserInterface
{
	for ( EUIGroup groupID = UIGROUP_FIRST; groupID < UIGROUP_NUM; groupID++ )
	{
		[mUserInterface[groupID]			removeAllObjectsFinal:TRUE];
		[[GameObjectManager GetInstance]	Remove:mUserInterface[groupID]];
	}
}

-(TextBox*)InitTextBoxWithFontColor:(ENeonFontColor)inFontColor uiGroup:(UIGroup*)uiGroup
{
    return [self InitTextBoxWithFontColor:inFontColor fontType:NEON_FONT_INVALID uiGroup:uiGroup];
}

-(TextBox*)InitTextBoxWithFontColor:(ENeonFontColor)inFontColor fontType:(NeonFontType)inFontType uiGroup:(UIGroup*)inUIGroup
{
	TextBox* retTextBox;
	
	// Set TextBoxParams for the projected TextBoxes showing hand scores
	TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    
    tbParams.mMutable   = TRUE;
    tbParams.mUIGroup   = inUIGroup;
    tbParams.mFontType  = NEON_FONT_NORMAL;
    tbParams.mFontSize  = 24;
    tbParams.mWidth     = 0;
    tbParams.mMaxWidth  = 200;
    tbParams.mMaxHeight = 100;
    
    if (inFontType != NEON_FONT_INVALID)
    {
        tbParams.mFontType = inFontType;
    }
    else if (NEONFONT_FIRST <= inFontColor && NEONFONT_LAST >= inFontColor)
    {
        tbParams.mCharMap           = mCharMap[inFontColor];
        tbParams.mCharMapSpacing    = 17.0f;
    }
    else
    {
        NSAssert1(FALSE, @"Invalid font color with ID: %d", inFontColor);
    }
    
	tbParams.mString = [NSString stringWithFormat:@""];	// Blank Until set by caller.

	retTextBox = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];

	if ( mUserInterface[UIGROUP_Projected3D] == inUIGroup )
	{
		[retTextBox SetProjected: TRUE];
		[retTextBox SetScaleX:0.020f Y:0.020f Z:1.0f];
	}
	    
    [retTextBox autorelease];
	
	return retTextBox;
}

-(NSMutableArray*)GetButtonArray
{
    NSAssert(FALSE, @"Must be implemented by subclass");
    return NULL;
}

@end