//
//  AnimationDebugState.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "AnimationDebugState.h"
#import "CameraStateMgr.h"

#import "Skeleton.h"
#import "Animation.h"

#import "ResourceManager.h"
#import "Streamer.h"

#import "NeonMath.h"

#import "GameObjectManager.h"
#import "ModelManager.h"
#import "SimpleModel.h"
#import "LightManager.h"
#import "ModelExporterDefines.h"

#import "TextBox.h"
#import "UIList.h"

#import "DebugCamera.h"

#define JOINT_BUTTON_BASE_X     (10)
#define JOINT_BUTTON_BASE_Y     (50)

#define MID_BUTTON_LENGTH       (4)
#define LONG_BUTTON_LENGTH      (10)

#define ANIMATION_STEP_TIME     (0.016666667)

#define GET_STATE_MACHINE() ( ((AnimationDebugStateMachine*)mStateMachine)  )

static const char* CHOOSE_MODEL_STRING = "Choose a model:";
static const char* CHOOSE_SKELETON_STRING = "Choose a skeleton:";
static const char* CHOOSE_ANIMATION_STRING = "Choose an animation:";

static const char* OVERRIDE_MODEL_NAME = "";//"AstroBoy.STM";
static const char* OVERRIDE_MODEL_SKEL = "";//"AstroBoy.SKEL";
static const char* OVERRIDE_MODEL_ANIM = "";//"AstroBoy.ANIM";

@implementation AnimationState

-(void)Draw
{
}

-(void)DrawOrtho
{
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    NSAssert(FALSE, @"Subclasses must implement this function");
}

@end

#define NUM_PERSISTENT_BUTTONS      (3)
#define PERSISTENT_TOGGLE_ROTATION_IDENTIFIER   'PTOR'
#define PERSISTENT_FREE_CAMERA_IDENTIFIER       'PFCA'
#define PERSISTENT_BACK_IDENTIFIER              'PBAC'

static ButtonInitParams sPersistentButtons[NUM_PERSISTENT_BUTTONS] = {  { 274.0f, 244.0f, "Toggle Rotation", PERSISTENT_TOGGLE_ROTATION_IDENTIFIER },
                                                                        { 274.0f, 269.0f, "Free Camera", PERSISTENT_FREE_CAMERA_IDENTIFIER },
                                                                        { 274.0f,  294.0f,"Back", PERSISTENT_BACK_IDENTIFIER } };

@implementation AnimationDebugStateMachine

-(AnimationDebugStateMachine*)InitWithModel:(Model*)inModel skeleton:(Skeleton*)inSkeleton
{
    [super Init];
    
    mDebugModel = inModel;
    mDebugAnimationClip = NULL;
    mActiveJointIndex = JOINT_INVALID_INDEX;
    mRotationEnabled = FALSE;
    mRotationAmount = 0.0;
    
    mAnimCamera = [(CameraUVN*)[CameraUVN alloc] Init];
    
    Set(&mAnimCamera->mPosition, 0.0, 0.0, 50.0);
    
    [self InitPersistentUI];
    
    return self;
}

-(void)dealloc
{
    [mAnimCamera release];
    
    [AnimationDebugStateMachine RemoveButtons:mPersistentButtons];
    
    [super dealloc];
}

-(void)InitPersistentUI
{
    mPersistentButtons = [[NSMutableArray alloc] initWithCapacity:NUM_PERSISTENT_BUTTONS];
    [AnimationDebugStateMachine CreateButtons:sPersistentButtons numButtons:NUM_PERSISTENT_BUTTONS referenceArray:mPersistentButtons listener:self];
}

-(Skeleton*)GetDebugSkeleton
{
    return [mDebugModel GetSkeleton];
}

-(void)SetActiveJointIndex:(int)inJointIndex
{
    mActiveJointIndex = inJointIndex;
}

-(Joint*)GetActiveJoint
{
    Joint* retJoint = NULL;
    
    if (mActiveJointIndex != JOINT_INVALID_INDEX)
    {
        retJoint =  [[self GetDebugSkeleton] GetJointWithIdentifier:mActiveJointIndex];
    }
    
    return retJoint;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [super Update:inTimeStep];
    
    [mDebugAnimationClip Update:inTimeStep];
    [mDebugModel Update:inTimeStep];
    
    if (mRotationEnabled)
    {
        mRotationAmount += 20.0f * inTimeStep;
    }
}

