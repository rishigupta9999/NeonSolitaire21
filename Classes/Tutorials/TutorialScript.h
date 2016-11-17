//
//  TutorialScript.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "CardDefines.h"
#import "CompanionManager.h"
#import "Color.h"

#define MAX_TUTORIAL_DIALOGUE_STRINGS (5)

typedef struct
{
    int					numStrings;
	char				*dialogue[MAX_TUTORIAL_DIALOGUE_STRINGS];
} Neon21TutorialDialogueMessage;

@interface ShoeEntry : NSObject
{
    @public
        CardLabel   mCardLabel;
        CardSuit    mCardSuit;
}

-(ShoeEntry*)InitWithCardLabel:(CardLabel)inCardLabel suit:(CardSuit)inCardSuit;

@end

@interface SpinnerEntry : NSObject
{
    @public
        Vector2 mPosition;
        Vector2 mSize;
}

-(SpinnerEntry*)InitWithPositionX:(float)inPosX positionY:(float)inPosY sizeX:(float)inSizeX sizeY:(float)inSizeY;

@end

@interface TutorialPhaseInfo : NSObject
{
    @public
        NSString*           mDialogueKey;
        Vector2             mDialogueOffset;
        int                 mDialogueFontSize;
        NSString*           mDialogueFontName;
        Color               mDialogueFontColor;
        CTTextAlignment     mDialogueFontAlignment;
    
        NSString*           mButtonIdentifier;
    
        NSString*           mTriggerState;
        int                 mTriggerCount;
        CompanionPosition   mVoicePosition;
    
        BOOL                mCameraPositionOverride;
        BOOL                mCameraLookAtOverride;
        BOOL                mCameraFovOverride;
    
        Vector3             mCameraPosition;
        Vector3             mCameraLookAt;
        float               mCameraFov;
    
        BOOL                mRestoreCamera;
    
        NSMutableArray*     mSpinnerEntries;
}

@property BOOL AnyButton;

-(TutorialPhaseInfo*)Init;
-(void)dealloc;

-(void)SetDialogueOffsetX:(float)inX y:(float)inY;
-(void)SetDialogueFontSize:(float)inFontSize;
-(void)SetDialogueFontName:(NSString*)inFontName;
-(void)SetDialogueFontColorR:(float)inR g:(float)inG b:(float)inB a:(float)inA;
-(void)SetDialogueAlignment:(CTTextAlignment)inFontAlignment;

-(void)SetCameraPositionX:(float)inX y:(float)inY z:(float)inZ;
-(void)SetCameraLookAtX:(float)inX y:(float)inY z:(float)inZ;
-(void)SetCameraFov:(float)inFov;

-(void)SetSpinnerPositionX:(float)inX positionY:(float)inY sizeX:(float)inSizeX sizeY:(float)inSizeY;
-(void)SetTallSpinnerPositionX:(float)inX positionY:(float)inY sizeX:(float)inSizeX sizeY:(float)inSizeY;

-(void)RestoreCamera;

-(BOOL)HasSpinners;
-(int)GetNumSpinners;
-(SpinnerEntry*)GetSpinnerEntry:(int)inIndex;

@end

@interface TutorialScript : NSObject
{
    @public
        NSString*       mActiveScript;
        
        NSMutableArray* mShoeEntries;
        NSMutableArray* mPhaseInfo;
}

@property BOOL Indeterminate; // Indeterminate tutorials end under normal game logic.  Otherwise tutorials end when all phases are done.
@property BOOL EnableUI;      // All UI is always enabled if this flag is on.

-(TutorialScript*)InitDynamic;

-(void)AddPhase:(TutorialPhaseInfo*)inPhaseInfo;
-(void)AddCardLabel:(CardLabel)inLabel suit:(CardSuit)inSuit;

-(void)SetIndeterminate:(BOOL)inIndeterminate;

-(void)dealloc;

-(TutorialPhaseInfo*)GetTutorialPhase:(int)inPhaseIndex;
-(int)GetNumPhases;

@end