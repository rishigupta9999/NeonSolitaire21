//
//  Companion.h
//  Neon21
//
//  Copyright Neon Games 2009 All rights reserved.

@class CompanionEntity;

typedef enum
{
    COMPANION_SIZE_NORMAL,
    COMPANION_SIZE_FAT
} CompanionSize;

@interface Companion : NSObject
{
@public
    CompanionEntity*    mEntity;
	NSString            *characterName;
	NSString            *fileNamePrefix;		// What is the character's file name prefix?  ( xxx_foo.png -> cathy_foo.png )
	bool                isUnlocked;				// Is this companion selectable as a companion?
    CompanionSize       companionSize;          // What is the companion's body type?
}

@end