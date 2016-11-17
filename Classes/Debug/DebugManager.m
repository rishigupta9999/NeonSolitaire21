//
//  DebugManager.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "DebugManager.h"
#import "Texture.h"
#import "TextTextureBuilder.h"

#import "ModelManager.h"
#import "GameStateMgr.h"
#import "CameraStateMgr.h"

#import "PrimitiveLibrary.h"
#include <sys/socket.h>
#include <netinet/in.h>

#define DEFAULT_INITIAL_CAPACITY    (16)
#define PICK_RAY_SPEED              (8.0f)
#define PICK_RAY_DURATION           (0.5f)

static NSString* DRAW_PICK_RAYS_STRING = @"Draw Pick Rays";
static NSString* NEON_TRANSPORT_SERVICE = @"_neonengine._tcp.";

static void serverAcceptCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@implementation DebugMenuItem

-(DebugMenuItem*)Init
{
    mName = NULL;
    mCallback = NULL;
    mButton = NULL;
    
    return self;
}

-(void)dealloc
{
    [mName release];
    
    [super dealloc];
}

@end

@implementation DebugManager

static DebugManager* sInstance = NULL;

+(void)CreateInstance
{
    sInstance = [DebugManager alloc];
	[sInstance Init];
}

+(void)DestroyInstance
{
    [sInstance Term];
    
    [sInstance release];
    
    sInstance = NULL;
}

+(DebugManager*)GetInstance
{
    return sInstance;
}

-(void)Init
{
    sInstance->mElapsedTime = 0.0f;
    
    mDebugMenuActive = FALSE;
    
#if DRAW_DEBUGMANAGER            
		// Set up the debug button
		TextureButtonParams params;
		
		[TextureButton InitDefaultParams:&params];
		params.mButtonTexBaseName = @"button_debug.png";
		params.mButtonTexHighlightedName = @"button_debug_lit.png";
		
		mDebugButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&params];
        [mDebugButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_ALL];
		
	#if LANDSCAPE_MODE
		[mDebugButton SetPositionX:350.0f Y:5.0f Z:0.0f];
	#else
		[mDebugButton SetPositionX:10.0f Y:430.0f Z:0.0f];
	#endif

#endif
    [mDebugButton SetListener:self];
    
    mDebugDepth = 0;
    
    mMenuItems = [[NSMutableArray alloc] initWithCapacity:DEFAULT_INITIAL_CAPACITY];

    mPickRayState = PICK_RAY_IDLE;
    SetVec4(&mPickRayStart, 0.0f, 0.0f, 0.0f, 0.0f);
    SetVec4(&mPickRayDirectionVector, 0.0f, 0.0f, 0.0f, 0.0f);
    mPickRayTime = -1.0f;
    
    mDrawPickRays = FALSE;
    
    [GetGlobalMessageChannel() AddListener:self];
    
    [self CreateServer];
    
    [self RegisterDebugMenuItem:DRAW_PICK_RAYS_STRING WithCallback:self];
}

-(void)Term
{
    [self UnregisterDebugMenuItem:DRAW_PICK_RAYS_STRING];
    
    [mDebugButton Remove];
    [mMenuItems release];
    
    [GetGlobalMessageChannel() RemoveListener:self];
    
    [self TerminateBonjourService];
}

-(void)TerminateBonjourService
{
    if (mNetService != NULL)
    {
        [mNetService setDelegate:nil];
        [mNetService stop];
        [mNetService release];
    }

    if (mListeningSocket != 0)
    {
        CFSocketInvalidate(mListeningSocket);
        CFRelease(mListeningSocket);
    }
    
    [mClientConnection Close];
}

