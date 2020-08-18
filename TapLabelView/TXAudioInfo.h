//
//  TXAudioInfo.h
//  AudioDemo
//

#import <Foundation/Foundation.h>

static NSString *const kDefaultPlayerId = @"DefaultAudioPlayerId";

@interface TXAudioInfo : NSObject

@property (nonatomic, copy) NSString *playerId;

@property (nonatomic, copy) NSURL *audioUrl;

- (instancetype)initWithPlayerId:(NSString *)playerId
                        audioUrl:(NSURL *)audioUrl;

@end