-(void)Draw
{
    if (mDebugModel == NULL)
    {
        return;
    }
    
#if LANDSCAPE_MODE
    Matrix44 viewMatrix, projMatrix;
    
    [mAnimCamera GetViewMatrix:&viewMatrix];
    [mAnimCamera GetProjectionMatrix:&projMatrix];
    
    NeonGLMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadMatrixf(projMatrix.mMatrix);

    NeonGLMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    
    Matrix44 screenRotation;
    GenerateRotationMatrix(-90, 0.0f, 0.0f, 1.0f, &screenRotation);
    
    glLoadIdentity();
    glMultMatrixf(screenRotation.mMatrix);
    glMultMatrixf(viewMatrix.mMatrix);
#endif

    NeonGLMatrixMode(GL_MODELVIEW);
    
    Matrix44 identity;
    
    SetIdentity(&identity);
        
    glRotatef(mRotationAmount, 0, 1, 0);
    glColor4f(1.0f, 0.0f, 1.0f, 1.0f);
    
    NeonGLEnable(GL_LIGHTING);
    [mDebugModel Draw];
    NeonGLDisable(GL_LIGHTING);
    
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
    
    NeonGLDisable(GL_DEPTH_TEST);
    [[self GetDebugSkeleton] DrawJointHierarchy:mActiveJointIndex];
    NeonGLEnable(GL_DEPTH_TEST);

#if LANDSCAPE_MODE    
    NeonGLMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    
    NeonGLMatrixMode(GL_PROJECTION);
    glPopMatrix();
#endif

    [(AnimationState*)mActiveState Draw];

    NeonGLError();
}

+(void)CreateButtons:(ButtonInitParams*)inButtonParams numButtons:(int)inNumButtons
                        referenceArray:(NSMutableArray*)inReferenceArray listener:(NSObject<ButtonListenerProtocol>*)inListener;
{
    TextureButtonParams buttonParams;
    
    [TextureButton InitDefaultParams:&buttonParams];
    
    buttonParams.mFontSize = 18;
    buttonParams.mFontColor = 0xFF000000;
        
    buttonParams.mButtonTexBaseName = @"editorbutton.png";
    buttonParams.mButtonTexHighlightedName = @"editorbutton_lit.png";
    
    for (int i = 0; i < inNumButtons; i++)
    {
        buttonParams.mButtonText = [NSString stringWithUTF8String:inButtonParams[i].mText];
        
        if ([buttonParams.mButtonText length] >= LONG_BUTTON_LENGTH)
        {
            buttonParams.mButtonTexBaseName = @"editorbutton_large.png";
            buttonParams.mButtonTexHighlightedName = @"editorbutton_large_lit.png";
        }
        else if ([buttonParams.mButtonText length] >= MID_BUTTON_LENGTH)
        {
            buttonParams.mButtonTexBaseName = @"editorbutton_mid.png";
            buttonParams.mButtonTexHighlightedName = @"editorbutton_mid_lit.png";
        }
        else
        {
            buttonParams.mButtonTexBaseName = @"editorbutton.png";
            buttonParams.mButtonTexHighlightedName = @"editorbutton_lit.png";
        }
        
        TextureButton* newButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&buttonParams];
        
        [newButton SetPositionX:inButtonParams[i].mX Y:inButtonParams[i].mY Z:0.0];
        newButton->mIdentifier = inButtonParams[i].mButtonIdentifier;
        
        [newButton SetListener:inListener];
        
        [[GameObjectManager GetInstance] Add:newButton];
        [inReferenceArray addObject:newButton];
        [newButton release];
    }
}

+(void)RemoveButtons:(NSMutableArray*)inButtonArray
{
    for (Button* curButton in inButtonArray)
    {
        [[GameObjectManager GetInstance] Remove:curButton];
        [curButton Remove];
    }
}

-(void)DrawOrtho
{
    [(AnimationState*)mActiveState DrawOrtho];
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            if (inButton->mIdentifier == PERSISTENT_TOGGLE_ROTATION_IDENTIFIER)
            {
                mRotationEnabled = !mRotationEnabled;
            }
            else if (inButton->mIdentifier == PERSISTENT_FREE_CAMERA_IDENTIFIER)
            {
                [self Push:[AnimationDebugFreeCamera alloc]];
            }
            else if (inButton->mIdentifier == PERSISTENT_BACK_IDENTIFIER)
            {
                [self Pop];
            }
            
            break;
        }
    }
}

@end

@implementation AnimationDebugChooseModel

-(void)Startup
{
    TextBoxParams textBoxParams;
    
    [TextBox InitDefaultParams:&textBoxParams];
    
    textBoxParams.mString = [NSString stringWithUTF8String:CHOOSE_MODEL_STRING];
    textBoxParams.mFontSize = 18;
    
    SetColor(&textBoxParams.mColor, 0xFF, 0x00, 0x00, 0xFF);
    
    mChooseModelTextBox = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    [mChooseModelTextBox SetPositionX:10.0 Y:10.0 Z:0.0];
    
    [[GameObjectManager GetInstance] Add:mChooseModelTextBox];
    [mChooseModelTextBox release];
    
    NSMutableArray* potentialModels = [[ResourceManager GetInstance] FilesWithExtension:@"STM"];
    NSMutableArray* displayedModels = [[NSMutableArray alloc] initWithCapacity:[potentialModels count]];
    
    mModelButtons = [[NSMutableArray alloc] initWithCapacity:[potentialModels count]];
    
    for (NSString* curPath in potentialModels)
    {
        NSNumber* handle = [[ResourceManager GetInstance] StreamAssetWithPath:curPath];
        Streamer* streamer = [[ResourceManager GetInstance] GetStreamForHandle:handle];
        
        ModelHeader header;
        [streamer StreamInto:&header size:sizeof(ModelHeader)];
        
        // If we have skinning data, then we can show this in the debugger
        if (header.mNumMatricesPerVertex != 0)
        {
            [displayedModels addObject:curPath];
        }
        
        [[ResourceManager GetInstance] UnloadAssetWithHandle:handle];
    }
    
    int count = 0;
    
    for (NSString* curPath in displayedModels)
    {
        TextureButtonParams    params;
        
        [TextureButton InitDefaultParams:&params];
        
        params.mButtonText = curPath;
        params.mFontColor = 0xFF000000;
        params.mFontSize = 18;
                                
        TextureButton* button = [(TextureButton*)[TextureButton alloc] InitWithParams:&params];
        [button SetListener:self];
        [button SetPositionX:24 Y:(44 + (32 * count)) Z:0];
        [button SetUserData:(u32)curPath];
        
        [[GameObjectManager GetInstance] Add:button];
        [mModelButtons addObject:button];
        
        [button release];
        
        count++;
    }
}

