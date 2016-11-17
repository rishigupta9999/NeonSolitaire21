//
//  TextTextureBuilder.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "TextTextureBuilder.h"
#import "ResourceManager.h"

#import "NeonMath.h"

#import "NeonColorDefines.h"

#import FT_STROKER_H
#import FT_BITMAP_H

static TextTextureBuilder* sInstance = NULL;

#define FONT_RESOURCE_HANDLE_CAPACITY   (3)
#define GLYPH_SPANS_INITIAL_CAPACITY    (256) 
#define INITIAL_LINE_WIDTH_CAPACITY     (5)
#define TEXT_TEXTURE_PARAMS_SIZE        (80)    // Update this as new fields are added to the parameter structure

static const int BITMAP_WIDTH = 1024;
static const int BITMAP_HEIGHT = 1024;

static const char*  COLOR_TAG = "color";
static const int    COLOR_TAG_LENGTH = 5;

#pragma mark -

@interface TextSpan : NSObject
{
    @public
        CTFontSymbolicTraits    mTraits;
    
        unsigned int            mColor;
        BOOL                    mColorOverride;
    
        int                     mPosition;
}

-(TextSpan*)Init;
-(TextSpan*)InitFromTextSpan:(TextSpan*)inSpan;

@end

@interface FontNode : NSObject
{
    @public
        CGFontRef   mCGFontRef;
    
        NSString*   mName;
        NSString*   mFamilyName;
    
        int         mTraits;
}

-(FontNode*)Init;
-(void)dealloc;

@end

#pragma mark -

@implementation TextSpan

-(TextSpan*)Init
{
    mTraits = 0;
    
    mColor = 0;
    mColorOverride = FALSE;
    
    mPosition = 0;
    
    return self;
}

-(TextSpan*)InitFromTextSpan:(TextSpan*)inSpan
{
    mTraits = inSpan->mTraits;
    mPosition = inSpan->mPosition;
    
    return self;
}

@end


@implementation FontNode

-(FontNode*)Init
{
    mCGFontRef = NULL;
    mName = NULL;
    mTraits = 0;
    
    return self;
}

-(void)dealloc
{
    CFRelease(mCGFontRef);
    [mName release];
    [mFamilyName release];
    
    [super dealloc];
}

@end


@implementation TextTextureBuilder

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"There is already an instance of the TextTextureBuilder");
    
    sInstance = [TextTextureBuilder alloc];
    [sInstance Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"There is no instance of the TextTextureBuilder");
    
    [sInstance release];
}

+(TextTextureBuilder*)GetInstance
{
    return sInstance;
}

-(TextTextureBuilder*)Init
{
    FT_Error error;
    
    error = FT_Init_FreeType(&mLibrary);
    NSAssert(error == 0, @"Error initializing freetype");
    
    mFontNodes = [[NSMutableArray alloc] initWithCapacity:FONT_RESOURCE_HANDLE_CAPACITY];
    
    mColorSpaceRef = CGColorSpaceCreateDeviceRGB();
    
    [self PreloadFonts];
    
    return self;
}

-(void)dealloc
{
    [mFontNodes release];
    
    CGColorSpaceRelease(mColorSpaceRef);
        
    [super dealloc];
}

