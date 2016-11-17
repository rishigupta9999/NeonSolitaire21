//
//  ResourceManager.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.

#import "ResourceManager.h"
#import "BigFile.h"
#import "Streamer.h"

static const char* RETINA_PREFIX = "x2";

enum
{
	ASSET_INDEX_RETINA,
	ASSET_INDEX_NORMAL,
	ASSET_INDEX_NUM
};

@implementation FileNode
-(void)dealloc
{
    [mAssetName release];
    [mPath release];
    
    [super dealloc];
}
@end

@implementation ResourceNode

-(void)Reset
{
    mPath = NULL;
    
    mReferenceCount = 0;
    mHandle = 0;
    mResourceType = RESOURCETYPE_INVALID;
    
    mData = 0;
    mMetadata = 0;
	
	mResourceFamily = RESOURCEFAMILY_PHONE;
}

-(void)dealloc
{
    [mPath release];
    [mHandle release];
    [mData release];
    
    switch(mResourceType)
    {
        case RESOURCETYPE_BIGFILE:
        case RESOURCETYPE_STANDARD:
        {
            [(NSObject*)mMetadata release];
            break;
        }
        
        case RESOURCETYPE_FILE_HANDLE:
        {
            fclose((FILE*)mMetadata);
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown resource type");
            break;
        }
    }

    [super dealloc];
}

@end

@implementation ResourceManager

static ResourceManager* sInstance = NULL;

static const int INITIAL_NUM_FILENODES = 10;
static const int INITIAL_NUM_FREEHANDLES = 0;
static const int INITIAL_HANDLE = 0;

+(void)CreateInstance
{
    sInstance = [ResourceManager alloc];
    
    [sInstance Init];
}

+(void)DestroyInstance
{
    [sInstance Term];
    
    [sInstance release];
    
    sInstance = NULL;
}

+(ResourceManager*)GetInstance
{
    return sInstance;
}

-(void)Init
{
    mFileNodes = [[NSMutableArray alloc] initWithCapacity:INITIAL_NUM_FILENODES];
    mResourceNodes = [[NSMutableArray alloc] initWithCapacity:INITIAL_NUM_FILENODES];
    mFreeHandles = [[NSMutableArray alloc] initWithCapacity:INITIAL_NUM_FREEHANDLES];
    mApplicationResourcePath = [[NSString alloc] initWithString:[[NSBundle mainBundle] resourcePath]];
    
    mCurHandle = INITIAL_HANDLE;
    
    mOperationQueue = dispatch_queue_create("com.neongames.ResourceManager", NULL);
    
#if TARGET_OS_IPHONE
    [self SetState:RESOURCE_MANAGER_STATE_INITIALIZING];
    
    dispatch_async(mOperationQueue, ^
    {
        [self GenerateFileNodes];
        [self SetState:RESOURCE_MANAGER_STATE_READY];
    } );
#else
    [self SetState:RESOURCE_MANAGER_STATE_READY];
#endif
}

-(void)Term
{
    [mResourceNodes release];
    [mFreeHandles release];
    [mApplicationResourcePath release];
    [mFileNodes release];
    
    dispatch_release(mOperationQueue);
}

+(void)InitDefaultParams:(ResourceLoadParams*)outParams
{
    outParams->mOptional = TRUE;
	outParams->mAttemptRetina = FALSE;
}

-(void)GenerateFileNodes
{
    NSString* appPath = [[NSBundle mainBundle] bundlePath];
    NSString* dataPath = [appPath stringByAppendingPathComponent:@"Data"];
    
    NSDirectoryEnumerator* directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:dataPath];
    NSAssert(directoryEnumerator != NULL, @"Game data not found, are the paths set up correctly?\n");
    
    NSString* fileName = NULL;
    
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:dataPath];
    
    do
    {
        fileName = [directoryEnumerator nextObject];
        
        if (fileName != NULL)
        {
            BOOL directory = FALSE;
            
            [[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:&directory];
            
            if (!directory)
            {
                FileNode* curNode = [FileNode alloc];
                
                curNode->mPath = [[NSString alloc] initWithString:fileName];
                curNode->mAssetName = [[NSString alloc] initWithString:[fileName lastPathComponent]];
                
                [mFileNodes addObject:curNode];
                
                [curNode release];
            }
        }
    }
    while (fileName != NULL);
}

-(NSNumber*)StreamAssetWithPath:(NSString*)inPath
{
    [self SetWorkingDirectory];
    
    return [self InternalLoadAssetWithPath:inPath loadType:LOADTYPE_STREAM];
}

-(NSNumber*)StreamAssetWithName:(NSString*)inName params:(ResourceLoadParams*)inParams
{
    return [self InternalLoadAssetWithName:inName loadType:LOADTYPE_STREAM params:inParams];
}