-(void)Resume
{
    [mChooseModelTextBox SetVisible:TRUE];
    
    for (TextureButton* curButton in mModelButtons)
    {
        [curButton Enable];
    }

}

-(void)Shutdown
{
    [[GameObjectManager GetInstance] Remove:mChooseModelTextBox];
    
    for (TextureButton* curButton in mModelButtons)
    {
        [[GameObjectManager GetInstance] Remove:curButton];
    }
    
    [mModelButtons removeAllObjects];
    [mModelButtons release];
}

-(void)Suspend
{
    [mChooseModelTextBox SetVisible:FALSE];
    
    for (TextureButton* curButton in mModelButtons)
    {
        [curButton Disable];
    }
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            NSString* filePath = (NSString*)[inButton GetUserData];
            
            NSNumber* handle = [[ResourceManager GetInstance] LoadAssetWithPath:filePath];
            NSData* data = [[ResourceManager GetInstance] GetDataForHandle:handle];
            
            AnimationDebugStateMachine* stateMachine = ((AnimationDebugStateMachine*)mStateMachine);
            
            if (stateMachine->mDebugModel != NULL)
            {
                [stateMachine->mDebugModel release];
                stateMachine->mDebugModel = NULL;
            }
            
            stateMachine->mDebugModel = [(SimpleModel*)[SimpleModel alloc] InitWithData:data];
            [[ResourceManager GetInstance] UnloadAssetWithHandle:handle];
            
            [stateMachine Push:[AnimationDebugChooseModelAction alloc]];         
            break;
        }
    }
}

@end

#define MODEL_ACTION_CHOOSE_SKELETON    'MACS'

#define NUM_MODEL_ACTIONS               (1)

static ButtonInitParams   sModelActionButtonParams[NUM_MODEL_ACTIONS] = {   { 10, 230, "Choose Skeleton",   MODEL_ACTION_CHOOSE_SKELETON } };

@implementation AnimationDebugChooseModelAction

-(void)Startup
{    
    mActionButtons = [[NSMutableArray alloc] initWithCapacity:NUM_MODEL_ACTIONS];
    
    [AnimationDebugStateMachine CreateButtons:sModelActionButtonParams numButtons:NUM_MODEL_ACTIONS referenceArray:mActionButtons listener:self];
}

-(void)Resume
{
    for (Button* curButton in mActionButtons)
    {
        [curButton Enable];
    }
}

-(void)Shutdown
{
    [AnimationDebugStateMachine RemoveButtons:mActionButtons];
    [mActionButtons release];
}

-(void)Suspend
{
    for (Button* curButton in mActionButtons)
    {
        [curButton Disable];
    }
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            switch(inButton->mIdentifier)
            {
                case MODEL_ACTION_CHOOSE_SKELETON:
                {
                    [mStateMachine Push:[AnimationDebugChooseSkeleton alloc]];
                    break;
                }
            }
            
            break;
        }
    }
}

@end


@implementation AnimationDebugChooseSkeleton

-(void)Startup
{
    [self CreateUI];
}

-(void)Resume
{
    [self CreateUI];
}

-(void)Shutdown
{
    [self TeardownUI];
}

-(void)Suspend
{
    [self TeardownUI];
}