+(void)InitDefaultParams:(TextTextureParams*)outParams
{
    outParams->mFontName = [NSString stringWithString:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
    outParams->mFontType = NEON_FONT_INVALID;
    outParams->mPointSize = 24;
    outParams->mString = NULL;
    outParams->mColor = 0xFFFFFFFF;
    outParams->mStrokeColor = 0;
    outParams->mWidth = 0;
    
    outParams->mLeadWidth = 0;
    outParams->mLeadHeight = 0;
    outParams->mTrailWidth = 0;
    outParams->mTrailHeight = 0;
    
    outParams->mStrokeSize = 0;
    outParams->mPremultipliedAlpha = FALSE;
    
    outParams->mAlignment = kCTTextAlignmentLeft;
    
    outParams->mTextureAtlas = NULL;
    outParams->mTexture = NULL;
}

-(CGFontRef)FindFont:(NSString*)inName traits:(int)inTraits
{
    for (FontNode* curNode in mFontNodes)
    {
        if (([curNode->mFamilyName compare:inName] == NSOrderedSame) && (curNode->mTraits == inTraits))
        {
            return curNode->mCGFontRef;
        }
    }
    
    NSAssert(FALSE, @"Couldn't find font for the passed in parameters");
    
    return NULL;
}

-(void)PreloadFonts
{
    NSMutableArray* fontNodes = [[ResourceManager GetInstance] FileNodesWithPrefixPath:@"Fonts"];
    
    for (FileNode* curNode in fontNodes)
    {
        if ([[curNode->mAssetName pathExtension] caseInsensitiveCompare:@"ttf"] == NSOrderedSame)
        {
            NSNumber* resourceHandle = [[ResourceManager GetInstance] LoadAssetWithName:curNode->mAssetName];
            NSData* fontData = [[ResourceManager GetInstance] GetDataForHandle:resourceHandle];
        
            FontNode* curFontNode = [(FontNode*)[FontNode alloc] Init];
        
            curFontNode->mName = [[NSString alloc] initWithString:curNode->mAssetName];
            
            FT_Face tempFace;
            
            FT_Error error = FT_New_Memory_Face( mLibrary, (unsigned char*)[fontData bytes], [fontData length], 0, &tempFace);
            NSAssert(error == 0, @"Unexpected error loading font");
            
            curFontNode->mFamilyName = [[NSString alloc] initWithUTF8String:tempFace->family_name];
            
            if (tempFace->style_flags & FT_STYLE_FLAG_BOLD)
            {
                curFontNode->mTraits |= kCTFontBoldTrait;
            }
            
            if (tempFace->style_flags & FT_STYLE_FLAG_ITALIC)
            {
                curFontNode->mTraits |= kCTFontItalicTrait;
            }
        
            CGDataProviderRef fontProvider = CGDataProviderCreateWithCFData((CFDataRef)fontData);

            curFontNode->mCGFontRef = CGFontCreateWithDataProvider(fontProvider);
            CGDataProviderRelease(fontProvider);
        
            [mFontNodes addObject:curFontNode];
            
            FT_Done_Face(tempFace);
            [[ResourceManager GetInstance] UnloadAssetWithHandle:resourceHandle];
        }
    }
}

-(Texture*)GenerateTextureWithFont:(NSString*)inFontName PointSize:(u32)inPointSize String:(NSString*)inString Color:(u32)inColor
{
    return [self GenerateTextureWithFont:inFontName PointSize:inPointSize String:inString Color:inColor Width:0];
}

-(Texture*)GenerateTextureWithFont:(NSString*)inFontName PointSize:(u32)inPointSize String:(NSString*)inString Color:(u32)inColor Width:(u32)inWidth;
{
    TextTextureParams params;
    
    [TextTextureBuilder InitDefaultParams:&params];
        
    params.mFontName = inFontName;
    params.mPointSize = inPointSize;
    params.mString = inString;
    params.mColor = inColor;
    params.mWidth = inWidth;
    
    return [self GenerateTextureWithParams:&params];
}

-(BOOL)RenderWithParams_CoreGraphics:(TextTextureParams*)inParams texture:(Texture*)inTexture
{
    NSAssert([self SupportsCoreGraphicsGeneration:inParams], @"Unsupported parameter combination for CoreGraphics Text generation");
    
    NSString* strippedString = NULL;
    
    NSMutableArray* textSpans = [self GenerateTextSpans:inParams strippedString:&strippedString];
            
    u32 paddedWidth = 1024;
    u32 paddedHeight = 1024;
    
    // Initialize an attributed string.
    CFStringRef string = (CFStringRef)strippedString;
                                 
    CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString(attrString, CFRangeMake(0, 0), string);
    
    // Set Foreground Color
    [self ApplyAttribute:kCTForegroundColorAttributeName spans:textSpans params:inParams strippedString:strippedString attrString:attrString];

    // Set Stroke Color
    CGColorRef strokeColorRef = [self ColorRefFromU32:inParams->mStrokeColor];
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, [strippedString length]), kCTStrokeColorAttributeName, strokeColorRef);
        
    // Set stroke width
    float strokeWidth = 1.0 * (float)inParams->mStrokeSize;
    CFNumberRef strokeWidthRef = CFNumberCreate(NULL, kCFNumberFloatType, &strokeWidth);
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, [strippedString length]), kCTStrokeWidthAttributeName, strokeWidthRef);
    
    [self ApplyAttribute:kCTFontAttributeName spans:textSpans params:inParams strippedString:strippedString attrString:attrString];
    
    // Set alignment
    CTTextAlignment alignment = inParams->mAlignment;
    CTParagraphStyleSetting alignmentSetting[1];
    
    alignmentSetting[0].spec = kCTParagraphStyleSpecifierAlignment;
    alignmentSetting[0].valueSize = sizeof(CTTextAlignment);
    alignmentSetting[0].value = &alignment;
    
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(alignmentSetting, 1);
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, [strippedString length]), kCTParagraphStyleAttributeName, paragraphStyle);

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attrString);
    
    // Initialize a rectangular path.
    CGMutablePathRef dummyPath = CGPathCreateMutable();
    
    float dummyWidth = 2048.0;
    
    if (inParams->mWidth != 0)
    {
        dummyWidth = inParams->mWidth;
    }
    
    CGRect bounds = CGRectMake(0.0, 0.0, dummyWidth, 2048.0);
    CGPathAddRect(dummyPath, NULL, bounds);

    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), dummyPath, NULL);
    CGSize suggestedSize = [self MeasureFrame:frameRef startX:&inParams->mStartX startY:&inParams->mStartY endX:&inParams->mEndX endY:&inParams->mEndY];
    
    CFRelease(frameRef);
    frameRef = NULL;
    
    // Padding for borders, sometimes they get a little clipped
    suggestedSize.width += 2.0f;
    suggestedSize.height += 2.0f;
    
    suggestedSize.width += inParams->mLeadWidth + inParams->mTrailWidth;
    suggestedSize.height += inParams->mLeadHeight + inParams->mTrailHeight;
    
    int widthWithBorder = suggestedSize.width;
    int heightWithBorder = suggestedSize.height;
    
    int paddingWidthAmount = 0;
    int paddingHeightAmount = 0;
        
    if (inParams->mTextureAtlas == NULL)
    {
        [Texture RoundToValidDimensionsWidth:suggestedSize.width Height:suggestedSize.height ValidWidth:&paddedWidth ValidHeight:&paddedHeight];
        
        paddingWidthAmount = paddedWidth - suggestedSize.width;
        paddingHeightAmount = paddedHeight - suggestedSize.height;
    }
    else
    {
        // If we're using a texture atlas, then there are no power-of-two size restrictions on the subtextures.  Don't
        // waste memory with the padding.
        paddedWidth = suggestedSize.width;
        paddedHeight = suggestedSize.height;
    }
    
    suggestedSize.width -= inParams->mLeadWidth + inParams->mTrailWidth;
    suggestedSize.height -= inParams->mLeadHeight + inParams->mTrailHeight;

    // Initialize a rectangular path.
    CGMutablePathRef finalPath = CGPathCreateMutable();
    bounds = CGRectMake(inParams->mLeadWidth, paddingHeightAmount + inParams->mTrailHeight - 2.0f, suggestedSize.width, suggestedSize.height);
    CGPathAddRect(finalPath, NULL, bounds);

    inTexture->mTexBytes = malloc(sizeof(u32) * paddedWidth * paddedHeight);
    
    u8 clearColor = 0x00;
    
