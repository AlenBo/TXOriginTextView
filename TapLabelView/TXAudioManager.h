//
//  TXAudioManager.h
//

#import <Foundation/Foundation.h>
#import "TXAudioInfo.h"
#import "Singleton.h"
#import "AVAudioPlayer+TX.h"
#import <AVFoundation/AVFoundation.h>
#import "TXContentAudioInfo.h"

@interface TXAudioManager : NSObject

//+ (NSMutableDictionary *)players;
//获取下载音频的数组
+ (NSMutableDictionary *)downloadingAudioArr;
//获取下载的session
+(NSURLSession *)downloadAudioSessionWithDelegate:(id<NSURLSessionDelegate>)delegate;

// 根据音乐文件名称播放音乐
+ (AVAudioPlayer *)playWithAudioInfo:(TXContentAudioInfo *)audioInfo;

// 根据音乐文件名称暂停音乐
+ (void)pauseWithPlayerId:(NSString *)playerId;

//是否正在播放
+ (BOOL)isPlaying:(NSString *)playerId;

+ (AVAudioPlayer *)resumeWithPlayerId:(NSString *)playerId;

// 根据音乐文件名称停止音乐
+ (void)stopWithPlayerId:(NSString *)playerId;

+ (void)stopAllAudio;

+ (void)pauseAllAudio;

/**
 * 定点播放
 * @param 播放器id
 * @param position 单位：毫秒
 */
+ (AVAudioPlayer *)seekWithPlayerId:(NSString *)playerId position:(NSUInteger)position;

/**
 * 获取当前播放时间点
 * @param 播放器id
 * @return 单位毫秒
 */
+ (NSUInteger)currentTimeWithPlayerId:(NSString *)playerId;

/**
 * 获取音频文件时长
 * @param 播放器id
 * @param 单位毫秒
 */
+ (NSUInteger)durationWithPlayerId:(NSString *)playerId;

//正在播放的id,只允许一路音频播放
+ (NSString *)playingId;

@end
