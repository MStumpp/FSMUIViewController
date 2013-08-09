//
//  StateViewController.h
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "State.h"

@interface StatefulUIViewController : UIViewController

// state related

-(State*)configureState:(int)state;
-(void)toState:(int)state;
-(void)setInitialState:(int)state;
-(void)toInitialState;

// view queue related

-(void)onViewState:(int)state doOnce:(ViewCallback)callback;
-(void)onViewState:(int)state when:(BOOL)when doOnce:(ViewCallback)callback;
-(void)onViewState:(int)state doForever:(ViewCallback)callback;
-(void)onViewState:(int)state when:(BOOL)when doForever:(ViewCallback)callback;

-(void)removeAllOnces:(int)state;
-(void)removeAllForevers:(int)state;

@end
