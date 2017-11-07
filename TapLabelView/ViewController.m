//
//  ViewController.m
//  TapLabelView
//
//  Created by YouXianMing on 15/6/13.
//  Copyright (c) 2015年 YouXianMing. All rights reserved.
//

#import "ViewController.h"
#import "TTTAttributeLabelView.h"
#import "NSString+RichText.h"
#import "TTTAttributedLabel.h"
#import "TXContentAudioInfo.h"
#import "TXAudioManager.h"

#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
#define SCREEN_WIDTH  ([UIScreen mainScreen].bounds.size.width)

@interface ViewController () <TTTAttributeLabelViewDelegate,UIScrollViewDelegate,AVAudioPlayerDelegate>
{
    NSTimer *_positionTimer;
}

@property (nonatomic, strong) TTTAttributeLabelView  *attributeLabelView;

@property (nonatomic, strong) NSMutableAttributedString *attributedString;

@property (nonatomic, strong) NSString *string;

@property (nonatomic, strong) NSMutableArray <NSMutableArray *>*section;

@property (nonatomic, strong) NSMutableParagraphStyle *style;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) NSArray *timePoints;

@property (nonatomic, strong) NSString *audioPath;

@property (nonatomic, strong) NSString *audioPlayerId;

@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, strong) NSIndexPath *indexPath;

@property (nonatomic, strong) NSMutableArray *sentenceLengths;

@property (nonatomic, strong) TXContentAudioInfo *audioInfo;

@property (nonatomic, assign) BOOL isDownloading;

@end

@implementation ViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    for (int i = 0; i<100; i++) {
        NSLog(@"-------%i",i);
        if (i== 10) goto finish;
    }

    finish : {
        NSLog(@"已经结束");
    }

    // 创建富文本
    self.string = @"";
    self.sentenceLengths = [NSMutableArray array];
    for (NSArray *sentences in self.section) {

        [self.sentenceLengths addObject:@(self.string.length)];

        for (NSString *sentence in sentences) {
            self.string = [self.string stringByAppendingString:sentence];
        }
        self.string = [self.string stringByAppendingString:@"\n"];
    }

    self.style = [NSMutableParagraphStyle new];
    self.style.lineSpacing              = 4.f;
    self.style.paragraphSpacing         = self.style.lineSpacing * 4;
    self.style.alignment                = NSTextAlignmentCenter;
    self.attributedString  = \
        [self.string createAttributedStringAndConfig:@[[ConfigAttributedString foregroundColor:[UIColor whiteColor] range:self.string.range],
                                                  [ConfigAttributedString paragraphStyle:self.style range:self.string.range],
                                                  [ConfigAttributedString font:[UIFont fontWithName:@"TimesNewRomanPSMT" size:20.f] range:self.string.range]]];
    
    // 初始化对象
    self.attributeLabelView                    = [[TTTAttributeLabelView alloc] initWithFrame:CGRectMake(45,0,SCREEN_WIDTH-45,SCREEN_HEIGHT)];
    self.attributeLabelView.attributedString   = self.attributedString;
    self.attributeLabelView.delegate           = self;
    self.attributeLabelView.linkColor          = [UIColor blackColor];
    self.attributeLabelView.activeLinkColor    = [UIColor blackColor];



    [self.section enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSArray *obj1, NSUInteger idx1, BOOL * _Nonnull stop) {

        [obj1 enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *obj2, NSUInteger idx2, BOOL * _Nonnull stop) {
            NSRange range = [self.string rangeOfString:obj2];
            [self.attributeLabelView addLinkStringRange:range flag:[NSString stringWithFormat:@"%lu-%lu",idx1,idx2]];
        }];


    }];

    // 进行渲染
    [self.attributeLabelView render];
    [self.attributeLabelView resetSize];

    //内容滚动视图
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, SCREEN_HEIGHT-64)];
    self.scrollView.backgroundColor = [UIColor whiteColor];
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH, self.attributeLabelView.bounds.size.height);
    self.scrollView.pagingEnabled = NO;

    [self.scrollView addSubview:self.attributeLabelView];
    [self.view addSubview:self.scrollView];

    for (int i = 0; i<self.sentenceLengths.count; i++) {
        float y = 0;
        NSAttributedString *attributesStr = [self.attributedString attributedSubstringFromRange:NSMakeRange(0, [self.sentenceLengths[i] integerValue])];
        CGSize finishStrSize = [TTTAttributeLabelView sizeThatFitsAttributedString:attributesStr withFixedWidth:SCREEN_WIDTH-45];
        y = i ? finishStrSize.height+20 : 0;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 35, 30)];
        label.text = i%2==0?@"M:":@"w:";
        label.font = [UIFont systemFontOfSize:20];
        label.textAlignment = NSTextAlignmentRight;
        label.textColor = [UIColor greenColor];
        [self.scrollView addSubview:label];
    }


    //配置播放器
    [self setupAudioPlayer];

}

