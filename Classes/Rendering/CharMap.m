//
//  CharMap.m
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "CharMap.h"

#define DEFAULT_CHARMAP_CAPACITY    (16)

@implementation CharMapEntry

-(CharMapEntry*)Init
{
    memset(mCharacter, 0, sizeof(mCharacter));
    
    return self;
}

-(void)dealloc
{
    [mData release];
    
    [super dealloc];
}

-(void)SetData:(id)inData type:(CharMapEntryType)inType
{
    [mData release];
    mData = inData;
    [mData retain];
    
    mType = inType;
}

-(void)SetGlyphFromString:(NSString*)inString
{
    NSAssert(([inString length] == 1), @"String should only be one character");
    const char* utf8Data = [inString UTF8String];
    
    strncpy(mCharacter, utf8Data, CHARMAP_UTF8_MAX_LENGTH);
}

-(void)SetGlyph:(char*)inGlyph
{
    strncpy(mCharacter, inGlyph, CHARMAP_UTF8_MAX_LENGTH);
}

-(id)GetData
{
    return mData;
}

-(char*)GetGlyph
{
    return mCharacter;
}

@end

@implementation CharMap

-(CharMap*)Init
{
    mArray = [[NSMutableArray alloc] initWithCapacity:DEFAULT_CHARMAP_CAPACITY];
    return self;
}

-(void)dealloc
{
    [mArray release];

    [super dealloc];
}

-(void)SetData:(id)inData forGlyphWithString:(NSString*)inGlyph type:(CharMapEntryType)inType
{
    CharMapEntry* entry = [self CharMapEntryForGlyphWithString:inGlyph];
    
    if (entry == NULL)
    {
        entry = [(CharMapEntry*)[CharMapEntry alloc] Init];
        
        [entry SetGlyphFromString:inGlyph];
        [mArray addObject:entry];
        [entry release];
    }
    
    [entry SetData:inData type:inType];
}

-(void)SetData:(id)inData forGlyph:(char*)inGlyph type:(CharMapEntryType)inType
{
    CharMapEntry* entry = [self CharMapEntryForGlyph:inGlyph];
    
    if (entry == NULL)
    {
        entry = [(CharMapEntry*)[CharMapEntry alloc] Init];
        
        [entry SetGlyph:inGlyph];
        [mArray addObject:entry];
        [entry release];
    }
    
    [entry SetData:inData type:inType];
}

-(id)GetDataForGlyphWithString:(NSString*)inGlyph type:(CharMapEntryType*)outType
{
    return [self GetDataForGlyph:(char*)[inGlyph UTF8String] type:outType];
}

-(id)GetDataForGlyph:(char*)inGlyph type:(CharMapEntryType*)outType
{
    for (CharMapEntry* curEntry in mArray)
    {
        if (strncmp(inGlyph, [curEntry GetGlyph], CHARMAP_UTF8_MAX_LENGTH) == 0)
        {
            *outType = curEntry->mType;
            return [curEntry GetData];
        }
    }
    
    return NULL;
}

-(CharMapEntry*)CharMapEntryForGlyphWithString:(NSString*)inGlyph
{
    return NULL;
}

-(CharMapEntry*)CharMapEntryForGlyph:(char*)inGlyph
{
    return NULL;
}

-(NSMutableArray*)GetCharMapArray
{
    return mArray;
}

@end