//
//  CardEntity.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "CardEntity.h"
#import "Card.h"
#import "CardRenderManager.h"
#import "MeshBuilder.h"
#import "GameEnvironment.h"
#import "GameObjectBatch.h"
#import "GameObjectManager.h"
#import "Texture.h"
#import "GameStateMgr.h"
#import "GameRun21.h"
#import "Flow.h"
#import "LevelDefinitions.h"

#define CARD_HEIGHT     (1.5)
#define CARD_SPACING    (CARD_HEIGHT - 0.5)
#define HAND_SPACING    (CARD_SPACING * 3)

static const char* CARD_FRONT_IDENTIFIER = "Card Front";
static const char* CARD_BACK_IDENTIFIER = "Card Back";

@implementation CardEntity

@synthesize cardEntityMode = mCardEntityMode;

-(CardEntity*)InitWithCard:(Card*)inCard;
{
    [super Init];
        
    mCard = inCard;
    
    mTexture = NULL;
    mUsesLighting = TRUE;
    
    [self Reset];
    
    // Use an easier to visualize coordinate system for cards, since most of the time they are being viewed
    // on the table (top-down).
    //
    // If we're looking down at the table, this is the coordinate system.
    //
    // ----------------> +x
    // |
    // |
    // |
    // |
    // |
    // v
    //
    // +y
    //
    
    // Generate a transform for this coordinate system
    
    Matrix44 translation, rotation;
    
    GenerateTranslationMatrix(0.0f, [[[CardRenderManager GetInstance] GetGameEnvironment] GetTableHeight], 0.0f, &translation);
    GenerateRotationMatrix([[[CardRenderManager GetInstance] GetGameEnvironment] GetTableRotationDegrees], 1.0f, 0.0f, 0.0f, &rotation);
    
    MatrixMultiply(&translation, &rotation, &mLTWTransform);
    
    mAspect = 1.0f;
    
    mRenderBinId = RENDERBIN_CARDS;
    
    Texture* backTexture = [[CardRenderManager GetInstance] GetBackTextureAtIndex:0];
    
    Set(&mPivot, (CARD_HEIGHT * mAspect * ((float)[backTexture GetRealWidth] / (float)[backTexture GetRealHeight])) / 2.0, CARD_HEIGHT / 2.0, 0.0);
    
    mCardEntityMode = CARDENTITYMODE_NORMAL;
    
    [[CardRenderManager GetInstance] AddCardEntity:self];
        
    return self;
}

-(void)Remove
{
    [[CardRenderManager GetInstance] RemoveCardEntity:self];
}

-(void)Reset
{
    [self SetVisible:FALSE];
    mParentHand = NULL;
}

-(void)SetupRenderState:(RenderStateParams*)inParams
{
    NeonGLEnable(GL_CULL_FACE);
    
    [super SetupRenderState:inParams];
}

-(void)TeardownRenderState:(RenderStateParams*)inParams
{
    NeonGLDisable(GL_CULL_FACE);
    
    [super TeardownRenderState:inParams];
}

