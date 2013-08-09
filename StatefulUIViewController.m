//
//  StateViewController.m
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import "StatefulUIViewController.h"

#define tDidInitViewState 11
#define tDidLoadViewState 12
#define tWillAppearViewState 13
#define tDidAppearViewState 14
#define tWillDisappearViewState 15
#define tDidDisappearViewState 16
#define tWillUnloadViewState 17
#define tDidUnloadViewState 18

@interface StatefulUIViewController ()

// state related

@property int currentState;
@property int initState;

@property int currentControllerViewState;
@property int currentProcessedViewState;

@property NSMutableDictionary *states;

// view queue related

@property NSMutableDictionary *viewOnce;
@property NSMutableDictionary *viewForever;

@end

@implementation StatefulUIViewController

-(id)init
{
    self = [super init];
    if (self) {
        self.currentState = nil;
        self.initState = nil;
        
        self.currentControllerViewState = tDidInitViewState;
        self.currentProcessedViewState = tDidInitViewState;
        self.states = [NSMutableDictionary dictionary];
        
        self.viewOnce = [NSMutableDictionary dictionary];
        self.viewForever = [NSMutableDictionary dictionary];        
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.currentControllerViewState = tDidLoadViewState;
    [self processStateOnViewDidLoad];    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.currentControllerViewState = tWillAppearViewState;
    [self processStateOnViewWillAppear];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.currentControllerViewState = tDidAppearViewState;
    [self processStateOnViewDidAppear];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.currentControllerViewState = tWillDisappearViewState;
    [self processStateOnViewWillDisappear];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];    
    self.currentControllerViewState = tDidDisappearViewState;
    [self processStateOnViewDidDisappear];
}

-(void)viewWillUnload
{
    [super viewWillUnload];
    self.currentControllerViewState = tWillUnloadViewState;
    [self processStateOnViewWillUnload];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
    self.currentControllerViewState = tDidUnloadViewState;
    [self processStateOnViewDidUnload];
}

// state stuff

-(State*)configureState:(int)state
{
    if (!state)
        [NSException raise:NSInvalidArgumentException format:@"State identifier must be provided!"];

    if (![self.states objectForKey:[NSNumber numberWithInt:state]]) {
        [self.states addEntriesFromDictionary:[NSDictionary 
            dictionaryWithObject:[[State alloc] initWithName:state] forKey:[NSNumber numberWithInt:state]]];
    }
    return [self.states objectForKey:[NSNumber numberWithInt:state]];
}

-(void)setInitialState:(int)state
{
    if (!state || ![self.states objectForKey:[NSNumber numberWithInt:state]])
        [NSException raise:NSInvalidArgumentException format:@"State not registered!"]; 
    self.initState = state;
}

-(void)toInitialState
{
    [self toState:self.initState];
}

-(void)toState:(int)state
{
    if (!state || ![self.states objectForKey:[NSNumber numberWithInt:state]])
        [NSException raise:NSInvalidArgumentException format:@"State not configured!"];    
    self.currentState = state;
    self.currentProcessedViewState = tDidInitViewState;
    [self processStateOnInit];
}

// view queue

-(void)onViewState:(int)state doOnce:(ViewCallback)callback
{
    if (![self.viewOnce objectForKey:[NSNumber numberWithInt:state]])
        [self.viewOnce addEntriesFromDictionary:[NSDictionary 
            dictionaryWithObject:[NSMutableArray 
                arrayWithObject:callback] forKey:[NSNumber numberWithInt:state]]];
    else
        [[self.viewOnce objectForKey:[NSNumber numberWithInt:state]] addObject:callback];
    [self processStateOnInit];
}

-(void)onViewState:(int)state when:(BOOL)when doOnce:(ViewCallback)callback
{
    if (when)
        [self onViewState:state doOnce:callback];
}

-(void)onViewState:(int)state doForever:(ViewCallback)callback
{
    if (![self.viewForever objectForKey:[NSNumber numberWithInt:state]])
        [self.viewForever addEntriesFromDictionary:[NSDictionary 
            dictionaryWithObject:[NSMutableArray 
                arrayWithObject:callback] forKey:[NSNumber numberWithInt:state]]];
    else
        [[self.viewForever objectForKey:[NSNumber numberWithInt:state]] addObject:callback];
    [self processStateOnInit];
}

