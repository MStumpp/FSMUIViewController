//
//  StateViewController.m
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import "FSMUIViewController.h"
#import "StateQueueWrapper.h"

@interface FSMUIViewController ()
@property (atomic) State *previousState;
@property (atomic) State *currState;
@property (atomic) NSMutableArray *nextStates;
@property (atomic) BOOL blockCurrentState;
@property (atomic) NSString *defState;
@property (atomic) NSString *allState;
@property (atomic) int currentControllerViewState;
@property (atomic) int currentProcessedViewState;
@property (atomic) NSMutableDictionary *states;
@property (atomic) NSMutableDictionary *all;
@end

@implementation FSMUIViewController
@synthesize nextStates;

-(id)init
{
    self = [super init];
    if (self) {
        self.previousState = nil;
        self.currState = nil;
        self.nextStates = [NSMutableArray array];
        [self addObserver:self forKeyPath:@"nextStates" options:NSKeyValueObservingOptionNew context:nil];
        self.blockCurrentState = TRUE;
        
        self.defState = tDefaultState;
        self.allState = tAllState;

        self.currentControllerViewState = tDidInitViewState;
        self.currentProcessedViewState = tNoneViewState;
        self.states = [NSMutableDictionary dictionary];
        self.all = [NSMutableDictionary dictionary];
        
        // set up default state
        [self.states setObject:[[State alloc] initWithName:self.defState] forKey:self.defState];
        // set up state representing all states
        [self.states setObject:[[State alloc] initWithName:self.allState] forKey:self.allState];
    }
    return self;
}

// state configuration

-(State*)configureState:(NSString*)state
{
    if (!state) {
        NSLog(@"state must be provided");
        return NULL;    
    }

    return [self getOrNewState:state];
}

-(State*)configureDefaultState
{
    return [self configureState:self.defState];
}

-(StateSet*)configureStates:(NSArray*)states
{
    if (!states) {
        NSLog(@"state must be provided");
        return NULL;    
    }

    NSMutableArray *array = [[NSMutableArray alloc] init];
    [states enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        [array addObject:[self getOrNewState:object]];
    }]; 

    return [[StateSet alloc] initWithStates:array];         
}

-(State*)configureAllStates
{
   return [self configureState:self.allState];
}

-(void)setDefaultState:(NSString*)state
{
    if (!state) {
        NSLog(@"state must be provided");
    }

    if ([self.defState isEqualToString:state]) {
        NSLog(@"current default state is equal to requested state");
    }

    State *tmp = [self.states objectForKey:self.defState];
    [tmp setName:state];

    // merge callbacks from state to be requested as default state
    // into current default state object
    State *oldState = [self.states objectForKey:state];
    if (oldState) {
        // merge viw callbacks in
        [tmp mergeState:oldState];
        // remove object which has been eventually merged
        [self.states removeObjectForKey:oldState.name];
    }

    // if current state is default state, process callback until view state
    if (self.currState && [self.currState.name isEqualToString:self.defState]) {
        self.currState = tmp;
        [self processOnInitForPrev:nil andCurrent:self.currState];
    }

    // further process default state
    [self.states removeObjectForKey:self.defState];
    [self.states setObject:tmp forKey:state];
    self.defState = state;
}

// state transition

-(BOOL)toDefaultState
{
    return [self toState:self.defState];
}

-(BOOL)toState:(NSString*)state
{
    //NSLog(@"toState %@", state);
    
    if (!state) {
        NSLog(@"state must not be nil");
        return FALSE;
    }

    State *tmp = [self getOrNewState:state];
    
    State *refState = self.currState;
    if ([self.nextStates count] > 0)
        refState = [(StateQueueWrapper*)[self.nextStates lastObject] state];
    
    if (refState && [refState.name isEqualToString:tmp.name]) {
        NSLog(@"already in requested state");
        return FALSE;
    }

    return [self toStateForce:state];
}

-(BOOL)toDefaultStateForce
{
    return [self toStateForce:self.defState];
}

