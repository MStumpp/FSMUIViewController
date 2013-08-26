//
//  StateViewController.h
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "State.h"
#import "StateSet.h"

@interface FSMUIViewController : UIViewController

// state configuration

-(State*)configureState:(NSString*)state;
-(State*)configureDefaultState;

-(StateSet*)configureStates:(NSArray*)states;
-(StateSet*)configureAllStates;

-(BOOL)setDefaultState:(NSString*)state;

// state transition

-(BOOL)toState:(NSString*)state;
-(BOOL)toDefaultState;

-(BOOL)toStateForce:(NSString*)state;
-(BOOL)toDefaultStateForce;

-(BOOL)transitionFrom:(State*)from to:(State*)to;
@end