-(void)CreateServer
{
    int                 err;
    int                 fdForListening;
    int                 chosenPort;
    socklen_t           namelen;
    
    mClientConnection = NULL;
    
    chosenPort = -1;        // quieten assert

    // Here, create the socket from traditional BSD socket calls, and then set up a CFSocket with that to listen for 
    // incoming connections.

    // Start by trying to do everything with IPv6.  This will work for both IPv4 and IPv6 clients 
    // via the miracle of mapped IPv4 addresses.
    
    err = 0;
    fdForListening = socket(AF_INET6, SOCK_STREAM, 0);
    
    if (fdForListening < 0)
    {
        err = errno;
    }
    
    if (err == 0)
    {
        struct sockaddr_in6 serverAddress6;

        // If we created an IPv6 socket, bind it to a kernel-assigned port and then use 
        // getsockname to determine what port we got.
        
        memset(&serverAddress6, 0, sizeof(serverAddress6));
        serverAddress6.sin6_family = AF_INET6;
        serverAddress6.sin6_len    = sizeof(serverAddress6);

        err = bind(fdForListening, (const struct sockaddr *) &serverAddress6, sizeof(serverAddress6));
        if (err < 0) {
            err = errno;
        }
        if (err == 0) {
            namelen = sizeof(serverAddress6);
            err = getsockname(fdForListening, (struct sockaddr *) &serverAddress6, &namelen);
            if (err < 0) {
                err = errno;
                assert(err != 0);       // quietens static analyser
            } else {
                chosenPort = ntohs(serverAddress6.sin6_port);
            }
        }
    } else if (err == EAFNOSUPPORT) {
        struct sockaddr_in  serverAddress;

        // IPv6 is not available (this can happen, for example, on early versions of iOS).  
        // Let's fall back to IPv4.  Create an IPv4 socket, bind it to a kernel-assigned port 
        // and then use getsockname to determine what port we got.
        
        err = 0;
        fdForListening = socket(AF_INET, SOCK_STREAM, 0);
        if (fdForListening < 0) {
            err = errno;
        }

        if (err == 0) {
            memset(&serverAddress, 0, sizeof(serverAddress));
            serverAddress.sin_family = AF_INET;
            serverAddress.sin_len    = sizeof(serverAddress);

            err = bind(fdForListening, (const struct sockaddr *) &serverAddress, sizeof(serverAddress));
            if (err < 0) {
                err = errno;
            }
        }
        if (err == 0) {
            namelen = sizeof(serverAddress);
            err = getsockname(fdForListening, (struct sockaddr *) &serverAddress, &namelen);
            if (err < 0) {
                err = errno;
                assert(err != 0);       // quietens static analyser
            } else {
                chosenPort = ntohs(serverAddress.sin_port);
            }
        }
    }
    
    // Listen for connections on our socket, then create a CFSocket to route any connections 
    // to a run loop based callback.
    
    if (err == 0) {
        err = listen(fdForListening, 5);
        if (err < 0) {
            err = errno;
        } else {
            CFSocketContext     context = {0, (__bridge void *)(self), NULL, NULL, NULL};
            CFRunLoopSourceRef  rls;
            
            mListeningSocket = CFSocketCreateWithNative(NULL, fdForListening, kCFSocketAcceptCallBack, serverAcceptCallback, &context);
            
            if (mListeningSocket != NULL)
            {
                assert( CFSocketGetSocketFlags(mListeningSocket) & kCFSocketCloseOnInvalidate );
                fdForListening = -1;        // so that the clean up code doesn't close it
                
                rls = CFSocketCreateRunLoopSource(NULL, mListeningSocket, 0);
                assert(rls != NULL);
                
                CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
                
                CFRelease(rls);
            }
        }
    }

    // Register our service with Bonjour.

    if (err == 0) {
        NSLog(@"chosenPort = %d", chosenPort);

        mNetService = [[NSNetService alloc] initWithDomain:@"local." type:NEON_TRANSPORT_SERVICE name:@"FOO" port:chosenPort];
        if (mNetService != nil) {
            [mNetService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [mNetService setDelegate:self];
            [mNetService publish];
        }
    }
}

-(void)HandleClientConnectedWithSocket:(CFSocketNativeHandle)inSocket
{
    NSLog(@"HandleClientConnectedWithSocket");
    mClientConnection = [[Connection alloc] initWithNativeSocketHandle:inSocket];
    mClientConnection.Delegate = self;
}

-(void)ReceivedNetworkPacket:(NSDictionary*)message viaConnection:(Connection*)connection
{
    NSString* type = [message objectForKey:@"Type"];
    
    if ([type compare:@"Request Debug Menu"] == NSOrderedSame)
    {
        NSLog(@"Request Debug Menu");
    }
}

-(void)netService:(NSNetService*)sender didNotPublish:(NSDictionary*)errorDict
{
    NSLog(@"Couldn't publish Bonjour Service");
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_APPLICATION_RESUMED:
        {
            [self CreateServer];
            break;
        }
        
        case EVENT_APPLICATION_SUSPENDED:
        {
            [self TerminateBonjourService];
            break;
        }
    }
}

