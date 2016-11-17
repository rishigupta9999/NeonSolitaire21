//
//  Neon21AppDelegate.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import <UIKit/UIKit.h>


extern UIView* gAppView;

@class EAGLView;
@class MessageChannel;

@interface Neon21AssertionHandler : NSAssertionHandler
{
}

- (void)handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format,...;
- (void)handleFailureInFunction:(NSString *)functionName file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format,...;

@end

@class NeonVungleDelegate;
@class NeonChartboostDelegate;

@interface Neon21AppDelegate : NSObject <UIApplicationDelegate>
{	
    @public
        MessageChannel*     mGlobalMessageChannel;

    @protected
        IBOutlet UIWindow*  window;
        IBOutlet EAGLView*  glView;
    
        UIViewController*   mViewController;
        
        NSTimer *mAnimationTimer;
        NSTimeInterval mAnimationInterval;

        CFAbsoluteTime mLastFrameTime;
        CFAbsoluteTime mTimeStep;
        
        BOOL    mUsingDisplayLink;
        id      mDisplayLink;
            
        u32     mFrameNumber;
        
        BOOL    mSuspended;
    
        NeonChartboostDelegate*  mChartboostDelegate;
}

-(void)Init;
-(void)GameLoop;
-(int)GetFrameNumber;

-(void)applicationWillTerminate:(UIApplication *)application;
-(void)applicationWillResignActive:(UIApplication *)application;
-(void)applicationDidBecomeActive:(UIApplication *)application;
-(void)applicationWillEnterForeground:(UIApplication *)application;

-(void)applicationDidEnterBackground:(UIApplication *)application;

-(UIViewController*)GetViewController;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) EAGLView *glView;

@end