-(BOOL)toStateForce:(NSString*)state
{
    //NSLog(@"toStateForce %@", state);
    
    if (!state) {
        NSLog(@"state must not be nil");
        return FALSE;  
    }

    State *tmp = [self getOrNewState:state];

    State *previousState = self.currState;
    if ([self.nextStates count] > 0)
        previousState = [(StateQueueWrapper*)[self.nextStates lastObject] state];
    
    if (![self transitionFrom:previousState to:tmp]) {
        return FALSE;
    }
    
    State *currState = tmp;
    
    [currState processForwardFromState:previousState andCallback:^(State *toState, BOOL block, BOOL skip) {
        // if state and skip, skip current state and immediately forward to toState
        if (toState && skip) {
            //NSLog(@"toStateForce 1");
            [self toState:toState.name];
        // if state but not skip, process current state first, then forward to toState
        } else if (toState && !skip) {
            //NSLog(@"toStateForce 2");
            [self addTheArrayObject:[[StateQueueWrapper alloc] initWithState:currState andBlock:block]];
            [self toState:toState.name];
        // if toState, just process current state
        } else {
            //NSLog(@"toStateForce 3");
            [self addTheArrayObject:[[StateQueueWrapper alloc] initWithState:currState andBlock:TRUE]];
        }
     }];

    return TRUE;
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([keyPath isEqualToString:@"nextStates"]) {
        [self toStateProcessor];
    }
}

-(void)toStateProcessor
{
    if (self.blockCurrentState && self.currState && [self.currState hasViewStateAfterViewState:self.currentProcessedViewState]) {
        return;
    }
        
    if ([self.nextStates count] == 0)
        return;
    
    self.previousState = self.currState;
    StateQueueWrapper *stateQueueWrapper = [self.nextStates firstObject];
    self.currState = [stateQueueWrapper state];
    self.blockCurrentState = [stateQueueWrapper block];
    [self.nextStates removeObject:stateQueueWrapper];
    
    self.currentProcessedViewState = tNoneViewState;
    [self processOnInitForPrev:self.previousState andCurrent:self.currState];
}

// query

-(State*)state:(NSString*)state
{
    return [self.states objectForKey:state];
}

-(State*)defaultState
{
    return [self state:self.defState];
}

-(State*)currentState
{
    return self.currState;
}

-(State*)prevState
{
    return self.previousState;
}

-(BOOL)inState:(NSString*)state
{
    if (!state)
        NSLog(@"state must be provided");

    if (self.currState)
        return [self.currState.name isEqualToString:state];
    else
        return FALSE;
}

// may be overwritten in sub class

-(BOOL)transitionFrom:(State*)from to:(State*)to
{
    return TRUE;
}

// helper

-(State*)getOrNewState:(NSString*)state
{
    if (![self.states objectForKey:state]) {
        State *newState = [[State alloc] initWithName:state];
        [self.states setObject:newState forKey:state];
    }

    return [self.states objectForKey:state];
}

-(void)addTheArrayObject:(NSObject*)newObject
{
    [self insertObject:newObject inNextStatesAtIndex:[self.nextStates count]];
}

-(void)insertObject:(NSObject*)obj inNextStatesAtIndex:(NSUInteger)index
{
    [self.nextStates insertObject:obj atIndex:index];
}

-(void)removeObjectFromNextStatesAtIndex:(NSUInteger)index
{
    [self.nextStates removeObjectAtIndex:index];
}

// internal processing of state transisions

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.currentControllerViewState = tDidLoadViewState;
    self.currentProcessedViewState = tDidInitViewState;
    [self processOnViewDidLoadForPrev:self.previousState andCurrent:self.currState];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.currentControllerViewState = tWillAppearViewState;
    self.currentProcessedViewState = tDidLoadViewState;
    [self processOnViewWillAppearForPrev:self.previousState andCurrent:self.currState];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.currentControllerViewState = tDidAppearViewState;
    self.currentProcessedViewState = tWillAppearViewState;
    [self processOnViewDidAppearForPrev:self.previousState andCurrent:self.currState];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.currentControllerViewState = tDidLoadViewState;
    self.currentProcessedViewState = tWillDisappearViewState;

    if (self.previousState) {
        [self.previousState processStateOut:tWillDisappearViewState toState:self.currentState];
        [(State*)[self.states objectForKey:self.allState] processStateOut:tWillDisappearViewState toState:self.currentState];
    }
    if (self.currentState) {
        [self.currentState processStateIn:tWillDisappearViewState fromState:self.previousState];
        [(State*)[self.states objectForKey:self.allState] processStateIn:tWillDisappearViewState fromState:self.previousState];
    }
    [self toStateProcessor];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.currentControllerViewState = tDidLoadViewState;
    self.currentProcessedViewState = tDidDisappearViewState;

    if (self.previousState) {
        [self.previousState processStateOut:tDidDisappearViewState toState:self.currentState];
        [(State*)[self.states objectForKey:self.allState] processStateOut:tDidDisappearViewState toState:self.currentState];
    }
    if (self.currentState) {
        [self.currentState processStateIn:tDidDisappearViewState fromState:self.previousState];
        [(State*)[self.states objectForKey:self.allState] processStateIn:tDidDisappearViewState fromState:self.previousState];
    }
    [self toStateProcessor];
}

