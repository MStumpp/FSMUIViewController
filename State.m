//
//  State.m
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import "State.h"

@interface State()
@property NSMutableDictionary *states;
@end

@implementation State

-(id)initWithName:(int)name
{
    self = [super init];
    if (self) {
        self.name = name;
        self.states = [NSMutableDictionary dictionary];
    }
    return self;
}

-(State*)onViewState:(int)state do:(ViewCallback)callback
{
    if (![self.states objectForKey:[NSNumber numberWithInt:state]])
        [self.states addEntriesFromDictionary:[NSDictionary dictionaryWithObject:[NSMutableArray arrayWithObject:callback] forKey:[NSNumber numberWithInt:state]]];
    else
        [[self.states objectForKey:[NSNumber numberWithInt:state]] addObject:callback];
    return self;
}

-(void)processState:(int)state
{
    if ([self.states objectForKey:[NSNumber numberWithInt:state]]) {
        [[self.states objectForKey:[NSNumber numberWithInt:state]] enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            ((ViewCallback)object)();
        }];
    }
}

@end