#if DEBUG_TEXT_GENERATION
    clearColor = 0x80;
#endif

    memset(inTexture->mTexBytes, clearColor, sizeof(u32) * paddedWidth * paddedHeight);
         
    // Create the frame and draw it into the graphics context
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), finalPath, NULL);
    
    CFRelease(framesetter);
    
    CGContextRef cgContextRef = CGBitmapContextCreate(inTexture->mTexBytes, paddedWidth, paddedHeight, 8, paddedWidth * 4, mColorSpaceRef, kCGImageAlphaPremultipliedLast);
    CGContextSetTextMatrix(cgContextRef, CGAffineTransformIdentity);
    CGContextSetLineJoin(cgContextRef, kCGLineJoinRound);

    CTFrameDraw(frame, cgContextRef);
    CFRelease(frame);
    
    CFRelease(strokeWidthRef);
    
    strokeWidth = 0;
    strokeWidthRef = CFNumberCreate(NULL, kCFNumberFloatType, &strokeWidth);
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, [strippedString length]), kCTStrokeWidthAttributeName, strokeWidthRef);
    
    framesetter = CTFramesetterCreateWithAttributedString(attrString);
    frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), finalPath, NULL);
    
    CFRelease(attrString);
    CFRelease(framesetter);
    
    CTFrameDraw(frame, cgContextRef);
    CFRelease(frame);
    
    CFRelease(cgContextRef);
    CFRelease(strokeColorRef);
    CFRelease(strokeWidthRef);
    
    CFRelease(dummyPath);
    CFRelease(finalPath);
    CFRelease(paragraphStyle);
    
    [inTexture SetRealWidth:paddedWidth];
    [inTexture SetRealHeight:paddedHeight];
    
    [inTexture CreateGLTexture];
    
    [inTexture SetRealWidth:widthWithBorder];
    [inTexture SetRealHeight:heightWithBorder];
    
    [inTexture SetIdentifier:inParams->mString];
    
    inTexture->mPremultipliedAlpha = inParams->mPremultipliedAlpha;
	
    if (inParams->mTexture == NULL)
    {
        [inTexture autorelease];
    }
    
    [inTexture SetStatus:TEXTURE_STATUS_DECODING_COMPLETE];

    return TRUE;
}