- (void)TTTAttributeLabelView:(TTTAttributeLabelView *)attributeLabelView linkFlag:(NSString *)flag {
    if (self.isDownloading) {
#warning mark - 给出正在缓存的提示，是否是https
        return;
    }


    //点击的时候重置一下颜色
    [self resetAttributes];

    NSArray *indexPath = [flag componentsSeparatedByString:@"-"];
    NSInteger x = [indexPath.firstObject integerValue];
    NSInteger y = [indexPath.lastObject integerValue];

    //记录二维数组
    self.indexPath = [NSIndexPath indexPathForRow:y inSection:x];

    //更改当前句子的颜色
    [self changeCurrentAttributesStringStyle];

    NSInteger timeIndex = 0;
    for (int i = 0; i < x ; i++) {
        timeIndex += [self.section[i] count];
    }
    timeIndex += y;


    //记录当前index
    self.currentIndex = timeIndex;

    //根据点击的点，开始定点播放
    [self seekToPlayWithPosition:[[self.timePoints[timeIndex] firstObject] floatValue]];

    //手动点击之后重置
    if(_positionTimer) {
        [_positionTimer invalidate];
        _positionTimer = nil;
    }


    _positionTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(changeAttributesAndScrollViewPosition:) userInfo:^{

    } repeats:YES];

}

- (void)changeAttributesAndScrollViewPosition:(NSTimer *)timer {

    //最后一个播放的句子无需设置定时器，释放掉
    if (self.indexPath.section == self.section.count-1 && self.indexPath.row == self.section.lastObject.count-1) {
        //播放到最后一句移除定时器
        if(_positionTimer) {
            [_positionTimer invalidate];
            _positionTimer = nil;
        }
        return;
    }

    NSInteger currentTime =[TXAudioManager currentTimeWithPlayerId:self.audioPlayerId];
    if (currentTime/1000.0 > [[self.timePoints[self.currentIndex] lastObject] floatValue]) {
        //重新着色
        //二位数组中找到下一个
        if (self.indexPath.row+1 <= self.section[self.indexPath.section].count-1) {
            self.indexPath = [NSIndexPath indexPathForRow:self.indexPath.row+1 inSection:self.indexPath.section];
        } else {
            self.indexPath = [NSIndexPath indexPathForRow:0 inSection:self.indexPath.section+1];
        }
        self.currentIndex += 1;

        //重置一下颜色
        [self resetAttributes];

        //更改当前句子的颜色
        [self changeCurrentAttributesStringStyle];
    }
    
}


//重置富文本属性
- (void)resetAttributes {
    self.attributedString = \
    [self.string resetAttributedString:self.attributedString config:@[[ConfigAttributedString foregroundColor:[UIColor whiteColor] range:self.string.range],
                                                                      [ConfigAttributedString paragraphStyle:self.style range:self.string.range],
                                                                      [ConfigAttributedString font:[UIFont fontWithName:@"TimesNewRomanPSMT" size:20.f] range:self.string.range]]];
}

//设置当前正在播放的句子的属性，颜色、字体、字号等
- (void)changeCurrentAttributesStringStyle {
    NSString *currentString = self.section[self.indexPath.section][self.indexPath.row];
    NSRange range = [self.string rangeOfString:currentString];

////    设置当前链接的字体
//    [self.attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:20.f] range:range];

    //1、重绘之前的link的color
    [self.attributeLabelView render];
    //2、重新计算link的size
    [self.attributeLabelView resetSize];

    //3、更改当前link的color
    [self.attributeLabelView changeCurrentLinkAttributeWith:range URL:[NSURL URLWithString:[NSString stringWithFormat:@"%lu-%lu",self.indexPath.section,self.indexPath.row]] color:[UIColor blueColor]];

    //重新设置一下滚动视图的高度
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH, self.attributeLabelView.bounds.size.height);

    //计算高度
    NSInteger curStrloc = range.location + range.length;
    NSAttributedString *attributesStr = [self.attributedString attributedSubstringFromRange:NSMakeRange(0, curStrloc)];
    CGSize finishStrSize = [TTTAttributeLabelView sizeThatFitsAttributedString:attributesStr withFixedWidth:SCREEN_WIDTH-45];

    if (finishStrSize.height >= (SCREEN_HEIGHT-64)/2) {
        //这个时候就要开始滚动
        if (self.scrollView.contentSize.height - finishStrSize.height <= SCREEN_HEIGHT/2) {
            return;
        } else {
            [self.scrollView setContentOffset:CGPointMake(0,finishStrSize.height-(SCREEN_HEIGHT-64)/3) animated:YES];
        }
    }
}