-(NSNumber*)StreamAssetWithName:(NSString*)inName
{
    return [self InternalLoadAssetWithName:inName loadType:LOADTYPE_STREAM params:NULL];
}

-(NSNumber*)LoadAssetWithName:(NSString*)inName
{
    return [self InternalLoadAssetWithName:inName loadType:LOADTYPE_ALLOC params:NULL];
}

-(NSNumber*)LoadAssetWithName:(NSString*)inName params:(ResourceLoadParams*)inParams
{
    return [self InternalLoadAssetWithName:inName loadType:LOADTYPE_ALLOC params:inParams];
}

-(NSNumber*)LoadMappedAssetWithName:(NSString*)inName
{
    return [self InternalLoadAssetWithName:inName loadType:LOADTYPE_MMAP params:NULL];
}

-(NSNumber*)LoadAssetWithPath:(NSString*)inPath
{
    return [self InternalLoadAssetWithPath:inPath loadType:LOADTYPE_ALLOC];
}

-(NSNumber*)InternalLoadAssetWithPath:(NSString*)inPath loadType:(LoadType)inLoadType
{
    // Check and see if this asset exists in the resource list
    
    NSNumber* retHandle = NULL;
    
    [self SetWorkingDirectory];
    
    while ([self GetState] != RESOURCE_MANAGER_STATE_READY)
    {
        [NSThread sleepForTimeInterval:0.1f];
    }
    
    ResourceNode* resourceNode = [self FindResourceWithPath:inPath];
    
    if (resourceNode != NULL)
    {
        resourceNode->mReferenceCount++;
        retHandle = resourceNode->mHandle;
    }
    else
    {
        ResourceNode* resourceNode = [self CreateResourceNodeWithPath:inPath];
        [self LoadData:resourceNode loadType:inLoadType];
        
        retHandle = resourceNode->mHandle;
    }
    
    return retHandle;
}

-(NSNumber*)InternalLoadAssetWithName:(NSString*)inName loadType:(LoadType)inLoadType params:(ResourceLoadParams*)inParams
{
    NSAssert(inLoadType != LOADTYPE_MMAP, @"MMAP is unimplemented");
    
    while ([self GetState] != RESOURCE_MANAGER_STATE_READY)
    {
        [NSThread sleepForTimeInterval:0.1f];
    }
    
    // Check and see if this asset exists in the resource list
    
    NSNumber* retHandle = NULL;
	
	NSMutableArray* assetLoadList = [[NSMutableArray alloc] initWithCapacity:ASSET_INDEX_NUM];
	[assetLoadList autorelease];
        
	NSString* retinaName = [NSString stringWithFormat:@"%s_%@", RETINA_PREFIX, inName];
	[assetLoadList addObject:retinaName];
	
	[assetLoadList addObject:inName];
	
	for (int i = 0; i < ASSET_INDEX_NUM; i++)
	{
		// If we don't want to attempt loading retina display assets, then skip this iteration of the loop.
		if ((i == ASSET_INDEX_RETINA) && (inParams != NULL) && (!inParams->mAttemptRetina))
		{
			continue;
		}
		
		NSString* curAsset = [assetLoadList objectAtIndex:i];
		
		ResourceNode* resourceNode = [self FindResourceWithName:curAsset];
		
		if (resourceNode != NULL)
		{
			resourceNode->mReferenceCount++;
			retHandle = resourceNode->mHandle;
			break;
		}
		else
		{
			FileNode* fileNode = [self FindFileWithName:curAsset];
			
			if (((inParams == NULL) || (!inParams->mOptional)) && (i == ASSET_INDEX_NORMAL))
			{
				NSAssert1(fileNode != NULL, @"Could not find file %s.  No data will be loaded here.\n", [curAsset UTF8String]);
			}
			else if (fileNode == NULL)
			{
				continue;
			}
			
			if (fileNode != NULL)
			{
				ResourceNode* resourceNode = [self CreateResourceNodeWithPath:fileNode->mPath];
				
				[self LoadData:resourceNode loadType:inLoadType];
				
				retHandle = resourceNode->mHandle;
				
				if (i == ASSET_INDEX_RETINA)
				{
					resourceNode->mResourceFamily = RESOURCEFAMILY_PHONE_RETINA;
				}
				
				break;
			}
		}
	}
    
    NSAssert1(retHandle != NULL, @"Could not load %@ since it was not found.", inName);
    
    return retHandle;
}

-(NSString*)FindAssetWithName:(NSString*)inName
{
    FileNode* fileNode = [self FindFileWithName:inName];
    NSAssert1(fileNode != NULL, @"Could not find file %s.", [ inName UTF8String ] );
    
    NSString* retString = [NSString stringWithString:fileNode->mPath];
    
    return retString;
}

