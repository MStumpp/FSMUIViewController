//
//  State.h
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import <Foundation/Foundation.h>

@class State;

// states

#define tDefaultState @"defaultState"
#define tAllState @"allState"

// view states

#define tNoneViewState 1
#define tDidInitViewState 2
#define tDidLoadViewState 3
#define tWillAppearViewState 4
#define tDidAppearViewState 5
#define tWillDisappearViewState 6
#define tDidDisappearViewState 7

// transition modes

#define tIn 1
#define tOut 2
#define tInOut 3

typedef void(^ViewCallback)(State *this, State *other);
typedef void(^ForwardResponseCallback)(State *to, BOOL block, BOOL skip);
typedef void(^ForwardCallback)(State *this, State *from, ForwardResponseCallback callback);

@interface State : NSObject
@property NSString *name;
@property NSMutableDictionary *transitionIn;
@property NSMutableDictionary *transitionOut;
@property id data;
-(id)initWithName:(NSString*)name;

// public API

-(State*)onViewState:(int)viewState do:(ViewCallback)callback;
-(State*)onViewState:(int)viewState mode:(int)mode do:(ViewCallback)callback;

// state forwarding
-(State*)forwardToState:(ForwardCallback)callback;
-(void)processForwardFromState:(State*)from andCallback:(ForwardResponseCallback)callback;

// private API

-(void)addTransitionInViewState:(int)viewState do:(ViewCallback)callback;
-(void)addTransitionOutViewState:(int)viewState do:(ViewCallback)callback;

-(BOOL)processStateIn:(int)viewState fromState:(State*)from;
-(BOOL)processStateOut:(int)viewState toState:(State*)to;

// has view state after view state

-(BOOL)hasViewStateAfterViewState:(int)viewState;

// merging
-(void)mergeState:(State*)state;
@end