-(void)CreateUI
{
    TextBoxParams textBoxParams;
    
    [TextBox InitDefaultParams:&textBoxParams];
    
    textBoxParams.mString = [NSString stringWithUTF8String:CHOOSE_SKELETON_STRING];
    textBoxParams.mFontSize = 18;
    
    SetColor(&textBoxParams.mColor, 0xFF, 0x00, 0x00, 0xFF);
    
    mChooseSkeletonTextBox = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    [mChooseSkeletonTextBox SetPositionX:10.0 Y:10.0 Z:0.0];
    
    [[GameObjectManager GetInstance] Add:mChooseSkeletonTextBox];
    [mChooseSkeletonTextBox release];
    
    NSMutableArray* potentialSkeletons = [[ResourceManager GetInstance] FilesWithExtension:@"SKEL"];
    NSMutableArray* displayedSkeletons = [[NSMutableArray alloc] initWithCapacity:[potentialSkeletons count]];
    
    mSkeletonButtons = [[NSMutableArray alloc] initWithCapacity:[potentialSkeletons count]];

    for (NSString* curPath in potentialSkeletons)
    {
        NSNumber* handle = [[ResourceManager GetInstance] StreamAssetWithPath:curPath];
        Streamer* streamer = [[ResourceManager GetInstance] GetStreamForHandle:handle];
        
        SkeletonHeader header;
        
        [streamer StreamInto:&header size:sizeof(SkeletonHeader)];
        
        // If the number of joints match those in the model
        if (header.mNumJoints == [(SimpleModel*)(((AnimationDebugStateMachine*)mStateMachine)->mDebugModel) CalculateNumJointsIndexed] )
        {
            [displayedSkeletons addObject:curPath];
        }
        
        [[ResourceManager GetInstance] UnloadAssetWithHandle:handle];
    }
    
    int count = 0;
    
    for (NSString* curPath in displayedSkeletons)
    {
        TextureButtonParams    params;
        
        [TextureButton InitDefaultParams:&params];
        
        params.mButtonText = curPath;
        params.mFontColor = 0xFF000000;
        params.mFontSize = 18;
                                
        TextureButton* button = [(TextureButton*)[TextureButton alloc] InitWithParams:&params];
        [button SetListener:self];
        [button SetPositionX:24 Y:(44 + (32 * count)) Z:0];
        [button SetUserData:(u32)curPath];
        
        [[GameObjectManager GetInstance] Add:button];
        [mSkeletonButtons addObject:button];
        
        [button release];
        
        count++;
    }
}

-(void)TeardownUI
{
    [[GameObjectManager GetInstance] Remove:mChooseSkeletonTextBox];
    [AnimationDebugStateMachine RemoveButtons:mSkeletonButtons];
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            NSString* filePath = (NSString*)[inButton GetUserData];
            
            NSNumber* handle = [[ResourceManager GetInstance] LoadAssetWithPath:filePath];
            NSData* data = [[ResourceManager GetInstance] GetDataForHandle:handle];
            
            AnimationDebugStateMachine* stateMachine = ((AnimationDebugStateMachine*)mStateMachine);
            
            Skeleton* skeleton = [(Skeleton*)[Skeleton alloc] InitWithData:data];
            [stateMachine->mDebugModel BindSkeleton:skeleton];
            [skeleton release];
            
            [stateMachine Push:[AnimationDebugChooseSkeletonAction alloc]];         
            break;
        }
    }
}

@end

#define CHOOSE_SKELETON_ACTION_NUM_BUTTONS  (2)

#define CHOOSE_SKELETON_MANIPULATE_JOINTS   'CSMJ'
#define CHOOSE_SKELETON_CHOOSE_ANIMATION    'CSCA'

static ButtonInitParams sChooseSkeletonActionButtons[CHOOSE_SKELETON_ACTION_NUM_BUTTONS] = 
                                                {   { 10.0f, 244.0f, "Manipulate Joints", CHOOSE_SKELETON_MANIPULATE_JOINTS },
                                                    { 10.0f, 269.0f, "Choose Animation", CHOOSE_SKELETON_CHOOSE_ANIMATION }    };

@implementation AnimationDebugChooseSkeletonAction

-(void)Startup;
{
    [self CreateUI];
}

-(void)Resume
{
    [self CreateUI];
}

-(void)Shutdown
{
    [self TeardownUI];
}

-(void)Suspend
{
    [self TeardownUI];
}

-(void)CreateUI
{
    mSkeletonActionButtons = [[NSMutableArray alloc] initWithCapacity:CHOOSE_SKELETON_ACTION_NUM_BUTTONS];
    [AnimationDebugStateMachine CreateButtons:sChooseSkeletonActionButtons numButtons:CHOOSE_SKELETON_ACTION_NUM_BUTTONS
                                referenceArray:mSkeletonActionButtons listener:self];
}

-(void)TeardownUI
{
    [AnimationDebugStateMachine RemoveButtons:mSkeletonActionButtons];
    [mSkeletonActionButtons release];
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            switch(inButton->mIdentifier)
            {
                case CHOOSE_SKELETON_MANIPULATE_JOINTS:
                {
                    [mStateMachine Push:[AnimationDebugChooseJoint alloc]];
                    break;
                }
                
                case CHOOSE_SKELETON_CHOOSE_ANIMATION:
                {
                    [mStateMachine Push:[AnimationDebugChooseAnimation alloc]];
                    break;
                }
            }
            
            break;
        }
    }
}

@end

@implementation AnimationDebugChooseJoint

static const char*  sShowAxesString = "Show Axes";
static const char*  sHideAxesString = "Hide Axes";

#define SHOW_AXES_BUTTON_POSITION_X     (274.0f)
#define SHOW_AXES_BUTTON_POSITION_Y     (219.0f)

