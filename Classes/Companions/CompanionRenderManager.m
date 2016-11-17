//
//  CompanionRenderManager.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "CompanionRenderManager.h"

static CompanionRenderManager* sInstance = NULL;

static CompanionRenderInfo sRenderInfo[CompID_MAX] = {  { CompID_Empty,     NULL,           NULL,         NULL,                 1.0f, TRUE    },
                                                        { CompID_Polly,		"Polly.STM",    "Polly.SKEL", "Polly_OutUV.pvrtc",  0.3f, TRUE    },
                                                        { CompID_Amber,		"Amber.STM",    "Polly.SKEL", "Amber_OutUV.pvrtc",  0.3f, TRUE    },
                                                        { CompID_Betty,		"Betty.STM",    "Polly.SKEL", "Betty_OutUV.pvrtc",  0.3f, TRUE    },
                                                        { CompID_Cathy,		"Cathy.STM",    "Polly.SKEL", "Cathy_OutUV.pvrtc",  0.3f, TRUE    },
                                                        { CompID_Johnny,	"Johnny.STM",   "Polly.SKEL", "Johnny_OutUV.pvrtc", 0.3f, TRUE    },
                                                        { CompID_Panda,		"Panda.STM",    "Polly.SKEL", "Panda_OutUV.pvrtc",  0.3f, TRUE    },
                                                        { CompID_Igunaq,	"Igunaq.STM",   "Polly.SKEL", "Igunaq_OutUV.pvrtc", 0.3f, TRUE   },
                                                        { CompID_NunaVut,	"NunaVut.STM",  "Polly.SKEL", "NunaVut_OutUV.pvrtc",0.3f, TRUE    },
														{ CompID_DonCappo,	"Cappo.STM",    "Polly.SKEL", "Cappo_OutUV.pvrtc",  0.35f, TRUE   }};	// Make Cappo slightly bigger than everyone else
													/* ------------------- CUT Characters ----------------- ]]
														{ CompID_Ninja, "Polly.STM", "Polly.SKEL", "Polly_OutUV.pvrtc" },
														{ CompID_Blade, "Polly.STM", "Polly.SKEL", "Polly_OutUV.pvrtc" },
														{ CompID_Jack, "Polly.STM", "Polly.SKEL", "Polly_OutUV.pvrtc" },
														{ CompID_Jill, "Polly.STM", "Polly.SKEL", "Polly_OutUV.pvrtc" },
													[[ ------------------- CUT Characters ----------------- */ 
                                                        

#define NUM_POSITION_INFO   (5)
                                                        
static CompanionPositionInfo sCompanionRun21PositionInfo[CompID_MAX] =
{
    { { { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f },  { 0.0f, 0.0f, 0.0f },      { 0.0f, 0.0f, 0.0f } },     { { 0.0, 0.0, 0.0 },   { 0.0, 0.0, 0.0 },   { 0.0, 0.0f, 0.0 }, { 0.0, 0.0, 0.0 } } }, // Empty
    { { { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f },  { 0.0f, 0.0f, 0.0f },      { 0.0f, -1.5f, 5.0f } },   { { 0.0, 0.0, 0.0 },   { 0.0, 0.0, 0.0 },   { 0.0, 0.0f, 0.0 }, { 0.0, 180.0, 0.0 } } }, // Polly
    { { { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f },  {  7.00f, 3.75f, -2.75f }, { 0.0f, 0.0f, 0.0f } },     { { 0.0, 0.0, 0.0 },   { 0.0, 0.0, 0.0 },   { 0.0, -35.0, 0.0 }, { 0.0, 0.0, 0.0 } } }, // Amber
    { { { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f },  {  7.00f, 3.50f, -2.85f }, { 0.0f, 0.0f, 0.0f } },     { { 0.0, 0.0, 0.0 },   { 0.0, 0.0, 0.0 },   { 0.0, -35.0, 0.0 }, { 0.0, 0.0, 0.0 } } }, // Betty
    { { { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f },  {  7.00f, 3.75f, -2.75f }, { 0.0f, 0.0f, 0.0f } },     { { 0.0, 0.0, 0.0 },   { 0.0, 0.0, 0.0 },   { 0.0, -35.0, 0.0 }, { 0.0, 0.0, 0.0 } } }, // Cathy
    { { { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f },  {  7.00f, 3.75f, -2.85f }, { 0.0f, 0.0f, 0.0f } },     { { 0.0, 0.0, 0.0 },   { 0.0, 0.0, 0.0 },   { 0.0, -35.0, 0.0 }, { 0.0, 0.0, 0.0 } } }, // Johnny
    { { { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f },  {  7.25f, 3.25f, -1.75f }, { 0.0f, 0.0f, 0.0f } },     { { 0.0, 0.0, 0.0 },   { 0.0, 0.0, 0.0 },   { 0.0, -45.0, 0.0 }, { 0.0, 0.0, 0.0 } } }, // Panda
    { { { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f },  {  7.00f, 3.25f, -2.50f }, { 0.0f, 0.0f, 0.0f } },     { { 0.0, 0.0, 0.0 },   { 0.0, 0.0, 0.0 },   { 0.0, -25.0, 0.0 }, { 0.0, 0.0, 0.0 } } }, // NunaVut
    { { { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f },  {  7.00f, 3.25f, -1.5f },  { 0.0f, 0.0f, 0.0f } },     { { 0.0, 0.0, 0.0 },   { 0.0, 0.0, 0.0 },   { 0.0, -50.0, 0.0 }, { 0.0, 0.0, 0.0 } } }, // Igunaq
    { { { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f},   {  7.00f, 3.75f, -2.75f }, { 0.0f, 0.0f, 0.0f } },     { { 0.0, 0.0, 0.0 },   { 0.0, 0.0, 0.0 },   { 0.0, -35.0, 0.0 }, { 0.0, 0.0, 0.0 } } }  // Don Cappo
};

