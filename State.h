//
//  State.h
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import <Foundation/Foundation.h>

// states

#define tDefaultState @"defaultState"

// view states

#define tDidInitViewState 11
#define tDidLoadViewState 12
#define tWillAppearViewState 13
#define tDidAppearViewState 14
#define tWillDisappearViewState 15
#define tDidDisappearViewState 16
#define tWillUnloadViewState 17
#define tDidUnloadViewState 18

// transition modes

#define tIn 1;
#define tOut 2;
#define tInOut 3;

typedef void(^ViewCallback)();

@interface State : NSObject
@property NSString *name;
-(id)initWithName:(NSString*)name;

-(State*)onViewState:(int)viewState do:(ViewCallback)callback;
-(State*)onViewState:(int)viewState mode:(int)mode do:(ViewCallback)callback;

-(void)addTransitionInViewState:(int)viewState do:(ViewCallback)callback;
-(void)addTransitionOutViewState:(int)viewState do:(ViewCallback)callback;

-(BOOL)processStateIn:(int)viewState;
-(BOOL)processStateOut:(int)viewState;
@end