-(void)Startup
{
    UIListParams listParams;
    
    [UIList InitDefaultParams:&listParams];
    
    mJointButtonsList = [(UIList*)[UIList alloc] InitWithParams:&listParams];
    [mJointButtonsList SetPositionX:0.0 Y:0.0 Z:0];
    
    TextureButtonParams buttonParams;
    
    [TextureButton InitDefaultParams:&buttonParams];
    
    buttonParams.mButtonTexBaseName = @"editorbutton_mid.png";
    buttonParams.mButtonTexHighlightedName = @"editorbutton_mid_lit.png";
    buttonParams.mFontSize = 18;
    buttonParams.mFontColor = 0xFF000000;

    Skeleton* skeleton = [(AnimationDebugStateMachine*)mStateMachine GetDebugSkeleton];
    int numJoints = [skeleton GetNumJoints];
    
    for (int i = 0; i < numJoints; i++)
    {
        Joint* curJoint = [skeleton GetJointWithIdentifier:i];
        
        buttonParams.mButtonText = [curJoint GetName];
        TextureButton* newButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&buttonParams];
        
        [newButton SetPositionX:JOINT_BUTTON_BASE_X Y:(JOINT_BUTTON_BASE_Y + (i * 20.0)) Z:0.0];
        newButton->mIdentifier = i;
        
        [newButton SetListener:self];
        
        [mJointButtonsList AddObject:newButton];
    }
    
    buttonParams.mButtonText = [NSString stringWithUTF8String:sShowAxesString];
    mShowAxesButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&buttonParams];
    
    [mShowAxesButton SetPositionX:SHOW_AXES_BUTTON_POSITION_X Y:SHOW_AXES_BUTTON_POSITION_Y Z:0];
    [mShowAxesButton SetListener:self];
    
    [[GameObjectManager GetInstance] Add:mShowAxesButton];
    [[GameObjectManager GetInstance] Add:mJointButtonsList];
    
    [mJointButtonsList release];
    [mShowAxesButton release];
    
    mShowAxes = TRUE;
}

-(void)Resume
{
    [mJointButtonsList SetVisible:TRUE];
    [mJointButtonsList Enable];
    
    [(AnimationDebugStateMachine*)mStateMachine SetActiveJointIndex:JOINT_INVALID_INDEX];
}

-(void)Shutdown
{
    [mJointButtonsList Remove];
    [mShowAxesButton Remove];
}

-(void)Suspend
{
    [mJointButtonsList SetVisible:FALSE];
    [mJointButtonsList Disable];
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            if (inButton == mShowAxesButton)
            {
                mShowAxes = !mShowAxes;
                
                if (mShowAxes)
                {
                    [((TextureButton*)inButton) SetText:[NSString stringWithUTF8String:sShowAxesString]];
                }
                else
                {
                    [((TextureButton*)inButton) SetText:[NSString stringWithUTF8String:sHideAxesString]];
                }
            }
            else
            {
                [(AnimationDebugStateMachine*)mStateMachine SetActiveJointIndex:inButton->mIdentifier];
                [mStateMachine Push:[AnimationDebugManipulateJoint alloc]];
            }
            
            break;
        }
    }
}

@end

@implementation AnimationDebugManipulateJoint

#define JOINT_PLUS_X    '__+X'
#define JOINT_MINUS_X   '__-X'
#define JOINT_PLUS_Y    '__+Y'
#define JOINT_MINUS_Y   '__-Y'
#define JOINT_PLUS_Z    '__+Z'
#define JOINT_MINUS_Z   '__-Z'
#define JOINT_REVERT    'RVRT'
#define JOINT_BACK      'BACK'

#define INACTIVE_BUTTON_IDENTIFIER  (0)

#define NUM_JOINT_MANIPULATION_BUTTONS  (8)

static ButtonInitParams   sEditButtonParams[NUM_JOINT_MANIPULATION_BUTTONS] = {     { 10, 200, "+X",   JOINT_PLUS_X },
                                                                                    { 10, 230, "-X",   JOINT_MINUS_X },
                                                                                    { 60, 200, "+Y",   JOINT_PLUS_Y },
                                                                                    { 60, 230, "-Y",   JOINT_MINUS_Y },
                                                                                    { 110, 200, "+Z",  JOINT_PLUS_Z },
                                                                                    { 110, 230, "-Z",  JOINT_MINUS_Z },
                                                                                    { 10, 260, "Revert", JOINT_REVERT },
                                                                                    { 10, 290, "Back", JOINT_BACK } };

-(void)Startup
{
    TextureButtonParams buttonParams;
    
    [TextureButton InitDefaultParams:&buttonParams];
    
    buttonParams.mFontSize = 18;
    buttonParams.mFontColor = 0xFF000000;
    
    mManipulationButtons = [[NSMutableArray alloc] initWithCapacity:NUM_JOINT_MANIPULATION_BUTTONS];
    
    JointTransform* rotationTransforms[3];
    
    [[GET_STATE_MACHINE() GetActiveJoint] GetJointRotationTransforms:rotationTransforms];

    for (int i = 0; i < NUM_JOINT_MANIPULATION_BUTTONS; i++)
    {        
        switch (sEditButtonParams[i].mButtonIdentifier)
        {
            case JOINT_PLUS_X:
            case JOINT_MINUS_X:
            {
                if (rotationTransforms[x] == NULL)
                {
                    continue;
                }
                
                break;
            }
            
            case JOINT_PLUS_Y:
            case JOINT_MINUS_Y:
            {
                if (rotationTransforms[y] == NULL)
                {
                    continue;
                }
                
                break;
            }
             
            case JOINT_PLUS_Z:
            case JOINT_MINUS_Z:
            {
                if (rotationTransforms[z] == NULL)
                {
                    continue;
                }
                
                break;
            }
        }
        
        buttonParams.mButtonText = [NSString stringWithUTF8String:sEditButtonParams[i].mText];
        
        if ([buttonParams.mButtonText length] >= MID_BUTTON_LENGTH)
        {
            buttonParams.mButtonTexBaseName = @"editorbutton_mid.png";
            buttonParams.mButtonTexHighlightedName = @"editorbutton_mid_lit.png";
        }
        else
        {
            buttonParams.mButtonTexBaseName = @"editorbutton.png";
            buttonParams.mButtonTexHighlightedName = @"editorbutton_lit.png";
        }
        
        TextureButton* newButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&buttonParams];
        
        [newButton SetPositionX:sEditButtonParams[i].mX Y:sEditButtonParams[i].mY Z:0.0];
        newButton->mIdentifier = sEditButtonParams[i].mButtonIdentifier;
        
        [newButton SetListener:self];
        
        [[GameObjectManager GetInstance] Add:newButton];
        [mManipulationButtons addObject:newButton];
        [newButton autorelease];
    }
    
    mActiveButtonIdentifier = INACTIVE_BUTTON_IDENTIFIER;
}

