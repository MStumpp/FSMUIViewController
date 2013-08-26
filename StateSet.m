//
//  State.m
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import "StateSet.h"

@interface StateSet()
@property NSArray *states;
@end

@implementation StateSet

-(id)initWithStates:(NSArray*)states
{
    self = [super init];
    if (self) {
        self.states = states;
    }
    return self;
}

-(StateSet*)onViewState:(int)viewState do:(ViewCallback)callback
{
    return [self onViewState:viewState mode:tIn do:callback];
}

-(StateSet*)onViewState:(int)viewState mode:(int)mode do:(ViewCallback)callback
{
    [self.states enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        if (mode == tIn || mode == tInOut)
            [object addTransitionInViewState:viewState do:callback];

        if (mode == tOut || mode == tInOut)
            [object addTransitionOutViewState:viewState do:callback];
    }];
    return self;
}

@end