//配置播放器并开始播放
- (void)setupAudioPlayer {
//    self.audioPath = @"https://qlib-cdn11.up366.cn/xot_upload_files/media/2016/1027/5b38d3a0c7da4b7ea1ffd7e9465bdcbb/media/M1-T2-ZC.mp3";
    self.audioPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"M60-T7-ZC.mp3"];
    self.audioPlayerId = @"ceshi_player";

    self.isDownloading = YES;
    self.audioInfo = [TXContentAudioInfo playerId:self.audioPlayerId filePath:self.audioPath type:TXAudioInfoTypeOnline withBlock:^(TXContentAudioInfo *audioInfo) {
        [[TXAudioManager downloadingAudioArr] removeObjectForKey:self.audioPath];
        self.isDownloading = NO;
        //block没有执行，防止重复点击

        //返回了失败，重新下载


        AVAudioPlayer *player = [TXAudioManager playWithAudioInfo:audioInfo];
        player.delegate = self;
        //重头开始播放
        [self TTTAttributeLabelView:self.attributeLabelView linkFlag:@"0-0"];
    }];

}

//参数是秒（s）
- (void)seekToPlayWithPosition:(NSInteger)position {
    [TXAudioManager seekWithPlayerId:self.audioPlayerId position:position*1000];
}

#pragma market ————————————————————————————————————————————————————造的假数据。
- (NSMutableArray<NSMutableArray *> *)section {
    if (!_section) {
        _section = [NSMutableArray array];

        NSMutableArray *array1 = [NSMutableArray array];
        [array1 addObject:@"Well, Shirley, now that we’ve seen the three apartments, which one do you like most?"];

        NSMutableArray *array2 = [NSMutableArray array];
        [array2 addObject:@"I don’t know, Brad."];
        [array2 addObject:@"But I do know one thing: I didn’t like the one on 68th Street."];

        NSMutableArray *array3 = [NSMutableArray array];
        [array3 addObject:@"Neither did I. Let’s cross that one off."];
        [array3 addObject:@"That leaves the 72nd Street one and the 80th Street one."];

        NSMutableArray *array4 = [NSMutableArray array];
        [array4 addObject:@"The one on 80th Street has a better view, and a very cheerful kitchen."];


        NSMutableArray *array5 = [NSMutableArray array];
        [array5 addObject:@"Yes, and I like the carpeting in the hall."];
        [array5 addObject:@"It was quite clean."];
        [array5 addObject:@"But there was no place to put a desk."];

        NSMutableArray *array6 = [NSMutableArray array];
        [array6 addObject:@"That’s true."];
        [array6 addObject:@"If we put it in the corner of the living room, we wouldn’t have any privacy, and the bedroom would be too small."];

        NSMutableArray *array7 = [NSMutableArray array];
        [array7 addObject:@"Right. What about the 72nd Street apartment? "];
        [array7 addObject:@"It has a dining area. "];
        [array7 addObject:@"We could eat in the kitchen and put the desk in the dining area."];

        NSMutableArray *array8 = [NSMutableArray array];
        [array8 addObject:@"That sounds OK."];
        [array8 addObject:@"I think that apartment is best for our needs."];
        [array8 addObject:@"There’s also good parking."];

        NSMutableArray *array9 = [NSMutableArray array];
        [array9 addObject:@"Yes, let’s take that one."];

        [_section addObject:array1];
        [_section addObject:array2];
        [_section addObject:array3];
        [_section addObject:array4];
        [_section addObject:array5];
        [_section addObject:array6];
        [_section addObject:array7];
        [_section addObject:array8];
        [_section addObject:array9];



    }

    return _section;
}

- (NSArray *)timePoints {
    if (!_timePoints) {
        _timePoints = @[@[@(0.255),@(5.342)],@[@(5.342),@(7.358)],@[@(7.358), @(12.284)],@[@(12.284), @(15.708)],@[@(15.708), @(20.000)],@[@(20.000), @(25.241)],@[@(25.241), @(28.216)],@[@(28.216), @(30.000)],@[@(30.000), @(32.375)],@[@(32.375), @(33.495)], @[@(33.495), @(40.245)],@[@(40.245), @(44.000)],@[@(44.000), @(46.000)],@[@(46.000), @(50.000)],@[@(50.000), @(52.000)],@[@(52.000), @(55.000)],@[@(55.000), @(57.000)],@[@(57.000), @(59.316)]];
    }
    return _timePoints;
}

@end