-(void)ApplyAttribute:(CFStringRef)inAttribute spans:(NSMutableArray*)inSpans params:(TextTextureParams*)inParams strippedString:inStrippedString attrString:(CFMutableAttributedStringRef)inAttrString
{
    int numSpans = [inSpans count];
    
    for (int curSpanIndex = 0; curSpanIndex < numSpans; curSpanIndex++)
    {
        TextSpan* curSpan = [inSpans objectAtIndex:curSpanIndex];
        TextSpan* nextSpan = NULL;
        
        if (curSpanIndex < (numSpans - 1))
        {
            nextSpan = [inSpans objectAtIndex:(curSpanIndex + 1)];
        }
        
        int spanSize = 0;
        
        if (nextSpan == NULL)
        {
            spanSize = [inStrippedString length] - curSpan->mPosition;
        }
        else
        {
            spanSize = nextSpan->mPosition - curSpan->mPosition;
        }
        
        if (inAttribute == kCTFontAttributeName)
        {
            CGFontRef cgFontRef = [self FindFont:inParams->mFontName traits:curSpan->mTraits];
            CTFontRef ctFontRef = CTFontCreateWithGraphicsFont(cgFontRef, inParams->mPointSize, NULL, NULL);

            CFAttributedStringSetAttribute(inAttrString, CFRangeMake(curSpan->mPosition, spanSize), kCTFontAttributeName, ctFontRef);
            CFRelease(ctFontRef);
        }
        else if (inAttribute == kCTForegroundColorAttributeName)
        {
            CGColorRef colorRef = NULL;
            
            if (curSpan->mColorOverride)
            {
                colorRef = [self ColorRefFromU32:curSpan->mColor];
            }
            else
            {
                colorRef = [self ColorRefFromU32:inParams->mColor];
            }
            
            CFAttributedStringSetAttribute(inAttrString, CFRangeMake(curSpan->mPosition, spanSize), kCTForegroundColorAttributeName, colorRef);
            
            CFRelease(colorRef);
        }
        else
        {
            NSAssert(FALSE, @"Unknown attribute");
        }
    }
}