-(void)processOnInitForPrev:(State*)previousState andCurrent:(State*)currentState
{
    if (self.currentControllerViewState >= tDidInitViewState) {
        if (self.currentProcessedViewState < tDidInitViewState) {
            self.currentProcessedViewState = tDidInitViewState;
            if (previousState) {
                [previousState processStateOut:tDidInitViewState toState:currentState];
                [(State*)[self.states objectForKey:self.allState] processStateOut:tDidInitViewState toState:currentState];
            }
            if (currentState) {
                [currentState processStateIn:tDidInitViewState fromState:previousState];
                [(State*)[self.states objectForKey:self.allState] processStateIn:tDidInitViewState fromState:previousState];
            }
        }
        [self processOnViewDidLoadForPrev:previousState andCurrent:currentState];
        
    } else {
        [self toStateProcessor];
    }
}

-(void)processOnViewDidLoadForPrev:(State*)previousState andCurrent:(State*)currentState
{
    if (self.currentControllerViewState >= tDidLoadViewState) {
        if (self.currentProcessedViewState < tDidLoadViewState) {
            self.currentProcessedViewState = tDidLoadViewState;
            if (previousState) {
                [previousState processStateOut:tDidLoadViewState toState:currentState];
                [(State*)[self.states objectForKey:self.allState] processStateOut:tDidLoadViewState toState:currentState];
            }
            if (currentState) {
                [currentState processStateIn:tDidLoadViewState fromState:previousState];
                [(State*)[self.states objectForKey:self.allState] processStateIn:tDidLoadViewState fromState:previousState];
            }
        }
        [self processOnViewWillAppearForPrev:previousState andCurrent:currentState];
        
    } else {
        [self toStateProcessor];
    }
}

-(void)processOnViewWillAppearForPrev:(State*)previousState andCurrent:(State*)currentState
{
    if (self.currentControllerViewState >= tWillAppearViewState) {
        if (self.currentProcessedViewState < tWillAppearViewState) {
            self.currentProcessedViewState = tWillAppearViewState;
            if (previousState) {
                [previousState processStateOut:tWillAppearViewState toState:currentState];
                [(State*)[self.states objectForKey:self.allState] processStateOut:tWillAppearViewState toState:currentState];
            }
            if (currentState) {
                [currentState processStateIn:tWillAppearViewState fromState:previousState];
                [(State*)[self.states objectForKey:self.allState] processStateIn:tWillAppearViewState fromState:previousState];
            }
        }
        [self processOnViewDidAppearForPrev:previousState andCurrent:currentState];
        
    } else {
        [self toStateProcessor];
    }
}

-(void)processOnViewDidAppearForPrev:(State*)previousState andCurrent:(State*)currentState
{
    if (self.currentControllerViewState == tDidAppearViewState) {
        if (self.currentProcessedViewState < tDidAppearViewState) {
            self.currentProcessedViewState = tDidAppearViewState;
            if (previousState) {
                [previousState processStateOut:tDidAppearViewState toState:currentState];
                [(State*)[self.states objectForKey:self.allState] processStateOut:tDidAppearViewState toState:currentState];
            }
            if (currentState) {
                [currentState processStateIn:tDidAppearViewState fromState:previousState];
                [(State*)[self.states objectForKey:self.allState] processStateIn:tDidAppearViewState fromState:previousState];
            }
        }
    }
    
    [self toStateProcessor];
}

@end