-(void)DrawString:(NSString*)str locX:(int)in_X locY:(int)in_Y
{
    [self DrawString:str locX:in_X locY:in_Y size:14 red:1.0 blue:1.0 green:1.0];
}

-(void)DrawString:(NSString*)str locX:(int)in_X locY:(int)in_Y size:(int)inSize red:(float)inRed blue:(float)inBlue green:(float)inGreen
{
    GLState glState;
    SaveGLState(&glState);
    
	NeonGLDisable(GL_DEPTH_TEST);
    
    u32 redInt = (u32)(inRed * 255.0);
    u32 greenInt = (u32)(inGreen * 255.0);
    u32 blueInt = (u32)(inBlue * 255.0);
    
    u32 color = (redInt << 24) | (greenInt << 16) | (blueInt << 8) | 0xFF;
    
	// Create the texture to draw to
    
    TextTextureParams params;
    
    [TextTextureBuilder InitDefaultParams:&params];
    
    params.mFontName = [NSString stringWithString:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
    params.mPointSize = inSize;
    params.mString = str;
    params.mColor = color;
    params.mStrokeSize = 1;
    params.mStrokeColor = 0x000000FF;
    params.mPremultipliedAlpha = TRUE;
    
	Texture *textTexture = [[TextTextureBuilder GetInstance] GenerateTextureWithParams:&params];
	
	float vertexArray[12] = {   0, 0, 0,
                                0, 1, 0,
                                1, 0, 0,
                                1, 1, 0 };
    
    float texCoordArray[8] = {  0, 0,
                                0, 1,
                                1, 0,
                                1, 1 };
	
    float normalArray[12] = {   0, 0, 1,
                                0, 0, 1,
                                0, 0, 1,
                                0, 0, 1 };
    
	NeonGLEnable(GL_BLEND);
    NeonGLBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
	
    // Save old projection matrix ourselves.  We're running out of Matrix stack space.
    
    float projectionMatrix[16];
    glGetFloatv(GL_PROJECTION_MATRIX, projectionMatrix);
    
    NeonGLMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(-160.0f, 160.0f, -240.0f, 240.0f, -1.0f, 1.0f);
    
    NeonGLError();
    
    NeonGLMatrixMode(GL_MODELVIEW);
	glPushMatrix();
    
    NeonGLError();
    
    {
        [textTexture Bind];
        
        glTranslatef(in_X, in_Y, 0.0f); // todo take a translation comp.
        glScalef([textTexture GetGLWidth], [textTexture GetGLHeight], 1.0f);
		
        glVertexPointer(3, GL_FLOAT, 0, vertexArray);
        glTexCoordPointer(2, GL_FLOAT, 0, texCoordArray);
        glNormalPointer(GL_FLOAT, 0, normalArray);
		
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        [Texture Unbind];
    }
    NeonGLMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    
    NeonGLMatrixMode(GL_PROJECTION);
    glLoadMatrixf(projectionMatrix);
    
    RestoreGLState(&glState);
}

-(void)DrawOrtho:(CFTimeInterval)inTimeStep
{
    NeonGLDisable(GL_DEPTH_TEST);
    
    NeonGLError();
    
    float vertexArray[12] = {   0, 0, 0,
                                0, 1, 0,
                                1, 0, 0,
                                1, 1, 0 };
                                
    float colorArray[16] = {    0.0f, 0.0f, 0.0f, 0.7f,
                                0.0f, 0.0f, 0.0f, 0.7f,
                                0.0f, 0.0f, 0.0f, 0.7f,
                                0.0f, 0.0f, 0.0f, 0.7f };
                                
                                
    if (mDebugMenuActive)
    {
		[[ModelManager GetInstance] SetupUICamera];

        // Draw background quad to darken the screen
        NeonGLMatrixMode(GL_MODELVIEW);
        glPushMatrix();
        {
			
#if LANDSCAPE_MODE
            glScalef(480.0f, 320.0f, 1.0f);
#else
            glScalef(320.0f, 480.0f, 1.0f);
#endif

            glEnableClientState(GL_VERTEX_ARRAY);
            glEnableClientState(GL_COLOR_ARRAY);
                        
            glVertexPointer(3, GL_FLOAT, 0, vertexArray);
            glColorPointer(4, GL_FLOAT, 0, colorArray);
            
            NeonGLEnable(GL_BLEND);
            NeonGLBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            NeonGLDisable(GL_BLEND);
            
            glDisableClientState(GL_VERTEX_ARRAY);
            glDisableClientState(GL_COLOR_ARRAY);
        }
        glPopMatrix();
        
        // Draw buttons on top
        		
        for (DebugMenuItem* curMenuItem in mMenuItems)
        {
            if (curMenuItem->mButton != NULL)
            {
                [[ModelManager GetInstance] DrawObject:curMenuItem->mButton];
            }
        }
		
		[[ModelManager GetInstance] TeardownUICamera];
    }

	[[ModelManager GetInstance] SetupUICamera];
    [[ModelManager GetInstance] DrawObject:mDebugButton];
	[[ModelManager GetInstance] TeardownUICamera];

    switch(mPickRayState)
    {
        case PICK_RAY_ANIMATING:
        {
            mPickRayTime += inTimeStep;
            
            if (mPickRayTime >= PICK_RAY_DURATION)
            {
                mPickRayTime = PICK_RAY_DURATION;
                mPickRayState = PICK_RAY_WAITING_TO_EXPIRE;
            }
            
            [self DrawPickRay];
            
            break;
        }
        case PICK_RAY_WAITING_TO_EXPIRE:
        {
            mPickRayState = PICK_RAY_IDLE;
            break;
        }
        default:
        {
            break;
        }
    }
    
    NeonGLError();
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if (inEvent == BUTTON_EVENT_DOWN)
    {
        if (inButton == mDebugButton)
        {
            [self DebugMenuToggle];
        }
        else
        {
            // We must have hit a debug menu item.  Let's check for this.
            
            for (DebugMenuItem* curMenuItem in mMenuItems)
            {
                if (curMenuItem->mButton != NULL)
                {
                    if (curMenuItem->mButton == inButton)
                    {
                        [curMenuItem->mCallback DebugMenuItemPressed:curMenuItem->mName];
                    }
                }
            }
        }
    }
}

-(void)DebugMenuToggle
{
    mDebugMenuActive = !mDebugMenuActive;
    
    if (mDebugMenuActive)
    {
        // Create the buttons to display in the debug menu if we just activated
        
        TextureButtonParams    params;
        
        [TextureButton InitDefaultParams:&params];
        
        int count = 0;
        
        for (DebugMenuItem* curMenuItem in mMenuItems)
        {
            params.mButtonText = curMenuItem->mName;
            params.mFontColor = 0xFF0000FF;
            params.mFontSize = 14;
            
            NSAssert(curMenuItem->mButton == NULL, @"Reallocating a debug menu button that already exists.  This will cause a memory leak.\n");
            
            curMenuItem->mButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&params];
            
            [curMenuItem->mButton SetListener:self];

#if LANDSCAPE_MODE            
            [curMenuItem->mButton SetPositionX:20 Y:(30 + (24 * count)) Z:0];
#else
            [curMenuItem->mButton SetPositionX:10 Y:(64 + (32 * count)) Z:0];
#endif
            count++;
        }
    }
    else
    {
        for (DebugMenuItem* curMenuItem in mMenuItems)
        {
            [curMenuItem->mButton Remove];
            [curMenuItem->mButton release];
            
            curMenuItem->mButton = NULL;
        }
    }
}