-(NSMutableArray*)GenerateTextSpans:(TextTextureParams*)inParams strippedString:(NSString**)outStrippedString
{
    typedef enum
    {
        SCANSTATE_DEFAULT,
        SCANSTATE_INSIDE_START_TAG,
        SCANSTATE_INSIDE_END_TAG
    } ScanState;
    
    NSMutableArray* textSpans = [NSMutableArray arrayWithCapacity:0];
    int length = [inParams->mString length];
    
    char* srcString = (char*)[inParams->mString UTF8String];
    char* destString = (char*)malloc(length + 1);
    
    ScanState scanState = SCANSTATE_DEFAULT;

    TextSpan* curSpan = [(TextSpan*)[TextSpan alloc] Init];
    [textSpans addObject:curSpan];
    [curSpan release];
    
    int srcIndex = 0;
    
    for (int i = 0; i < length; i++)
    {
        int charsRemaining = length - i;
        
        switch(scanState)
        {
            case SCANSTATE_DEFAULT:
            {
                if (srcString[i] == '<')
                {
                    scanState = SCANSTATE_INSIDE_START_TAG;
                    
                    if (i > 0)
                    {
                        // If we have two (or more) tags next to each other, than combine them into one span
                        if (curSpan->mPosition != srcIndex)
                        {
                            curSpan = [(TextSpan*)[TextSpan alloc] InitFromTextSpan:curSpan];
                            [textSpans addObject:curSpan];
                            [curSpan release];
                            
                            curSpan->mPosition = srcIndex;
                        }
                    }
                }
                else
                {
                    destString[srcIndex] = srcString[i];
                    srcIndex++;
                }
                
                break;
            }
            
            case SCANSTATE_INSIDE_START_TAG:
            {
                if (srcString[i] == 'b' || srcString[i] == 'B')
                {
                    curSpan->mTraits |= kCTFontBoldTrait;
                }
                else if (srcString[i] == '>')
                {
                    scanState = SCANSTATE_DEFAULT;
                }
                else if (srcString[i] == '/')
                {
                    scanState = SCANSTATE_INSIDE_END_TAG;
                }
                else if ((charsRemaining >= COLOR_TAG_LENGTH) && (memcmp(&srcString[i], COLOR_TAG, COLOR_TAG_LENGTH) == 0))
                {
                    i += COLOR_TAG_LENGTH;
                    
                    typedef enum
                    {
                        COLOR_TAG_STATE_START,
                        COLOR_TAG_STATE_SCANNING_COLOR,
                        COLOR_TAG_STATE_EXTRACT_COLOR,
                        COLOR_TAG_STATE_EXTRACTION_COMPLETE
                    } ColorTagState;
                    
                    ColorTagState colorTagState = COLOR_TAG_STATE_START;
                    
                    static const int COLOR_BUFFER_SIZE = 9;
                    char colorBuffer[COLOR_BUFFER_SIZE];
                    int colorBufferIndex = 0;
                    
                    memset(colorBuffer, 0, sizeof(colorBuffer));
                    
                    while(true)
                    {
                        switch(colorTagState)
                        {
                            case COLOR_TAG_STATE_START:
                            {
                                switch(srcString[i])
                                {
                                    case ' ':
                                    {
                                        break;
                                    }
                                    
                                    case '=':
                                    {
                                        colorTagState = COLOR_TAG_STATE_SCANNING_COLOR;
                                        break;
                                    }
                                    
                                    default:
                                    {
                                        NSAssert(FALSE, @"Unexpected character");
                                        break;
                                    }
                                }
                                
                                i++;
                                
                                break;
                            }
                                
                            case COLOR_TAG_STATE_SCANNING_COLOR:
                            {
                                char nextVal = srcString[i];
                                
                                switch(colorBufferIndex)
                                {
                                    case 0:
                                    {
                                        NSAssert(nextVal == '0', @"Invalid color value");
                                        break;
                                    }
                                    
                                    case 1:
                                    {
                                        NSAssert(nextVal == 'x' || nextVal == 'X', @"Invalid color value");
                                        break;
                                    }
                                    
                                    default:
                                    {
                                        NSAssert((nextVal >= '0' && nextVal <= '9') || (nextVal >= 'A' && nextVal <= 'F') || (nextVal >= 'a' && nextVal <= 'f'), @"Invalid color value");
                                        break;
                                    }
                                }
                                
                                colorBuffer[colorBufferIndex] = nextVal;
                                
                                colorBufferIndex++;
                                
                                if (colorBufferIndex >= (COLOR_BUFFER_SIZE - 1))
                                {
                                    colorTagState = COLOR_TAG_STATE_EXTRACT_COLOR;
                                    break;
                                }
                                
                                i++;
                                
                                break;
                            }
                            
                            case COLOR_TAG_STATE_EXTRACT_COLOR:
                            {
                                int colorVal = 0;
                                sscanf(colorBuffer, "%x", &colorVal);
                                
                                curSpan->mColorOverride = TRUE;
                                curSpan->mColor = (colorVal << 8) | 0xFF;
                                
                                colorTagState = COLOR_TAG_STATE_EXTRACTION_COMPLETE;
                                
                                break;
                            }
                            
                        }
                        
                        if (colorTagState == COLOR_TAG_STATE_EXTRACTION_COMPLETE)
                        {
                            break;
                        }
                    }
                }
                else
                {
                    NSAssert(FALSE, @"Unknown content in tag");
                }
                
                break;
            }
            
            case SCANSTATE_INSIDE_END_TAG:
            {
                if (srcString[i] == '>')
                {
                    scanState = SCANSTATE_DEFAULT;
                }
                else if (srcString[i] == 'b' || srcString[i] == 'B')
                {
                    curSpan->mTraits ^= kCTFontBoldTrait;
                }
                else if ((charsRemaining >= COLOR_TAG_LENGTH) && (memcmp(&srcString[i], COLOR_TAG, COLOR_TAG_LENGTH) == 0))
                {
                    curSpan->mColorOverride = FALSE;
                    curSpan->mColor = 0;
                    
                    i += (COLOR_TAG_LENGTH - 1);
                }
                else
                {
                    NSAssert(FALSE, @"Unknown content in tag");
                }
                
                break;
            }
        }
    }
    
    // If we have a text span at the very end (with no characters), just remove it
    if (curSpan->mPosition == srcIndex)
    {
        [textSpans removeObject:curSpan];
    }
    
    destString[srcIndex] = 0;
    
    *outStrippedString = [NSString stringWithUTF8String:destString];
    
    free(destString);
    
    return textSpans;
}

