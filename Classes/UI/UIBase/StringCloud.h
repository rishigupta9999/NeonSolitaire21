//
//  StringCloud.h
//  Neon21
//
//  Copyright Neon Games 2014. All rights reserved.

#import "UIObject.h"
#import "TextBox.h"

@interface StringCloudParams : NSObject
{
    @public
        UIGroup*        mUIGroup;
        NSMutableArray* mStrings;
    
        float           mFontSize;
        NeonFontType    mFontType;
}

-(StringCloudParams*)init;
-(void)dealloc;

@end

@interface StringCloud : UIObject
{
    NSMutableArray* mStringCloudEntries;
    float           mScaleFactor;
}

-(StringCloud*)initWithParams:(StringCloudParams*)inParams;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;

@end