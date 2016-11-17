// Each card 'label' will need to be uniquely identifiable by rank and suit 
typedef enum
{
    CardLabel_First     = 0,
    CardLabel_Ace		= 0,
    CardLabel_Two		= 1,
    CardLabel_Three		= 2,
    CardLabel_Four		= 3,
    CardLabel_Five		= 4,
    CardLabel_Six		= 5,
    CardLabel_Seven		= 6,
    CardLabel_Eight		= 7,
    CardLabel_Nine		= 8,
    CardLabel_Ten		= 9,
    CardLabel_Jack		= 10,
    CardLabel_Queen		= 11,
    CardLabel_King		= 12,
    CardLabel_Joker		= 13,
    CardLabel_NumStandard = 13,
    CardLabel_Num       = 14
} CardLabel;

typedef enum
{
    CARDSUIT_First      = 0,
    CARDSUIT_Spades		= CARDSUIT_First,
    CARDSUIT_Hearts		= 1,
    CARDSUIT_Diamonds	= 2,
    CARDSUIT_Clubs		= 3,
    CARDSUIT_NumSuits	= 4,
} CardSuit;

typedef enum
{
	JokerStatus_TableTurnedOff,			// This joker has not been initialized
	JokerStatus_DifficultyIneligible,	// This joker is not available due to the difficulty setting
	JokerStatus_InDeck,					// The joker is present in the deck
	JokerStatus_InPlacer,				// The joker is the active card being placed by the user
	JokerStatus_NotInDeck,				// The joker has already been used, or has yet to be acquired.
	JokerStatus_MAX
} EJokerStatus;

typedef enum
{
	eInput_CPU_Preplay = 0,
	eInput_Human_Game,
	eInput_CPU_Postplay,
	eInput_MAX
} EInputMethod;

typedef enum
{
    CARDMODE_NORMAL,
    CARDMODE_XRAY,
    CARDMODE_NUM,
    CARDMODE_INVALID = CARDMODE_NUM
} CardMode;

#define CARDSUIT_JOKER_1		0	// The first  joker is of suit Spades, but is colorless as Joker #1
#define CARDSUIT_JOKER_2		1	// The second joker is of suit Hearts, but is colorless as Joker #2
#define CARDSUIT_JOKER_MAX		2	// The total number of Jokers
#define CARDSUIT_ELEVENCLUBS	2	// The Eleven of Clubs in 21^2 is a Joker of Suit 2, not its own rank.
#define CARDS_IN_STANDARD_SUIT  13  // There are thirteen cards [ A through K ] in a 'french' rank of cards.

extern const CardLabel STACK_PLAYER_LEFT_LABEL;  
extern const CardSuit STACK_PLAYER_LEFT_SUIT;
extern const CardLabel STACK_PLAYER_RIGHT_LABEL; 
extern const CardSuit STACK_PLAYER_RIGHT_SUIT;

extern const CardLabel STACK_DEALER_LEFT_LABEL; 
extern const CardSuit STACK_DEALER_LEFT_SUIT;
extern const CardLabel STACK_DEALER_RIGHT_LABEL;   
extern const CardSuit STACK_DEALER_RIGHT_SUIT;