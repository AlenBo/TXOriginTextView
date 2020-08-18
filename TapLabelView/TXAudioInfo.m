//
//  TXAudioInfo.m
//  AudioDemo
//

#import "TXAudioInfo.h"

@implementation TXAudioInfo

- (instancetype)initWithPlayerId:(NSString *)playerId
                        audioUrl:(NSURL *)audioUrl {
    self = [super init];
    if (self) {
        if (!playerId || [playerId isEqualToString:@""]) {
            playerId = kDefaultPlayerId;
        }
        self.playerId = playerId;
        self.audioUrl = audioUrl;
//        NSAssert(self.playerId, @"AudioPlayerId should not be nil!");
//        NSAssert(self.audioUrl, @"Audio URL should not be nil!");
    }
    return self;
}

@end
