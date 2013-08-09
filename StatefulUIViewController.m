//
//  StateViewController.m
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import "StatefulUIViewController.h"

#define tDefaultState 10

@interface StatefulUIViewController ()

// state related

@property int currentState;
@property int defaultState;

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
        self.defaultState = tDefaultState;
        
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

-(State*)configureDefaultState
{
    return [self configureState:self.defaultState];
}

-(void)toState:(int)state
{
    if (!state || ![self.states objectForKey:[NSNumber numberWithInt:state]])
        [NSException raise:NSInvalidArgumentException format:@"State not configured!"];    
    self.currentState = state;
    self.currentProcessedViewState = tDidInitViewState;
    [self processStateOnInit];
}

-(void)toDefaultState
{
    [self toState:self.defaultState];
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
    [self processViewStates:tDidInitViewState];
    [self processStateOnViewDidLoad];
}

-(void)processStateOnViewDidLoad
{
    if (tDidLoadViewState <= self.currentControllerViewState &&
        self.currentControllerViewState <= tDidAppearViewState) {
        if (self.currentProcessedViewState < tDidLoadViewState) {
            self.currentProcessedViewState = tDidLoadViewState;
            [(State*)[self.states objectForKey:[NSNumber 
                numberWithInt:self.currentState]] processState:tDidLoadViewState];
        }
        [self processViewStates:tDidLoadViewState];
        [self processStateOnViewWillAppear];
    }
}

-(void)processStateOnViewWillAppear
{
    if (tWillAppearViewState <= self.currentControllerViewState &&
        self.currentControllerViewState <= tDidAppearViewState) {
        if (self.currentProcessedViewState < tWillAppearViewState) {
            self.currentProcessedViewState = tWillAppearViewState;
            [(State*)[self.states objectForKey:[NSNumber 
                numberWithInt:self.currentState]] processState:tWillAppearViewState];
        }
        [self processViewStates:tWillAppearViewState];
        [self processStateOnViewDidAppear];
    }
}

-(void)processStateOnViewDidAppear
{
    if (tDidAppearViewState <= self.currentControllerViewState &&
        self.currentControllerViewState <= tDidAppearViewState) {
        if (self.currentProcessedViewState < tDidAppearViewState) {
            self.currentProcessedViewState = tDidAppearViewState;
            [(State*)[self.states objectForKey:[NSNumber 
                numberWithInt:self.currentState]] processState:tDidAppearViewState];
        }
        [self processViewStates:tDidAppearViewState];
    }
}

- (void)processStateOnViewWillDisappear
{
     if (tWillDisappearViewState <= self.currentControllerViewState) {
         if (self.currentProcessedViewState < tWillDisappearViewState) {
             self.currentProcessedViewState = tWillDisappearViewState;
         }
     }
}

- (void)processStateOnViewDidDisappear
{
     if (tDidDisappearViewState <= self.currentControllerViewState) {
         if (!(self.currentProcessedViewState < tDidDisappearViewState)) {
             self.currentProcessedViewState = tDidDisappearViewState;
         }
     }
}

- (void)processStateOnViewWillUnload
{
     if (tWillUnloadViewState <= self.currentControllerViewState) {
         if (self.currentProcessedViewState < tWillUnloadViewState) {
             self.currentProcessedViewState = tWillUnloadViewState;
         }
     }
}

- (void)processStateOnViewDidUnload
{
     if (tDidUnloadViewState <= self.currentControllerViewState) {
         if (self.currentProcessedViewState < tDidUnloadViewState) {
             self.currentProcessedViewState = tDidUnloadViewState;
         }
     }
}

@end
