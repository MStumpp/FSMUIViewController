//
//  State.m
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import "State.h"

@interface State()
@property id forwardCallback;
@end

@implementation State

-(id)initWithName:(NSString*)name
{
    self = [self init];
    if (self) {
        self.name = name;
        self.transitionIn = [NSMutableDictionary dictionary];
        self.transitionOut = [NSMutableDictionary dictionary];
    }
    return self;
}

-(State*)onViewState:(int)viewState do:(ViewCallback)callback
{
    return [self onViewState:viewState mode:tIn do:callback];
}

-(State*)onViewState:(int)viewState mode:(int)mode do:(ViewCallback)callback
{
    if (mode == tIn || mode == tInOut) {
        [self addTransitionInViewState:viewState do:callback];
    }

    if (mode == tOut || mode == tInOut) {
        [self addTransitionOutViewState:viewState do:callback];
    }

    return self;
}

// state forwarding

-(State*)forwardToState:(ForwardCallback)callback
{
    if (callback)
        self.forwardCallback = callback;
    return self;
}

-(void)processForwardFromState:(State*)from andCallback:(ForwardResponseCallback)callback
{
    if (!callback)
        return;

    if (self.forwardCallback) {
        ((ForwardCallback)self.forwardCallback)(self, from, callback);
    } else {
        callback(nil, TRUE, FALSE);
    }
}

-(void)addTransitionInViewState:(int)viewState do:(ViewCallback)callback
{
    if (![self.transitionIn objectForKey:[NSNumber numberWithInteger:viewState]]) {
        [self.transitionIn setObject:[NSMutableArray arrayWithObject:callback] forKey:[NSNumber numberWithInteger:viewState]];
    } else {
        [[self.transitionIn objectForKey:[NSNumber numberWithInteger:viewState]] addObject:callback];
    }
}

-(void)addTransitionOutViewState:(int)viewState do:(ViewCallback)callback
{
    if (![self.transitionOut objectForKey:[NSNumber numberWithInteger:viewState]]) {
        [self.transitionOut setObject:[NSMutableArray arrayWithObject:callback] forKey:[NSNumber numberWithInteger:viewState]];
    } else {
        [[self.transitionOut objectForKey:[NSNumber numberWithInteger:viewState]] addObject:callback];
    }
}

-(BOOL)processStateIn:(int)viewState fromState:(State*)from
{
    // process own callbacks first
    if ([self.transitionIn objectForKey:[NSNumber numberWithInteger:viewState]]) {
        [[self.transitionIn objectForKey:[NSNumber numberWithInteger:viewState]] enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            ((ViewCallback)object)(self, from);
        }];
    }
    return TRUE;
}

-(BOOL)processStateOut:(int)viewState toState:(State*)to
{
    // process own callbacks first
    if ([self.transitionOut objectForKey:[NSNumber numberWithInteger:viewState]]) {
        [[self.transitionOut objectForKey:[NSNumber numberWithInteger:viewState]] enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            ((ViewCallback)object)(self, to);
        }];
    }
    return TRUE;
}

// has view state after view state

-(BOOL)hasViewStateAfterViewState:(int)viewState
{
    __block BOOL found = FALSE;
    
    [self.transitionIn enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([(NSNumber*)key intValue] > viewState) {
            found = TRUE;
            stop = TRUE;
        }
    }];
    
    if (found) return TRUE;
    
    [self.transitionOut enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([(NSNumber*)key intValue] > viewState) {
            found = TRUE;
            stop = TRUE;
        }
    }];
    
    return found;
}

// merging

-(void)mergeState:(State*)state
{
    [self.transitionIn enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj && [obj isKindOfClass:[NSArray class]]) {
            [obj enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
                [self onViewState:[(NSNumber*)key intValue] mode:tIn do:object];
            }];
        }
    }];

    [[state transitionOut] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj && [obj isKindOfClass:[NSArray class]]) {
            [obj enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
                [self onViewState:[(NSNumber*)key intValue] mode:tOut do:object];
            }];
        }
    }];
}

@end