-(void)onViewState:(int)state when:(BOOL)when doForever:(ViewCallback)callback
{
    if (when)
        [self onViewState:state doForever:callback];
}

-(void)processViewStates:(int)state
{
    if ([self.viewForever objectForKey:[NSNumber numberWithInt:state]]) {
        [[self.viewForever objectForKey:[NSNumber numberWithInt:state]] 
            enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            ((ViewCallback)object)();
        }];
    }
    
    if ([self.viewOnce objectForKey:[NSNumber numberWithInt:state]]) {
        [[self.viewOnce objectForKey:[NSNumber numberWithInt:state]] 
            enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            ((ViewCallback)object)();
        }];
        [[self.viewOnce objectForKey:[NSNumber numberWithInt:state]] removeAllObjects];
    }
}

-(void)removeAllOnces:(int)state
{
    if ([self.viewOnce objectForKey:[NSNumber numberWithInt:state]])
        [[self.viewOnce objectForKey:[NSNumber numberWithInt:state]] removeAllObjects];
}

-(void)removeAllForevers:(int)state
{
    if ([self.viewForever objectForKey:[NSNumber numberWithInt:state]])
        [[self.viewForever objectForKey:[NSNumber numberWithInt:state]] removeAllObjects];
}

// some general stuff

-(void)processStateOnInit
{
    [(State*)[self.states objectForKey:[NSNumber 
        numberWithInt:self.currentState]] processState:tDidInitViewState];
    [self processViews:tDidInitViewState];
    [self processStateOnViewDidLoad];
}

-(void)processStateOnViewDidLoad
{
    if (tDidLoadViewState <= self.currentViewControllerState && 
        self.currentViewControllerState <= tDidAppearViewState) {
        if (self.currentProcessedState < tDidLoadViewState) {
            self.currentProcessedState = tDidLoadViewState;
            [(State*)[self.states objectForKey:[NSNumber 
                numberWithInt:self.currentState]] processState:tDidLoadViewState];
        }
        [self processViews:tDidLoadViewState];
        [self processStateOnViewWillAppear];
    }
}

-(void)processStateOnViewWillAppear
{
    if (tWillAppearViewState <= self.currentViewControllerState && 
        self.currentViewControllerState <= tDidAppearViewState) {
        if (self.currentProcessedState < tWillAppearViewState) {
            self.currentProcessedState = tWillAppearViewState;
            [(State*)[self.states objectForKey:[NSNumber 
                numberWithInt:self.currentState]] processState:tWillAppearViewState];
        }
        [self processViews:tWillAppearViewState];
        [self processStateOnViewDidAppear];
    }
}

-(void)processStateOnViewDidAppear
{
    if (tDidAppearViewState <= self.currentViewControllerState && 
        self.currentViewControllerState <= tDidAppearViewState) {
        if (self.currentProcessedState < tDidAppearViewState) {
            self.currentProcessedState = tDidAppearViewState;
            [(State*)[self.states objectForKey:[NSNumber 
                numberWithInt:self.currentState]] processState:tDidAppearViewState];
        }
        [self processViews:tDidAppearViewState];
    }
}

// - (void)processStateOnViewWillDisappear
// {
//     if (tViewWillDisappearState <= self.currentViewControllerState) {
//         if (self.currentProcessedState < tViewWillDisappearState) {
//             self.currentProcessedState = tViewWillDisappearState;
//         }
//     }
// }

// - (void)processStateOnViewDidDisappear
// {
//     if (tViewDidDisappearState <= self.currentViewControllerState) {
//         if (!(self.currentProcessedState < tViewDidDisappearState)) {
//             self.currentProcessedState = tViewDidDisappearState;
//         }
//     }
// }

// - (void)processStateOnViewWillUnload
// {
//     if (tViewWillUnloadState <= self.currentViewControllerState) {
//         if (self.currentProcessedState < tViewWillUnloadState) {
//             self.currentProcessedState = tViewWillUnloadState;
//         }
//     }
// }

// - (void)processStateOnViewDidUnload
// {
//     if (tViewDidUnloadState <= self.currentViewControllerState) {
//         if (self.currentProcessedState < tViewDidUnloadState) {
//             self.currentProcessedState = tViewDidUnloadState;
//         }
//     }
// }

@end
