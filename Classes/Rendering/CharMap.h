//
//  CharMap.h
//
//  Copyright Neon Games 2011. All rights reserved.
//

#define CHARMAP_UTF8_MAX_LENGTH (4)

typedef enum
{
    CHARMAP_ENTRY_STRING,
    CHARMAP_ENTRY_TEXTURE
} CharMapEntryType;

@interface CharMapEntry : NSObject
{
    @protected
        char                mCharacter[CHARMAP_UTF8_MAX_LENGTH];
        id                  mData;
        
    @public
        CharMapEntryType    mType;
}

-(CharMapEntry*)Init;
-(void)dealloc;

-(void)SetData:(id)inData type:(CharMapEntryType)inType;
-(void)SetGlyphFromString:(NSString*)inString;
-(void)SetGlyph:(char*)inGlyph;

-(id)GetData;
-(char*)GetGlyph;

@end

@interface CharMap : NSObject
{
    NSMutableArray* mArray;
}

-(CharMap*)Init;
-(void)dealloc;

-(void)SetData:(id)inData forGlyphWithString:(NSString*)inGlyph type:(CharMapEntryType)inType;
-(void)SetData:(id)inData forGlyph:(char*)inGlyph type:(CharMapEntryType)inType;

-(id)GetDataForGlyphWithString:(NSString*)inGlyph type:(CharMapEntryType*)outType;
-(id)GetDataForGlyph:(char*)inGlyph type:(CharMapEntryType*)outType;

-(CharMapEntry*)CharMapEntryForGlyphWithString:(NSString*)inGlyph;
-(CharMapEntry*)CharMapEntryForGlyph:(char*)inGlyph;

-(NSMutableArray*)GetCharMapArray;

@end