-(ResourceNode*)CreateResourceNodeWithPath:(NSString*)inPath
{
    ResourceNode* resourceNode = [ResourceNode alloc];
    
    resourceNode->mPath = [[NSString alloc] initWithString:inPath];
    resourceNode->mReferenceCount = 1;
    resourceNode->mMetadata = NULL;
    
    int numFreeHandles = [mFreeHandles count];
    
    if (numFreeHandles != 0)
    {
        resourceNode->mHandle = [mFreeHandles objectAtIndex:(numFreeHandles - 1)];
        [resourceNode->mHandle retain];
        
        [mFreeHandles removeObjectAtIndex:(numFreeHandles - 1)];
    }
    else
    {
        resourceNode->mHandle = [[NSNumber alloc] initWithInt:mCurHandle];
        mCurHandle++;
        
        if (mCurHandle == 0)
        {
            NSAssert(false, @"Out of handle space.  Why do we have so many assets loaded?");
        }
    }
    
    [mResourceNodes addObject:resourceNode];
                
    [resourceNode release];
    
    return resourceNode;
}

-(void)UnloadAssetWithHandle:(NSNumber*)inHandle
{
    ResourceNode* resourceNode = [self FindResourceWithHandle:inHandle];
    NSAssert(resourceNode != NULL, @"Could not find resource\n");
    
    if (resourceNode != NULL)
    {
        resourceNode->mReferenceCount--;
        
        NSAssert(resourceNode->mReferenceCount >= 0, @"Reference count has dropped below zero.");
        
        if (resourceNode->mReferenceCount == 0)
        {
            // Store off the handle for future use, and remove the resource node's reference to it
            [mFreeHandles addObject:resourceNode->mHandle];
            
            // Get rid of the defunct resource node.  The resource is no longer loaded.
            [mResourceNodes removeObject:resourceNode];
        }
    }
}

-(ResourceNode*)FindResourceWithPath:(NSString*)inPath
{
    ResourceNode* retNode = NULL;
    
    int numResources = [mResourceNodes count];

    for (int i = 0; i < numResources; i++)
    {
        ResourceNode* curResource = [mResourceNodes objectAtIndex:i];
        
        if ([inPath compare:curResource->mPath] == NSOrderedSame)
        {
            retNode = curResource;
            break;
        }
    }

    return retNode;
}

-(ResourceNode*)FindResourceWithHandle:(NSNumber*)inHandle
{
    ResourceNode* retNode = NULL;
    
    int numResources = [mResourceNodes count];

    for (int i = 0; i < numResources; i++)
    {
        ResourceNode* curResource = [mResourceNodes objectAtIndex:i];
        
        if ([inHandle isEqualToValue:curResource->mHandle])
        {
            retNode = curResource;
            break;
        }
    }

    return retNode;
}

-(ResourceNode*)FindResourceWithName:(NSString*)inPath
{
    ResourceNode* retNode = NULL;
    
    int numResources = [mResourceNodes count];

    for (int i = 0; i < numResources; i++)
    {
        ResourceNode* curResource = [mResourceNodes objectAtIndex:i];
        
        if ([inPath compare:[curResource->mPath lastPathComponent]] == NSOrderedSame)
        {
            retNode = curResource;
            break;
        }
    }

    return retNode;
}

-(void)LoadData:(ResourceNode*)inResourceNode loadType:(LoadType)inLoadType
{
#if TARGET_OS_IPHONE
    NSMutableString* loadPath = [[[NSMutableString alloc] initWithString:mApplicationResourcePath] autorelease];
    
    [loadPath appendString:@"/Data/"];
    [loadPath appendString:(inResourceNode->mPath)];
#else
    NSString* loadPath = inResourceNode->mPath;
#endif
    
    switch(inLoadType)
    {
        case LOADTYPE_ALLOC:
        {
            inResourceNode->mData = [[[NSFileManager defaultManager] contentsAtPath:loadPath] retain];
            NSAssert(inResourceNode->mData != NULL, @"For some reason, the file could not be loaded");
            
            inResourceNode->mResourceType = RESOURCETYPE_STANDARD;
            break;
        }
                
        case LOADTYPE_STREAM:
        {
            inResourceNode->mData = NULL;
            inResourceNode->mResourceType = RESOURCETYPE_FILE_HANDLE;
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown load type");
            break;
        }
    }
    
    NSString* fileExtension = [inResourceNode->mPath pathExtension];

    [self CreateMetadataForNode:inResourceNode withExtension:fileExtension loadType:inLoadType];
}

-(NSData*)GetDataForHandle:(NSNumber*)inHandle
{
    NSData* retData = NULL;
    
    ResourceNode* resource = [self FindResourceWithHandle:inHandle];
    NSAssert(resource != NULL, @"Invalid resource handle was specified");
    
    if ((resource != NULL) && (resource->mResourceType == RESOURCETYPE_STANDARD))
    {
        retData = resource->mData;
    }
    
    return retData;
}

