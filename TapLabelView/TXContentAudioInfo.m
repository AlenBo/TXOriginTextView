//
//  TXContentAudioInfo.m
//

#import "TXContentAudioInfo.h"
#import "TXAudioManager.h"

#define weakify(...) \
rac_keywordify \
metamacro_foreach_cxt(rac_weakify_,, __weak, __VA_ARGS__)

#define strongify(...) \
rac_keywordify \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
metamacro_foreach(rac_strongify_,, __VA_ARGS__) \
_Pragma("clang diagnostic pop")

@interface TXContentAudioInfo()<NSURLSessionDelegate>

@property (nonatomic, copy, readwrite) NSString *filePath;

@property (nonatomic, assign, readwrite) TXAudioInfoType type;

@end


@implementation TXContentAudioInfo

+ (instancetype)playerId:(NSString *)playerId
                        filePath:(NSString *)filePath
                            type:(TXAudioInfoType)type withBlock:(AudioSuccessBlock)successBlock{
    TXContentAudioInfo *audioInfo = [[TXContentAudioInfo alloc] init];
    if (audioInfo) {
        if (!playerId || [playerId isEqualToString:@""]) {
            playerId = kDefaultPlayerId;
        }
        audioInfo.playerId = playerId;
        audioInfo.filePath = filePath;
        audioInfo.type = type;
        //在这里可以做在线播放类型的判断
        if (isHttpURLString(filePath)) {
            audioInfo.audioUrl = [NSURL URLWithString:filePath];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:filePath]];
                request.cachePolicy = NSURLRequestUseProtocolCachePolicy;
                NSURLSession *session = [TXAudioManager downloadAudioSessionWithDelegate:audioInfo];
                NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    if (!error) {
                        audioInfo.audioData = [NSData dataWithContentsOfURL:location];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (successBlock) {
                            successBlock(error?nil:audioInfo);
                        }
                    });
                }];
                [task resume];
                NSMutableDictionary *audioDic = [TXAudioManager downloadingAudioArr];
                audioDic[filePath] = task;
            });
        } else {
            audioInfo.audioUrl = [NSURL fileURLWithPath:filePath];
            if (successBlock) {
                successBlock(audioInfo);
            }
        }
    }
    return audioInfo;
}

#pragma -- mark  NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    NSURLCredential *card = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential,card);
}

BOOL isHttpURLString(NSString *urlString) {
    return ([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"]);
}

@end
