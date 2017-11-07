//
//  TXAudioManager.m
//  txmanios
//
//  Created by 晓童 韩 on 16/1/12.
//  Copyright © 2016年 up366. All rights reserved.
//

#import "TXAudioManager.h"

@implementation TXAudioManager

+ (void)initialize {
    // 1.创建音频会话
    AVAudioSession *session = [[AVAudioSession alloc] init];
    // 2.设置会话类型
    [session setCategory:AVAudioSessionCategoryPlayback
             withOptions: AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth
                   error:nil];
    // 3.激活会话
    [session setActive:YES error:nil];
}

//static NSMutableDictionary *_audioIDs;
static NSMutableDictionary *_players;
static NSMutableDictionary *_downloadingAudioArr;
static NSURLSession *_downloadAudioSession;


+ (NSMutableDictionary *)players {
    if (!_players) {
        _players = [NSMutableDictionary dictionary];
    }
    return _players;
}
+ (NSMutableDictionary *)downloadingAudioArr{
    if (!_downloadingAudioArr) {
        _downloadingAudioArr = [NSMutableDictionary dictionary];
    }
    return _downloadingAudioArr;
}
+(NSURLSession *)downloadAudioSessionWithDelegate:(id<NSURLSessionDelegate>)delegate{
    if (!_downloadAudioSession) {
        _downloadAudioSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:delegate delegateQueue:[NSOperationQueue currentQueue]];
    }
    return _downloadAudioSession;
}

// 根据音乐文件名称播放音乐
+ (AVAudioPlayer *)playWithAudioInfo:(TXContentAudioInfo *)audioInfo {
    
    [self switchToBluetooth];
    
    // 0.判断文件名是否为nil
    if (!audioInfo || !audioInfo.playerId || !audioInfo.audioUrl) {
        return nil;
    }
    
    // 1.从字典中取出播放器
    AVAudioPlayer *player = [self players][audioInfo.playerId];
    // 2.判断播放器是否为nil
    if (![player.url.absoluteString isEqualToString:audioInfo.audioUrl.absoluteString]) {
        NSLog(@"创建新的播放器");
        NSError *error;
        NSData *soundData;
        if (HttpURLString(audioInfo.audioUrl.absoluteString)) {
            if (audioInfo.audioData) {
                soundData = audioInfo.audioData;
            }
        } else {
            soundData = [[NSFileManager defaultManager] contentsAtPath:audioInfo.filePath];
        }
        
        player = [[AVAudioPlayer alloc] initWithData:soundData fileTypeHint:AVFileTypeMPEGLayer3 error:&error];
        player.playerId = audioInfo.playerId;
        if(![player prepareToPlay]) {
            return nil;
        }
        
        [self players][audioInfo.playerId] = player;
    }
    
    if (!player.playing) {
        [player play];
    }
    return player;
}

// 根据音乐文件名称播放音乐
+ (AVAudioPlayer *)resumeWithPlayerId:(NSString *)playerId {
    
    [self switchToBluetooth];
    
    // 0.判断文件名是否为nil
    if (!playerId) {
        return nil;
    }
    
    // 1.从字典中取出播放器
    AVAudioPlayer *player = [self players][playerId];
    
    // 2.判断播放器是否为nil
    if (!player) {
        return nil;
    }
    // 3.播放音乐
    if (!player.playing) {
        [player play];
    }
    return player;
}

// 根据音乐文件名称暂停音乐
+ (void)pauseWithPlayerId:(NSString *)playerId {
    // 0.判断文件名是否为nil
    if (!playerId) {
        return;
    }
    
    // 1.从字典中取出播放器
    AVAudioPlayer *player = [self players][playerId];
    
    // 2.判断播放器是否存在
    if(player && player.playing) {
        // 暂停
        [player pause];
    }
    
}

/**
 * 定点播放
 * @param 播放器id
 * @param position 单位：毫秒
 */
+ (AVAudioPlayer *)seekWithPlayerId:(NSString *)playerId position:(NSUInteger)position {
    if (!playerId) {
        return nil;
    }
    AVAudioPlayer *player = [self players][playerId];
    player.currentTime = position / 1000.0f;

    //已经播放完成的继续播放
    if (![player isPlaying]) {
        [player play];
    }
    return player;
}

/**
 * 获取当前播放时间点
 * @param 播放器id
 * @return 单位毫秒
 */
+ (NSUInteger)currentTimeWithPlayerId:(NSString *)playerId {
    if (!playerId) {
        return 0;
    }
    AVAudioPlayer *player = [self players][playerId];
    return player.currentTime * 1000;
}

/**
 * 获取音频文件时长
 * @param 播放器id
 * @param 单位毫秒
 */
+ (NSUInteger)durationWithPlayerId:(NSString *)playerId {
    if (!playerId) {
        return 0;
    }
    AVAudioPlayer *player = [self players][playerId];
    return player.duration * 1000;
}

//如果可用设备有蓝牙设备，设置为蓝牙设备为input设备
+ (void)switchToBluetooth{
    NSArray* bluetoothRoutes = @[AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE, AVAudioSessionPortBluetoothHFP];
    
    NSArray *routes = [[AVAudioSession sharedInstance] availableInputs];
    
    for (AVAudioSessionPortDescription* route in routes)
    {
        if ([bluetoothRoutes containsObject:route.portType])
        {
            NSError* audioError = nil;
            [[AVAudioSession sharedInstance] setPreferredInput:route
                                                         error:&audioError];
        }
    }
}

// 根据音乐文件名称停止音乐
+ (void)stopWithPlayerId:(NSString *)playerId {
    // 0.判断文件名是否为nil
    if (playerId == nil) {
        return;
    }
    
    // 1.从字典中取出播放器
    AVAudioPlayer *player = [self players][playerId];
    
    // 2.判断播放器是否为nil
    if (player) {
        // 2.1停止播放
        [player stop];
        // 2.2从字典中移除播放器
        [[self players] removeObjectForKey:playerId];
        player = nil;
    }
}

+ (void)stopAllAudio {
    for (AVAudioPlayer *player in [[self players] allValues]) {
        [player stop];
    }
    [[self players] removeAllObjects];
}

+ (void)pauseAllAudio {
    for (AVAudioPlayer *player in [[self players] allValues]) {
        [player pause];
    }
}

+ (BOOL)isPlaying:(NSString *)playerId {
    AVAudioPlayer *player = [self players][playerId];
    return player.playing;
}

//正在播放的id,只允许一路音频播放
+ (NSString *)playingId {
    __block NSString *playingId;
   [_players enumerateKeysAndObjectsUsingBlock:^(NSString *playerId, AVAudioPlayer *player, BOOL * _Nonnull stop) {
       if (player.isPlaying) {
           playingId = playerId;
           *stop = YES;
       }
   }];
    
    return playingId;
}


BOOL HttpURLString(NSString *urlString) {
    return ([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"]);
}

@end
