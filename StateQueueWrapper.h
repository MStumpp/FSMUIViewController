//
//  StateQueueWrapper.h
//  Ytubeapp
//
//  Created by Matthias Stumpp on 11.10.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "State.h"

@interface StateQueueWrapper : NSObject
-(id)initWithState:(State*)state andBlock:(BOOL)block;
@property State *state;
@property BOOL block;
@end