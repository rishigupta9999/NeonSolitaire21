//
//  ResourceManager.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

typedef enum
{
    LOADTYPE_ALLOC,
    LOADTYPE_STREAM,
    LOADTYPE_MMAP
} LoadType;

typedef enum
{
    RESOURCETYPE_STANDARD,
    RESOURCETYPE_BIGFILE,
    RESOURCETYPE_FILE_HANDLE,
    RESOURCETYPE_INVALID
} ResourceType;

typedef struct
{
    BOOL    mOptional;		// If the asset load is optional, we'll silently fail, returning NULL.  If it's required, we'll assert / crash.
	BOOL	mAttemptRetina;	// Attempt to load a retina display version of the asset (prefixed with x2_)
} ResourceLoadParams;

@class BigFile;
@class Streamer;

typedef enum
{
    RESOURCEFAMILY_PHONE,
    RESOURCEFAMILY_PHONE_RETINA,
    RESOURCEFAMILY_PAD_RETINA
} ResourceFamily;

@interface ResourceNode : NSObject
{
    @public
        NSString*       mPath;
        int             mReferenceCount;
        NSNumber*       mHandle;
        ResourceType    mResourceType;
        
        NSData*         mData;
        void*           mMetadata;
		
		ResourceFamily  mResourceFamily;
};

-(void)Reset;
@end

@interface FileNode : NSObject
{
    @public
        NSString*   mAssetName;
        NSString*   mPath;
}

@end

typedef enum
{
    RESOURCE_MANAGER_STATE_INITIALIZING,
    RESOURCE_MANAGER_STATE_READY
} ResourceManagerState;

@interface ResourceManager : NSObject
{
    @private
        NSMutableArray*     mFileNodes;
        NSMutableArray*     mResourceNodes;
        NSMutableArray*     mFreeHandles;
    
        NSString*           mApplicationResourcePath;
        
        int                 mCurHandle;
    
        dispatch_queue_t        mOperationQueue;
        ResourceManagerState    mState;
        NSLock*                 mLock;
}

// Class methods that manage creation and access
+(void)CreateInstance;
+(void)DestroyInstance;
+(ResourceManager*)GetInstance;

// Initialization and Shutdown.  Must be called explicitly once.
-(void)Init;
-(void)Term;

// Parameter initialization
+(void)InitDefaultParams:(ResourceLoadParams*)outParams;

// Asset loading functions, these are safe - use these freely.
-(NSNumber*)LoadAssetWithPath:(NSString*)inPath;
-(NSNumber*)StreamAssetWithPath:(NSString*)inPath;

-(NSNumber*)LoadAssetWithName:(NSString*)inName;
-(NSNumber*)LoadAssetWithName:(NSString*)inName params:(ResourceLoadParams*)inParams;
-(NSNumber*)StreamAssetWithName:(NSString*)inName;
-(NSNumber*)StreamAssetWithName:(NSString*)inName params:(ResourceLoadParams*)inParams;

-(NSNumber*)LoadMappedAssetWithName:(NSString*)inName;
-(NSString*)FindAssetWithName:(NSString*)inName;
-(void)UnloadAssetWithHandle:(NSNumber*)inHandle;

// Access to data
-(NSData*)GetDataForHandle:(NSNumber*)inHandle;
-(BigFile*)GetBigFile:(NSNumber*)inHandle;
-(Streamer*)GetStreamForHandle:(NSNumber*)inHandle;
-(ResourceFamily)GetResourceFamily:(NSNumber*)inHandle;

// General resource information
-(NSMutableArray*)FilesWithExtension:(NSString*)inExtension;

// You should not need to call these, but they are there and should be relatively safe.
-(NSNumber*)InternalLoadAssetWithPath:(NSString*)inPath loadType:(LoadType)inLoadType;
-(NSNumber*)InternalLoadAssetWithName:(NSString*)inName loadType:(LoadType)inLoadType params:(ResourceLoadParams*)inParams;
-(ResourceNode*)FindResourceWithPath:(NSString*)inPath;
-(ResourceNode*)FindResourceWithHandle:(NSNumber*)inHandle;
-(ResourceNode*)FindResourceWithName:(NSString*)inName;
-(FileNode*)FindFileWithName:(NSString*)inName;

-(NSMutableArray*)FileNodesWithPrefixPath:(NSString*)inPath;

// Internally used functions.  Don't call these externally, can be dangerous.

-(ResourceNode*)CreateResourceNodeWithPath:(NSString*)inPath;
-(void)CreateMetadataForNode:(ResourceNode*)inResourceNode withExtension:(NSString*)inFileExtension loadType:(LoadType)inLoadType;

-(void)LoadData:(ResourceNode*)inResourceNode loadType:(LoadType)inLoadType;

-(void)SetWorkingDirectory;
-(void)GenerateFileNodes;

-(void)SetState:(ResourceManagerState)inState;
-(ResourceManagerState)GetState;

@end