-(void)Resume
{
}

-(void)Shutdown
{
    [AnimationDebugStateMachine RemoveButtons:mManipulationButtons];
}

-(void)Suspend
{
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    switch(inEvent)
    {
        case BUTTON_EVENT_DOWN:
        {
            switch(inButton->mIdentifier)
            {
                case JOINT_BACK:
                {
                    [mStateMachine Pop];
                    break;
                }
                
                case JOINT_REVERT:
                {
                    Joint* curJoint = [(AnimationDebugStateMachine*)mStateMachine GetActiveJoint];
                    
                    int numTransforms = NeonArray_GetNumElements(curJoint->mTransforms);
                    
                    for (int curTransformIndex = 0; curTransformIndex < numTransforms; curTransformIndex++)
                    {
                        JointTransform* curTransform = *(JointTransform**)NeonArray_GetElementAtIndexFast(curJoint->mTransforms, curTransformIndex);
                        Set(&curTransform->mTransformModifier, 0.0, 0.0, 0.0);
                    }
                    
                    break;
                }
                
                default:
                {
                    mActiveButtonIdentifier = inButton->mIdentifier;
                    break;
                }
            }
            
            break;
        }
        
        case BUTTON_EVENT_UP:
        {
            mActiveButtonIdentifier = INACTIVE_BUTTON_IDENTIFIER;
            break;
        }
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    Joint* activeJoint = [(AnimationDebugStateMachine*)mStateMachine GetActiveJoint];
    
    if (activeJoint != NULL)
    {        
        JointTransform* jointTransform[3];
        
        [activeJoint GetJointRotationTransforms:jointTransform];
                
        switch(mActiveButtonIdentifier)
        {
            case JOINT_PLUS_X:
            {
                if (jointTransform[x] != NULL)
                {
                    jointTransform[x]->mTransformModifier.mVector[x] += 1.0;
                }
                
                break;
            }
            
            case JOINT_MINUS_X:
            {
                if (jointTransform[x] != NULL)
                {
                    jointTransform[x]->mTransformModifier.mVector[x] -= 1.0;
                }
                
                break;
            }
            
            case JOINT_PLUS_Y:
            {
                if (jointTransform[y] != NULL)
                {
                    jointTransform[y]->mTransformModifier.mVector[y] += 1.0;
                }
                
                break;
            }

            case JOINT_MINUS_Y:
            {
                if (jointTransform[y] != NULL)
                {
                    jointTransform[y]->mTransformModifier.mVector[y] -= 1.0;
                }
                
                break;
            }

            case JOINT_PLUS_Z:
            {
                if (jointTransform[z] != NULL)
                {
                    jointTransform[z]->mTransformModifier.mVector[z] += 1.0;
                }

                break;
            }

            case JOINT_MINUS_Z:
            {
                if (jointTransform[z] != NULL)
                {
                    jointTransform[z]->mTransformModifier.mVector[z] -= 1.0;
                }

                break;
            }
        }
    }
}

-(void)Draw
{
    Joint* activeJoint = [(AnimationDebugStateMachine*)mStateMachine GetActiveJoint];
    
    JointTransform* rotationTransforms[3];
    
    [activeJoint GetJointRotationTransforms:rotationTransforms];
    
    float xVal = 0.0;
    float yVal = 0.0;
    float zVal = 0.0;
    
    if (rotationTransforms[x] != NULL)
    {
        xVal = rotationTransforms[x]->mTransformModifier.mVector[x];
    }
    
    if (rotationTransforms[y] != NULL)
    {
        yVal = rotationTransforms[y]->mTransformModifier.mVector[y];
    }
    
    if (rotationTransforms[z] != NULL)
    {
        zVal = rotationTransforms[z]->mTransformModifier.mVector[z];
    }

    [[DebugManager GetInstance] DrawString:[NSString stringWithFormat:@"Angle: %0.3f, %0.3f, %0.3f",
                                            xVal, yVal, zVal] locX:10 locY:50];
}

@end

@implementation AnimationDebugChooseAnimation

-(void)Startup
{
    [self CreateUI];
}

-(void)Resume
{
    [self CreateUI];
}

-(void)Shutdown
{
    [self TeardownUI];
}

-(void)Suspend
{
    [self TeardownUI];
}

-(void)CreateUI
{
    TextBoxParams textBoxParams;
    
    [TextBox InitDefaultParams:&textBoxParams];
    
    textBoxParams.mString = [NSString stringWithUTF8String:CHOOSE_ANIMATION_STRING];
    textBoxParams.mFontSize = 18;
    
    SetColor(&textBoxParams.mColor, 0xFF, 0x00, 0x00, 0xFF);
    
    mChooseAnimationTextBox = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    [mChooseAnimationTextBox SetPositionX:10.0 Y:10.0 Z:0.0];
    
    [[GameObjectManager GetInstance] Add:mChooseAnimationTextBox];
    [mChooseAnimationTextBox release];
    
    NSMutableArray* potentialAnimations = [[ResourceManager GetInstance] FilesWithExtension:@"ANIM"];
    NSMutableArray* displayedAnimations = [[NSMutableArray alloc] initWithCapacity:[potentialAnimations count]];
    
    mAnimationButtons = [[NSMutableArray alloc] initWithCapacity:[potentialAnimations count]];

    for (NSString* curPath in potentialAnimations)
    {
        NSNumber* handle = [[ResourceManager GetInstance] StreamAssetWithPath:curPath];
        Streamer* streamer = [[ResourceManager GetInstance] GetStreamForHandle:handle];
        
        AnimationClipHeader header;
        [streamer StreamInto:&header size:sizeof(AnimationClipHeader)];
        
        // For now, display all possible animations.  In the future, we have to do some validation to see
        // if an animation is compatible with the currently loaded skeleton.
        [displayedAnimations addObject:curPath];
        
        [[ResourceManager GetInstance] UnloadAssetWithHandle:handle];
    }

    int count = 0;
    
    for (NSString* curPath in displayedAnimations)
    {
        TextureButtonParams    params;
        
        [TextureButton InitDefaultParams:&params];
        
        params.mButtonText = curPath;
        params.mFontColor = 0xFF000000;
        params.mFontSize = 18;
                                
        TextureButton* button = [(TextureButton*)[TextureButton alloc] InitWithParams:&params];
        [button SetListener:self];
        [button SetPositionX:24 Y:(44 + (32 * count)) Z:0];
        [button SetUserData:(u32)curPath];
        
        [[GameObjectManager GetInstance] Add:button];
        [mAnimationButtons addObject:button];
        
        [button release];
        
        count++;
    }
}

-(void)TeardownUI
{
    [[GameObjectManager GetInstance] Remove:mChooseAnimationTextBox];
    [AnimationDebugStateMachine RemoveButtons:mAnimationButtons];
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            NSString* filePath = (NSString*)[inButton GetUserData];
            
            NSNumber* handle = [[ResourceManager GetInstance] LoadAssetWithPath:filePath];
            NSData* data = [[ResourceManager GetInstance] GetDataForHandle:handle];
            
            AnimationDebugStateMachine* stateMachine = ((AnimationDebugStateMachine*)mStateMachine);
                        
            AnimationClip* animationClip = [(AnimationClip*)[AnimationClip alloc] InitWithData:data skeleton:[stateMachine GetDebugSkeleton]];
            
            if (stateMachine->mDebugAnimationClip != NULL)
            {
                [stateMachine->mDebugAnimationClip release];
            }
            
            stateMachine->mDebugAnimationClip = animationClip;
            
            [mStateMachine Push:[AnimationDebugPlayAnimation alloc]];
            
            break;
        }
    }
}

