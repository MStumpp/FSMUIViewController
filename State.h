//
//  State.h
//  Ytubeapp
//
//  Created by Matthias Stumpp on 07.01.13.
//  Copyright (c) 2013 Matthias Stumpp. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ViewCallback)();

@interface State : NSObject
@property int name;
-(id)initWithName:(int)name;
-(State*)onViewState:(int)state do:(ViewCallback)callback;
-(void)processState:(int)state;
@end
