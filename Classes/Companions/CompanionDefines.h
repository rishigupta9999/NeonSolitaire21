//
//  CompanionDefines.h
//  Neon21
//
//  Copyright Neon Games 2009 All rights reserved.

typedef enum
{
    COMPANION_POSITION_FIRST,
    COMPANION_POSITION_LEFT = COMPANION_POSITION_FIRST,
    COMPANION_POSITION_RIGHT,
    COMPANION_POSITION_CHANGEABLE_NUM,  // This is the number of companions that can be changed (the dealer can't be changed obviously)
    COMPANION_POSITION_DEALER = COMPANION_POSITION_CHANGEABLE_NUM,
    COMPANION_POSITION_PLAYER,
    COMPANION_POSITION_MAX,
    COMPANION_POSITION_INVALID = COMPANION_POSITION_MAX
} CompanionPosition;