-(void)Draw
{
    Texture* backTexture = [[CardRenderManager GetInstance] GetBackTexture];
    Texture* activeTexture = mTexture;
    
    if (mCardEntityMode == CARDENTITYMODE_XRAY)
    {
        activeTexture = [[CardRenderManager GetInstance] GetXRayTextureForCard:mCard];
    }

	float vertexArray[12] = {   0, 0, 0,
                                0, 1, 0,
                                1, 0, 0,
                                1, 1, 0 };
    
    float backVertexArray[12] = {   0, 0, 0,
                                    1, 0, 0,
                                    0, 1, 0,
                                    1, 1, 0 };

    float texCoordArray[8] = {  activeTexture->mTextureAtlasInfo.mSMin, activeTexture->mTextureAtlasInfo.mTMin,
                                activeTexture->mTextureAtlasInfo.mSMin, activeTexture->mTextureAtlasInfo.mTMax,
                                activeTexture->mTextureAtlasInfo.mSMax, activeTexture->mTextureAtlasInfo.mTMin,
                                activeTexture->mTextureAtlasInfo.mSMax, activeTexture->mTextureAtlasInfo.mTMax };
                                
    float backTexCoordArray[8] = {  backTexture->mTextureAtlasInfo.mSMax, backTexture->mTextureAtlasInfo.mTMin,
                                    backTexture->mTextureAtlasInfo.mSMin, backTexture->mTextureAtlasInfo.mTMin,
                                    backTexture->mTextureAtlasInfo.mSMax, backTexture->mTextureAtlasInfo.mTMax,
                                    backTexture->mTextureAtlasInfo.mSMin, backTexture->mTextureAtlasInfo.mTMax };

	
    float normalArray[12] = {   0, 0, -1,
                                0, 0, -1,
                                0, 0, -1,
                                0, 0, -1 };
                                
    float backNormalArray[12] =  {  0, 0, 1,
                                    0, 0, 1,
                                    0, 0, 1,
                                    0, 0, 1 };
    
    float colorArray[16];
            
    float width = CARD_HEIGHT * mAspect;
    float height = CARD_HEIGHT;
    
    for (int i = 0; i < 4; i++)
    {
        vertexArray[(i * 3) + 0] *= width;
        vertexArray[(i * 3) + 1] *= height;
        
        backVertexArray[(i * 3) + 0] *= width;
        backVertexArray[(i * 3) + 1] *= height;
    }
    
    for (int i = 0; i < 4; i++)
    {
        colorArray[(i * 4) + 0] = 1.0f;
        colorArray[(i * 4) + 1] = 1.0f;
        colorArray[(i * 4) + 2] = 1.0f;
        colorArray[(i * 4) + 3] = mAlpha;
    }
    
    MeshBuilder* meshBuilder = [mGameObjectBatch GetMeshBuilder];
    
    Matrix44 ltwTransform;
    [self GetLocalToWorldTransform:&ltwTransform];

    if (mCardEntityMode == CARDMODE_NORMAL)
    {
        [meshBuilder StartMeshWithOwner:self identifier:CARD_FRONT_IDENTIFIER];
        
        [meshBuilder SetPositionPointer:(u8*)vertexArray numComponents:3 numVertices:4 copyData:TRUE];
        [meshBuilder SetTexcoordPointer:(u8*)texCoordArray numComponents:2 numVertices:4 copyData:TRUE];
        [meshBuilder SetNormalPointer:(u8*)normalArray numComponents:3 numVertices:4 copyData:TRUE];
        [meshBuilder SetColorPointer:(u8*)colorArray numComponents:4 numVertices:4 copyData:TRUE];
        
        [meshBuilder SetBlendEnabled:TRUE];
        [meshBuilder SetBlendFunc:GL_SRC_ALPHA dest:GL_ONE_MINUS_SRC_ALPHA];
        
        [meshBuilder SetNumVertices:4];
        
        [meshBuilder SetTransform:&ltwTransform];
        [meshBuilder SetTexture:activeTexture];
        [meshBuilder SetPrimitiveType:GL_TRIANGLE_STRIP];
        
        [meshBuilder EndMesh];
        
        [meshBuilder StartMeshWithOwner:self identifier:CARD_BACK_IDENTIFIER];
        
        [meshBuilder SetPositionPointer:(u8*)backVertexArray numComponents:3 numVertices:4 copyData:TRUE];
        [meshBuilder SetTexcoordPointer:(u8*)backTexCoordArray numComponents:2 numVertices:4 copyData:TRUE];
        [meshBuilder SetNormalPointer:(u8*)backNormalArray numComponents:3 numVertices:4 copyData:TRUE];
        [meshBuilder SetColorPointer:(u8*)colorArray numComponents:4 numVertices:4 copyData:TRUE];
        
        [meshBuilder SetBlendEnabled:TRUE];
        [meshBuilder SetBlendFunc:GL_SRC_ALPHA dest:GL_ONE_MINUS_SRC_ALPHA];
        
        [meshBuilder SetNumVertices:4];
        
        [meshBuilder SetTransform:&ltwTransform];
        [meshBuilder SetTexture:backTexture];
        [meshBuilder SetPrimitiveType:GL_TRIANGLE_STRIP];

        [meshBuilder EndMesh];
    }
    else
    {
        GLState glState;
    
        SaveGLState(&glState);

        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_NORMAL_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glEnableClientState(GL_COLOR_ARRAY);

        NeonGLEnable(GL_BLEND);
        NeonGLBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
        glVertexPointer(3, GL_FLOAT, 0, vertexArray);
        glNormalPointer(GL_FLOAT, 0, normalArray);
        glTexCoordPointer(2, GL_FLOAT, 0, texCoordArray);
        glColorPointer(4, GL_FLOAT, 0, colorArray);
        
        [activeTexture->mParams.mTextureAtlas Bind];
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glVertexPointer(3, GL_FLOAT, 0, backVertexArray);
        glNormalPointer(GL_FLOAT, 0, backNormalArray);
        glTexCoordPointer(2, GL_FLOAT, 0, backTexCoordArray);
        
        [backTexture->mParams.mTextureAtlas Bind];
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        RestoreGLState(&glState);
    }
}

-(void)dealloc
{
    [mTexture release];
    [super dealloc];
}

-(void)SetVisible:(BOOL)inVisible
{
    if (inVisible)
    {
        mTexture = [[CardRenderManager GetInstance] GetTextureForCard:mCard];
        
        // Get the aspect ratio from the card texture
        
        mAspect = (float)[mTexture GetRealWidth] / (float)[mTexture GetRealHeight];
    }
    else
    {
        mTexture = NULL;
    }
    
    [super SetVisible:inVisible];
}

+(void)GetLocalToWorldTransform:(Matrix44*)outLTWTransform
{
    GenerateRotationMatrix(90.0f, 1.0f, 0.0f, 0.0f, outLTWTransform);
}

-(void)UpdateCardMode
{
    switch(mCard.cardMode)
    {
        case CARDMODE_NORMAL:
        {
            [self PerformAfterOperationsInQueue:dispatch_get_main_queue() block:^
                {
                    [[CardRenderManager GetInstance] AddCardEntity:self];
                    [[GameObjectManager GetInstance] Remove:self];
                    
                    mCardEntityMode = CARDMODE_NORMAL;
                }
            ];
            
            break;
        }
        
        case CARDMODE_XRAY:
        {
            [[GameObjectManager GetInstance] Add:self withRenderBin:RENDERBIN_XRAY_CARD];
            [[CardRenderManager GetInstance] RemoveCardEntity:self];
            
            mCardEntityMode = CARDMODE_XRAY;
            break;
        }
    }
}

@end