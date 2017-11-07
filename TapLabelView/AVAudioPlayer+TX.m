//
//  AVAudioPlayer+TX.m
//  txmanios
//
//  Created by BloodLine on 16/5/2.
//  Copyright © 2016年 up366. All rights reserved.
//

#import "AVAudioPlayer+TX.h"
#import <objc/runtime.h>

@implementation AVAudioPlayer (TX)

static char PlayerIdKey;

- (void)setPlayerId:(NSString *)playerId {
    [self willChangeValueForKey:@"PlayerIdKey"];
    objc_setAssociatedObject(self, &PlayerIdKey,
                             playerId,
                             OBJC_ASSOCIATION_COPY);
    [self didChangeValueForKey:@"PlayerIdKey"];
}

- (NSString *)playerId {
    return objc_getAssociatedObject(self, &PlayerIdKey);
}

@end