-(void)SetWorkingDirectory
{
    NSString* appPath = [[NSBundle mainBundle] bundlePath];
    NSString* dataPath = [appPath stringByAppendingPathComponent:@"Data"];
    
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:dataPath];

}

-(FileNode*)FindFileWithName:(NSString*)inName
{
    FileNode* retNode = NULL;
    
    int numFiles = [mFileNodes count];

    for (int i = 0; i < numFiles; i++)
    {
        FileNode* curFile = [mFileNodes objectAtIndex:i];
        
        if ([inName caseInsensitiveCompare:curFile->mAssetName] == NSOrderedSame)
        {
            retNode = curFile;
            break;
        }
    }

    return retNode;
}

-(NSMutableArray*)FileNodesWithPrefixPath:(NSString*)inPath
{
    while ([self GetState] != RESOURCE_MANAGER_STATE_READY)
    {
        [NSThread sleepForTimeInterval:0.1f];
    }

    NSMutableArray* retArray = [NSMutableArray arrayWithCapacity:0];
    NSRange pathRange = NSMakeRange(0, [inPath length]);
    
    for (FileNode* curNode in mFileNodes)
    {
        if ([curNode->mPath compare:inPath options:NSCaseInsensitiveSearch range:pathRange] == NSOrderedSame)
        {
            [retArray addObject:curNode];
        }
    }
    
    return retArray;
}

-(NSMutableArray*)FilesWithExtension:(NSString*)inExtension
{
    NSMutableArray* retArray = [[NSMutableArray alloc] initWithCapacity:0];
    [retArray autorelease];
    
    for (FileNode* curNode in mFileNodes)
    {
        NSString* path = curNode->mPath;
        
        if ([[path pathExtension] caseInsensitiveCompare:inExtension] == NSOrderedSame)
        {
            [retArray addObject:path];
        }
    }
    
    return retArray;
}

-(void)CreateMetadataForNode:(ResourceNode*)inResourceNode withExtension:(NSString*)inFileExtension loadType:(LoadType)inLoadType
{
    inResourceNode->mMetadata = NULL;
    
    if ([inFileExtension compare:@"fag"] == NSOrderedSame)
    {
        NSAssert(inLoadType == LOADTYPE_ALLOC, @"When loading a BigFile, the load type must be standard (preallocation) for now");
        inResourceNode->mMetadata = [[BigFile alloc] InitWithData:inResourceNode->mData];
        inResourceNode->mResourceType = RESOURCETYPE_BIGFILE;
    }
    
    if (inLoadType == LOADTYPE_STREAM)
    {
        inResourceNode->mMetadata = (void*)fopen([inResourceNode->mPath UTF8String], "r");
    }
}

-(BigFile*)GetBigFile:(NSNumber*)inHandle
{
    ResourceNode* node = [self FindResourceWithHandle:inHandle];
    BigFile* retVal = NULL;
    
    if ((node != NULL) && (node->mResourceType == RESOURCETYPE_BIGFILE))
    {
        retVal = (BigFile*)node->mMetadata;
    }
    
    return retVal;
}

-(Streamer*)GetStreamForHandle:(NSNumber*)inHandle
{    
    Streamer* retStreamer = NULL;
    
    ResourceNode* resource = [self FindResourceWithHandle:inHandle];
    NSAssert(resource != NULL, @"Invalid resource handle was specified");
    
    StreamerParams streamerParams;
    
    if (resource != NULL)
    {
        if (resource->mResourceType == RESOURCETYPE_FILE_HANDLE)
        {
            streamerParams.mType = STREAMER_TYPE_FILE;
            streamerParams.mFileHandle = (FILE*)resource->mMetadata;
        }
        else if (resource->mResourceType == RESOURCETYPE_STANDARD)
        {
            streamerParams.mType = STREAMER_TYPE_DATA;
            streamerParams.mData = (NSData*)resource->mData;
        }
        else
        {
            NSAssert(FALSE, @"Resource not found, or was the wrong type");
        }
        
        retStreamer = [(Streamer*)[Streamer alloc] InitWithParams:&streamerParams];
        [retStreamer autorelease];
    }
    else
    {
        NSAssert(FALSE, @"Resource not found");
    }
    
    return retStreamer;
}

-(ResourceFamily)GetResourceFamily:(NSNumber*)inHandle
{
    ResourceNode* resource = [self FindResourceWithHandle:inHandle];
    NSAssert(resource != NULL, @"Invalid resource handle was specified");
    
    return resource->mResourceFamily;
}

-(void)SetState:(ResourceManagerState)inState
{
    [mLock lock];
    mState = inState;
    [mLock unlock];
}

-(ResourceManagerState)GetState
{
    [mLock lock];
    ResourceManagerState retState = mState;;
    [mLock unlock];
    
    return retState;
}

@end