-(CGSize)MeasureFrame:(CTFrameRef)frame startX:(u32*)outStartX startY:(u32*)outStartY endX:(u32*)outEndX endY:(u32*)outEndY
{
    CGPathRef framePath = CTFrameGetPath(frame);
    CGRect frameRect    = CGPathGetBoundingBox(framePath);
    CFArrayRef lines    = CTFrameGetLines(frame);
    CFIndex numLines    = CFArrayGetCount(lines);
    CGFloat maxWidth    = 0;
    CGFloat textHeight  = 0;
    CFIndex lastLineIndex = numLines - 1;
    CGFloat firstLineHeight = 0;
    
    CGPoint* points = (CGPoint*)malloc(sizeof(CGPoint) * numLines);
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numLines), points);
    
    *outStartX = CGRectGetMaxX(frameRect);
    *outEndX = 0;
        
    for(CFIndex index = 0; index < numLines; index++)
    {
        CGFloat ascent, descent, leading, width;
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, index);
        width = CTLineGetTypographicBounds(line, &ascent,  &descent, &leading);
        
        if (points[index].x < *outStartX)
        {
            *outStartX = floor(points[index].x);
        }
        
        if ((*outStartX + width) > *outEndX)
        {
            *outEndX = ceil(*outStartX + width);
        }
            
        if (width > maxWidth)
        {
            maxWidth = width;
        }
        
        if (index == 0)
        {
            if (leading < 0)
            {
                leading = 0;
            }

            leading = floor(leading + 0.5);

            int lineHeight = floor(ascent + 0.5) + floor(descent + 0.5) + leading;
            int ascenderDelta = 0;

            if (leading <= 0)
            {
                ascenderDelta = floor (0.2 * lineHeight + 0.5);
            }

            firstLineHeight = lineHeight + ascenderDelta;
        }
    
        if (index == lastLineIndex)
        {
            textHeight = CGRectGetMaxY(frameRect) - points[lastLineIndex].y + descent;
            *outEndY = textHeight;
        }
    }
    
    *outStartY = max((int)(textHeight - points[0].y - firstLineHeight), 0);
    
    free(points);

    return CGSizeMake(ceil(maxWidth), ceil(textHeight));
}

