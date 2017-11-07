//
//  TXAudioInfo.h
//  AudioDemo
//
//  Created by BloodLine on 16/5/2.
//  Copyright © 2016年 BloodLine. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const kDefaultPlayerId = @"DefaultAudioPlayerId";

@interface TXAudioInfo : NSObject

@property (nonatomic, copy) NSString *playerId;

@property (nonatomic, copy) NSURL *audioUrl;

- (instancetype)initWithPlayerId:(NSString *)playerId
                        audioUrl:(NSURL *)audioUrl;

@end