@end

#define ANIMATION_PLAY_STEP_BACKWARD    'APSB'
#define ANIMATION_PLAY_STEP_FORWARD     'APSF'
#define ANIMATION_PLAY_PLAY_PAUSE       'APPP'

#define NUM_ANIMATION_PLAY_BUTTONS  (3)

static ButtonInitParams   sAnimationPlayButtons[NUM_JOINT_MANIPULATION_BUTTONS] = { { 10, 244,  "<<",  ANIMATION_PLAY_STEP_BACKWARD },
                                                                                    { 65, 244,  ">",   ANIMATION_PLAY_PLAY_PAUSE },
                                                                                    { 120, 244, ">>",  ANIMATION_PLAY_STEP_FORWARD }    };

@implementation AnimationDebugPlayAnimation

-(void)Startup
{
    mAnimationPlayButtons = [[NSMutableArray alloc] initWithCapacity:NUM_ANIMATION_PLAY_BUTTONS];
    
    [AnimationDebugStateMachine CreateButtons:sAnimationPlayButtons numButtons:NUM_ANIMATION_PLAY_BUTTONS
                            referenceArray:mAnimationPlayButtons listener:self];
}

-(void)Resume
{
}

-(void)Shutdown
{
    [AnimationDebugStateMachine RemoveButtons:mAnimationPlayButtons];
}

-(void)Suspend
{
}

-(void)CreateUI
{
}

