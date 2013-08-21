//
//  StateViewController.h
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "State.h"

#define tDidInitViewState 11
#define tDidLoadViewState 12
#define tWillAppearViewState 13
#define tDidAppearViewState 14
#define tWillDisappearViewState 15
#define tDidDisappearViewState 16
#define tWillUnloadViewState 17
#define tDidUnloadViewState 18

@interface StatefulUIViewController : UIViewController

// state related

-(State*)configureState:(int)state;
-(State*)configureDefaultState;
-(void)toStateForce:(int)state;
-(void)toDefaultStateForce;

@end
