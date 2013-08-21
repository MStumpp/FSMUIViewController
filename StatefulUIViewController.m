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

@property int currentState;
@property int defaultState;

@property int currentControllerViewState;
@property int currentProcessedViewState;

@property NSMutableDictionary *states;

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

-(void)toStateForce:(int)state
{
    if (!state || ![self.states objectForKey:[NSNumber numberWithInt:state]])
        [NSException raise:NSInvalidArgumentException format:@"State not configured!"];    
    self.currentState = state;
    self.currentProcessedViewState = tDidInitViewState;
    [self processStateOnInit];
}

-(void)toDefaultStateForce
{
    [self toStateForce:self.defaultState];
}

// some general stuff

-(void)processStateOnInit
{
    [(State*)[self.states objectForKey:[NSNumber 
        numberWithInt:self.currentState]] processState:tDidInitViewState];
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
