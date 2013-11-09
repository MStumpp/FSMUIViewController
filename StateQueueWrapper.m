//
//  StateQueueWrapper.m
//  Ytubeapp
//
//  Created by Matthias Stumpp on 11.10.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import "StateQueueWrapper.h"

@implementation StateQueueWrapper
-(id)initWithState:(State*)state andBlock:(BOOL)block
{
    self = [self init];
    if (self) {
        self.state = state;
        self.block = block;
    }
    return self;
}
@end