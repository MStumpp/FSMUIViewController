//
//  StateViewController.m
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import "FSMUIViewController.h"

@interface FSMUIViewController ()
@property NSString *previousState;
@property NSString *currentState;
@property NSString *defaultState;
@property int currentControllerViewState;
@property int currentProcessedViewState;
@property NSMutableDictionary *states;
@end

@implementation FSMUIViewController

-(id)init
{
    self = [super init];
    if (self) {
        self.previousState = nil;
        self.currentState = nil;
        self.defaultState = tDefaultState;
        
        self.currentControllerViewState = tDidInitViewState;
        self.currentProcessedViewState = self.currentControllerViewState;
        self.states = [NSMutableDictionary dictionary];

        // set up default state
        [self.states setObject:[[State alloc] initWithName:self.defaultState] forKey:self.defaultState];
    }
    return self;
}

// state configuration

-(State*)configureState:(NSString*)state
{
    if (!states) {
        NSLog(@"state must be provided");
        return NULL;    
    }

    if (![self.states objectForKey:state])
        [self.states setObject:[[State alloc] initWithName:state] forKey:state];

    return [self.states objectForKey:state];
}

-(State*)configureDefaultState
{
    return [self configureState:self.defaultState];
}

-(StateSet*)configureStates:(NSArray*)states
{
    if (!states) {
        NSLog(@"state must be provided");
        return NULL;    
    }

    NSMutableArray *array = [[NSMutableArray alloc] init];
    [self.states enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
        if ([states containsObject:key])
            [array addObject:obj];
    }]; 

    return [[StateSet alloc] initWithStates:array];         
}

-(StateSet*)configureAllStates
{
   return [self configureStates:[self.states allKeys]]; 
}

-(BOOL)setDefaultState:(NSString*)state
{
    if (!states) {
        NSLog(@"state must be provided");
        return FALSE;    
    }

    if ([self.defaultState isEqualToString:state]) {
        NSLog(@"current default state is equal to rquested state");
        return FALSE;   
    }

    State *tmp = [self.states objectForKey:self.defaultState];
    [self.states removeObjectForKey:self.defaultState];
    [self.states setObject:tmp forKey:state];
    self.defaultState = state;
    return TRUE;
}

// state transition

-(BOOL)toDefaultState
{
    return [self toState:self.defaultState];
}

-(BOOL)toState:(NSString*)state
{
    if (!state || ![self.states objectForKey:state]) {
        NSLog(@"state doesn't exists");
        return FALSE;
    }
        
    if (![self.currentState isEqualToString:state])
        return [self toStateForce:state];

    NSLog(@"already in requested state");
    return FALSE;      
}

-(BOOL)toDefaultStateForce
{
    return [self toStateForce:self.defaultState];
}

-(BOOL)toStateForce:(NSString*)state
{
    if (!state || ![self.states objectForKey:state]) {
        NSLog(@"state doesn't exists");
        return FALSE;  
    }

    if (![self transitionFrom:self.currentState to:state]) {
        NSLog(@"state transition not allowed");
        return FALSE;
    }

    self.previousState = self.currentState;   
    self.currentState = state; 

    [self processStateOnInit];
    return TRUE;
}

// may be overwritten in sub class

-(BOOL)transitionFrom:(State*)from to:(State*)to
{
    return TRUE;
}

// internal processing of state transisions

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

-(void)processStateOnInit
{
    self.currentProcessedViewState = tDidInitViewState;
    if (self.previousState)
        [(State*)[self.states objectForKey:self.previousState] processStateOut:self.currentProcessedViewState];
    [(State*)[self.states objectForKey:self.currentState] processStateIn:self.currentProcessedViewState];
    [self processStateOnViewDidLoad];
}

-(void)processStateOnViewDidLoad
{
    if (tDidLoadViewState <= self.currentControllerViewState &&
        self.currentControllerViewState <= tDidAppearViewState) {
        if (self.currentProcessedViewState < tDidLoadViewState) {
            self.currentProcessedViewState = tDidLoadViewState;
            if (self.previousState)
                [(State*)[self.states objectForKey:self.previousState] processStateOut:self.currentProcessedViewState];
            [(State*)[self.states objectForKey:self.currentState] processStateIn:self.currentProcessedViewState];
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
            if (self.previousState)
                [(State*)[self.states objectForKey:self.previousState] processStateOut:self.currentProcessedViewState];
            [(State*)[self.states objectForKey:self.currentState] processStateIn:self.currentProcessedViewState];
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
            if (self.previousState)
                [(State*)[self.states objectForKey:self.previousState] processStateOut:self.currentProcessedViewState]; 
            [(State*)[self.states objectForKey:self.currentState] processStateIn:self.currentProcessedViewState];
        }
    }
}

// not yet supported

-(void)processStateOnViewWillDisappear
{
     if (tWillDisappearViewState <= self.currentControllerViewState) {
         if (self.currentProcessedViewState < tWillDisappearViewState) {
             self.currentProcessedViewState = tWillDisappearViewState;
         }
     }
}

-(void)processStateOnViewDidDisappear
{
     if (tDidDisappearViewState <= self.currentControllerViewState) {
         if (!(self.currentProcessedViewState < tDidDisappearViewState)) {
             self.currentProcessedViewState = tDidDisappearViewState;
         }
     }
}

-(void)processStateOnViewWillUnload
{
     if (tWillUnloadViewState <= self.currentControllerViewState) {
         if (self.currentProcessedViewState < tWillUnloadViewState) {
             self.currentProcessedViewState = tWillUnloadViewState;
         }
     }
}

-(void)processStateOnViewDidUnload
{
     if (tDidUnloadViewState <= self.currentControllerViewState) {
         if (self.currentProcessedViewState < tDidUnloadViewState) {
             self.currentProcessedViewState = tDidUnloadViewState;
         }
     }
}

@end