-(Texture*)GenerateTextureWithParams:(TextTextureParams*)inParams
{    
    if ([inParams->mString length] == 0)
    {
        return NULL;
    }
    
    // If mFontType is set, it takes precedence over mFontName for localization purposes
    if (inParams->mFontType != NEON_FONT_INVALID)
    {
        inParams->mFontName = [[LocalizationManager GetInstance] GetFontForType:inParams->mFontType];
    }
    
    Texture* newTexture = NULL;
    
    if (inParams->mTexture == NULL)
    {
        newTexture = [Texture alloc];
        [newTexture Init];
        
        newTexture->mParams.mTextureAtlas = inParams->mTextureAtlas;
    }
    else
    {
        newTexture = inParams->mTexture;
        [newTexture FreeClientData];
    }
    
    if ([self SupportsCoreGraphicsGeneration:inParams])
    {
        BOOL success = [self RenderWithParams_CoreGraphics:inParams texture:newTexture];
        [newTexture SetStatus:TEXTURE_STATUS_DECODING_COMPLETE];
        
        if (success)
        {
            return newTexture;
        }
    }
    
    NSAssert(FALSE, @"We shouldn't be using the old text generation path anymore!");
    
    return NULL;
}

-(BOOL)SupportsCoreGraphicsGeneration:(TextTextureParams*)inParams
{
    BOOL retVal = TRUE;
    
    if (!inParams->mPremultipliedAlpha)
    {
        retVal = FALSE;
    }
    
    return retVal;
}

-(CGColorRef)ColorRefFromU32:(u32)inColorVal
{
    CGFloat color[4];
    
    color[0] = (float)((inColorVal & 0xFF000000) >> 24) / 255.0f;
    color[1] = (float)((inColorVal & 0x00FF0000) >> 16) / 255.0f;
    color[2] = (float)((inColorVal & 0x0000FF00) >> 8) / 255.0f;
    color[3] = (float)(inColorVal & 0x000000FF) / 255.0f;
    
    CGColorRef colorRef = CGColorCreate(mColorSpaceRef, color);
    
    return colorRef;
}

@end
