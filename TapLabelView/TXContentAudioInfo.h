//
//  TXContentAudioInfo.h
//

#import "TXAudioInfo.h"
@class TXContentAudioInfo;

typedef void(^AudioSuccessBlock)(TXContentAudioInfo *audioInfo);

typedef NS_ENUM (NSUInteger, TXAudioInfoType){
    TXAudioInfoTypeNormal = 1, //普通音频文件
    TXAudioInfoTypeRecord = 2, //用户自己的录音文件
    TXAudioInfoTypeDownloadRecord = 3, //通过downloadShareMp3下载的音频
    TXAudioInfoTypePlayPath = 4,//播放绝对路径的音频
    TXAudioInfoTypeOnline = -1, //在线音频
    //其它值
};

@interface TXContentAudioInfo : TXAudioInfo

@property (nonatomic, copy, readonly) NSString *filePath;

@property (nonatomic, assign, readonly) TXAudioInfoType type;
@property (nonatomic, strong) NSData *audioData;

+ (instancetype)playerId:(NSString *)playerId
        filePath:(NSString *)filePath
            type:(TXAudioInfoType)type withBlock:(AudioSuccessBlock)successBlock;
@end