-(void)RegisterDebugMenuItem:(NSString*)inName WithCallback:(NSObject<DebugMenuCallback>*)inCallback
{
    // Sanity check, make sure we have no other items with this name
    for (DebugMenuItem* curMenuItem in mMenuItems)
    {
        NSAssert( ([curMenuItem->mName compare:inName] != NSOrderedSame), @"Trying to add two debug menu items with the same name");
    }
    
    DebugMenuItem* newMenuItem = [(DebugMenuItem*)[DebugMenuItem alloc] Init];
    
    newMenuItem->mName = [inName retain];
    newMenuItem->mCallback = inCallback;
    
    [mMenuItems addObject:newMenuItem];
    [newMenuItem release];
}

-(void)UnregisterDebugMenuItem:(NSString*)inName
{
    for (DebugMenuItem* curMenuItem in mMenuItems)
    {
        if ([curMenuItem->mName compare:inName] == NSOrderedSame)
        {
            [mMenuItems removeObject:curMenuItem];
            return;
        }
    }
    
    NSAssert(FALSE, @"Could not find debug menu item");
}

-(void)ToggleDebugGameState:(id)inStateType;
{
    if (mDebugDepth == 0)
    {
        [[GameStateMgr GetInstance] Push:[inStateType alloc]];
        mDebugDepth++;
    }
    else
    {
        GameState* activeState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];
        
        if ([activeState class] == inStateType)
        {
            [[GameStateMgr GetInstance] Pop];
            mDebugDepth--;
        }
        else
        {
            [[GameStateMgr GetInstance] ReplaceTop:[inStateType alloc]];
        }
    }
}