-(void)TeardownUI
{
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            switch(inButton->mIdentifier)
            {
                case ANIMATION_PLAY_STEP_FORWARD:
                {
                    CFTimeInterval curTime = [GET_STATE_MACHINE()->mDebugAnimationClip GetTime];
                    curTime += ANIMATION_STEP_TIME;
                    
                    AnimationClip_SetTime(GET_STATE_MACHINE()->mDebugAnimationClip, curTime);
                    
                    break;
                }
                
                case ANIMATION_PLAY_STEP_BACKWARD:
                {
                    CFTimeInterval curTime = [GET_STATE_MACHINE()->mDebugAnimationClip GetTime];
                    curTime -= ANIMATION_STEP_TIME;
                    
                    AnimationClip_SetTime(GET_STATE_MACHINE()->mDebugAnimationClip, curTime);

                    break;
                }
                
                case ANIMATION_PLAY_PLAY_PAUSE:
                {
                    [GET_STATE_MACHINE()->mDebugAnimationClip Play];
                    break;
                }
            }
            
            break;
        }
    }
}

@end

#define FREE_CAMERA_BACK               'BACK'

#define NUM_FREE_CAMERA_ACTIONS         (1)

static ButtonInitParams   sFreeCameraButtons[NUM_FREE_CAMERA_ACTIONS] = { { 10, 295, "Back",  FREE_CAMERA_BACK } };

@implementation AnimationDebugFreeCamera

-(void)Startup
{
    mDebugCamera = [[DebugCamera alloc] InitWithCamera:(((AnimationDebugStateMachine*)mStateMachine)->mAnimCamera)];
    
    mFreeCameraButtons = [[NSMutableArray alloc] initWithCapacity:NUM_FREE_CAMERA_ACTIONS];
    [AnimationDebugStateMachine CreateButtons:sFreeCameraButtons numButtons:1 referenceArray:mFreeCameraButtons listener:self];
}

-(void)Resume
{
}

-(void)Shutdown
{
    [mDebugCamera release];
    
    [AnimationDebugStateMachine RemoveButtons:mFreeCameraButtons];
    [mFreeCameraButtons release];
}

-(void)Suspend
{
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            switch(inButton->mIdentifier)
            {
                case FREE_CAMERA_BACK:
                {
                    [mStateMachine Pop];
                    break;
                }
            }
            
            break;
        }
    }
}

-(void)DrawOrtho
{
    [mDebugCamera DrawOrtho];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [mDebugCamera Update:inTimeStep];
}

@end


@implementation AnimationDebugState

-(void)Startup
{
    Model* initModel = NULL;
    
    if (OVERRIDE_MODEL_NAME[0] != 0)
    {
        initModel = [[ModelManager GetInstance] ModelWithName:[NSString stringWithUTF8String:OVERRIDE_MODEL_NAME] owner:NULL];
        
        if (OVERRIDE_MODEL_SKEL[0] != 0)
        {
            [initModel BindSkeletonWithFilename:[NSString stringWithUTF8String:OVERRIDE_MODEL_SKEL]];
        }
    }

    mAnimationDebugStateMachine = [(AnimationDebugStateMachine*)[AnimationDebugStateMachine alloc] InitWithModel:initModel skeleton:[initModel GetSkeleton]];
    [mAnimationDebugStateMachine Push:[AnimationDebugChooseModel alloc]];
    
    if (OVERRIDE_MODEL_NAME[0] != 0)
    {
        [mAnimationDebugStateMachine Push:[AnimationDebugChooseModelAction alloc]];         

        if (OVERRIDE_MODEL_SKEL[0] != 0)
        {
            [mAnimationDebugStateMachine Push:[AnimationDebugChooseSkeletonAction alloc]];
            
            if (OVERRIDE_MODEL_ANIM[0] != 0)
            {
                NSNumber* handle = [[ResourceManager GetInstance] LoadAssetWithName:[NSString stringWithUTF8String:OVERRIDE_MODEL_ANIM]];
                NSData* data = [[ResourceManager GetInstance] GetDataForHandle:handle];
                                    
                AnimationClip* animationClip = [(AnimationClip*)[AnimationClip alloc] InitWithData:data skeleton:[mAnimationDebugStateMachine GetDebugSkeleton]];
            
                mAnimationDebugStateMachine->mDebugAnimationClip = animationClip;
                
                [mAnimationDebugStateMachine Push:[AnimationDebugPlayAnimation alloc]];
            }
        }
    }
    
    [[ModelManager GetInstance] SetDrawingEnabled:FALSE];
    
    mLight = [[LightManager GetInstance] CreateLight];

    LightParams params;
    
    [Light InitDefaultParams:&params];
    Set(&params.mVector, 0.0, 0.0, 20.0);
    
    [mLight SetLightActive:TRUE];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [mAnimationDebugStateMachine Update:inTimeStep];
}

-(void)Shutdown
{
    [mAnimationDebugStateMachine release];
    [[ModelManager GetInstance] SetDrawingEnabled:TRUE];
    
    [[LightManager GetInstance] RemoveLight:mLight];
}

-(void)Draw
{
    [mAnimationDebugStateMachine Draw];
}

-(void)DrawOrtho
{
    [mAnimationDebugStateMachine DrawOrtho];
}

@end