static Plane sCompanionClipPlanes[CompID_MAX] =
{
    { { 0.0f, 0.0f, 0.0f}, { 0.527f, 0.0f, -0.85f }, 3.0f }, // Empty
    { { 0.0f, 0.0f, 0.0f}, { 0.000f, 0.0f,  0.00f }, 0.0f }, // Polly
    { { 0.0f, 0.0f, 0.0f}, { 0.312f, 0.0f,  0.95f }, 0.0f }, // Amber
    { { 0.0f, 0.0f, 0.0f}, { 0.243f, 0.0f, -0.97f }, 0.0f }, // Betty
    { { 0.0f, 0.0f, 0.0f}, { 0.312f, 0.0f, -0.95f }, 3.2f }, // Cathy
    { { 0.0f, 0.0f, 0.0f}, { 0.199f, 0.0f, -0.98f }, 3.7f }, // Johnny
    { { 0.0f, 0.0f, 0.0f}, { 0.000f, 0.0f,  0.00f }, 0.0f }, // Panda
    { { 0.0f, 0.0f, 0.0f}, { 0.000f, 0.0f, -1.00f }, 0.0f }, // NunaVut
    { { 0.0f, 0.0f, 0.0f}, { 0.000f, 0.0f,  0.00f }, 0.0f }, // Igunaq
    { { 0.0f, 0.0f, 0.0f}, { 0.312f, 0.0f, -0.95f }, 0.0f }  // Don Cappo
};

@implementation CompanionRenderManager

-(CompanionRenderManager*)init
{
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"CompanionRenderManager not NULL");
    
    sInstance = [[CompanionRenderManager alloc] init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"CompanionRender was NULL");
    
    [sInstance release];
    sInstance = NULL;
}

+(CompanionRenderManager*)GetInstance
{
    return sInstance;
}

-(CompanionRenderInfo*)getCompanionRenderInfo:(CompanionID)inCompanionID
{
    for (int curCompanion = 0; curCompanion < CompID_MAX; curCompanion++)
    {
        if (sRenderInfo[curCompanion].mCompanionID == inCompanionID)
        {
            return &sRenderInfo[curCompanion];
        }
    }
    
    NSAssert(FALSE, @"Couldn't find companion with specified ID");
    
    return NULL;
}

-(void)getCompanionPlacement:(CompanionPosition)inPosition forId:(CompanionID)inCompanionId position:(Vector3*)outPosition orientation:(Vector3*)outOrientation
{
    NSAssert(((inPosition >= COMPANION_POSITION_LEFT) && (inPosition <= COMPANION_POSITION_MAX)), @"Invalid Companion position provided");
    NSAssert((inCompanionId >= 0) && (inCompanionId <= CompID_MAX), @"Invalid Companion ID");
	
    CloneVec3(&sCompanionRun21PositionInfo[inCompanionId].mPositions[inPosition], outPosition);
    CloneVec3(&sCompanionRun21PositionInfo[inCompanionId].mOrientations[inPosition], outOrientation);
}

-(void)getCompanionClipPlane:(Plane*)outPlane forId:(CompanionID)inCompanionId
{
    NSAssert((inCompanionId >= 0) && (inCompanionId <= CompID_MAX), @"Invalid Companion ID");

    ClonePlane(&sCompanionClipPlanes[inCompanionId], outPlane);
}

@end