-(BOOL)DebugGameStateActive
{
    return (mDebugDepth != 0);
}

-(void)SpawnPickRay:(Vector4*)inRay
{
    if (mDrawPickRays)
    {
        if (mPickRayState == PICK_RAY_IDLE)
        {
            mPickRayState = PICK_RAY_ANIMATING;
            mPickRayTime = 0.0f;
            
            CloneVec4(inRay, &mPickRayDirectionVector);
            Normalize4(&mPickRayDirectionVector);
            
            Vector3 cameraPosition;
            [[CameraStateMgr GetInstance] GetPosition:&cameraPosition];
            
            SetVec4From3(&mPickRayStart, &cameraPosition, 1.0f);
        }
    }
}

-(void)DrawPickRay
{
    [[ModelManager GetInstance] SetupWorldCamera];
    
    ConeMeshInputParams inputParams;
    [PrimitiveLibrary InitDefaultConeMeshParams:&inputParams];
    
    SetVec3From4(&inputParams.mTip, &mPickRayStart);
    SetVec3From4(&inputParams.mDirection, &mPickRayDirectionVector);
    
    Vector3 offsetVector;
    CloneVec3(&inputParams.mDirection, &offsetVector);
    Scale3(&offsetVector, 1.0f);
    
    Add3(&inputParams.mTip, &offsetVector, &inputParams.mTip);
    
    inputParams.mLength = 12.0f;
    inputParams.mConeAngleDegrees = mPickRayTime * PICK_RAY_SPEED;
    
    ConeMesh* coneMesh = [PrimitiveLibrary BuildConeMeshWithParams:&inputParams];
    
    NeonGLEnable(GL_DEPTH_TEST);
    
    float* colorArray = (float*)malloc(sizeof(float) * 4 * coneMesh->mNumVertices);
    
    colorArray[0] = 1.0f;
    colorArray[1] = 1.0f;
    colorArray[2] = 1.0f;
    colorArray[3] = 1.0f;
    
    for (int i = 1; i < coneMesh->mNumVertices; i++)
    {
        colorArray[(i * 4) + 0] = 1.0f;
        colorArray[(i * 4) + 1] = 0.0f;
        colorArray[(i * 4) + 2] = 0.0f;
        colorArray[(i * 4) + 3] = 1.0f;
    }
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    
    glVertexPointer(3, GL_FLOAT, 0, coneMesh->mVertexArray);
    glColorPointer(4, GL_FLOAT, 0, colorArray);
    
    glDrawElements(GL_LINES, coneMesh->mNumIndices, GL_UNSIGNED_SHORT, coneMesh->mIndexArray);
    
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);

    NeonGLDisable(GL_DEPTH_TEST);
    
    free(colorArray);

    [[ModelManager GetInstance] TeardownWorldCamera];
}

-(void)DebugMenuItemPressed:(NSString*)inName
{
    if ([inName compare:DRAW_PICK_RAYS_STRING] == NSOrderedSame)
    {
        mDrawPickRays = !mDrawPickRays;
    }
}

@end

static void serverAcceptCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    // We can only process "connection accepted" calls here
    if (type != kCFSocketAcceptCallBack)
    {
        return;
    }
  
    // for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
    CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle*)data;

    [[DebugManager GetInstance] HandleClientConnectedWithSocket:nativeSocketHandle];
}
