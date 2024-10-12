//  PWUIKit
//
//  Created by wangwei on 2023/11/16.
//

#import "PWUIToast.h"
#import "Masonry.h"

CGFloat kToastContentLeftRightOffset = 30.f;
CGFloat kToastLabTopBottomOffset = 20.f;
CGFloat kToastLabLeftRightOffset = 20.f;

NSInteger kToastContentTag = 116000;

@interface PWUIToast()
@property (nonatomic,strong)UIView    *contentView;
@property (nonatomic,strong)UILabel   *titleLab;
@property (nonatomic,strong)NSTimer   *timer;

//@property (nonatomic,copy)NSString   *titleStr;
@property (nonatomic,copy)NSAttributedString   *attributedString;

@end

@implementation PWUIToast


#pragma mark Class Setter Getter
static UIColor *classBorderColor = nil;
+ (void)setBorderColor:(UIColor *)borderColor{
    classBorderColor = borderColor;
}
+ (UIColor*)borderColor{
    return classBorderColor;
}

#pragma mark -Setter
- (void)setDuration:(int)duration{
    _duration = duration;
}
- (void)setBgColor:(UIColor *)bgColor{
    _bgColor = bgColor;
    self.contentView.backgroundColor = _bgColor;
}
- (void)setBorderColor:(UIColor *)borderColor{
    _borderColor = borderColor;
    self.contentView.layer.borderColor = _borderColor.CGColor;
}
- (void)setTitleColor:(UIColor *)titleColor{
    _titleColor = titleColor;
    self.titleLab.textColor = _titleColor;
}
#pragma mark - instancetype
+ (void)showToastWithString:(NSString*)str{
    [[[PWUIToast alloc] initWithString:str] show];
}
+ (void)showToastWithAttributedString:(NSAttributedString*)attributedString{
    [[[PWUIToast alloc] initWithAttributedString:attributedString] show];
}
- (instancetype)initWithString:(NSString*)str;{
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:str];
    return [self initWithAttributedString:attributedString];
}
- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString{
    self = [super init];
    if (self) {
        _duration = [self canculateDurationWithStr:attributedString.string];
        _attributedString = attributedString;
    }
    return self;
}

- (void)showOnView:(UIView*)aView{
    if (!aView) {
        return;
    }
    
    /// 移除上一个
    UIView * lastview = [aView viewWithTag:kToastContentTag];
    [lastview removeFromSuperview];
    
    self.titleLab.attributedText = self.attributedString;
    [self.contentView addSubview:self.titleLab];
    [aView addSubview:self.contentView];
    
    CGFloat maxWid = aView.bounds.size.width - kToastContentLeftRightOffset*2 - kToastLabLeftRightOffset*2;
    CGSize labBestSize = [self.titleLab sizeThatFits:CGSizeMake(maxWid, MAXFLOAT)];
    
    CGSize contentBestSize = CGSizeMake(labBestSize.width+kToastLabLeftRightOffset*2, labBestSize.height+kToastLabTopBottomOffset*2);
    
    [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(aView);
        make.centerY.equalTo(aView);
        make.size.mas_equalTo(contentBestSize);
    }];
    
    //
    [self.titleLab mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_contentView).offset(kToastLabTopBottomOffset);
        make.left.mas_equalTo(_contentView).offset(kToastLabLeftRightOffset);
        make.bottom.mas_equalTo(_contentView).offset(-kToastLabTopBottomOffset);
        make.right.mas_equalTo(_contentView).offset(-kToastLabLeftRightOffset);
    }];
    
    /// 开启消失定时器
    if (_timer == nil) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:_duration target:self selector:@selector(disappearAnimation) userInfo:self repeats:NO];
        //将定时器放入runloop中防止被其他事件打断
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    
}
- (void)show{
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    [self showOnView:window];
}

- (void)disappearAnimation{
    //做一个0.3秒渐渐消失的动画 以免提示框消失的生硬
   [UIView animateWithDuration:0.3 animations:^{
       self.contentView.alpha = 0;
  } completion:^(BOOL finished) {
      [self.contentView removeFromSuperview];
      self.contentView = nil;
      [self.timer invalidate];
      self.timer = nil;
   }];
}
#pragma mark - Utils
/// MARK: 根据文字长度计算一下 显示的展示时间
- (CGFloat)canculateDurationWithStr:(NSString*)str{
    CGFloat duration = 4.0f;
    NSUInteger bytes = [str lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (bytes <= 20) {
        duration = 2.0f;
    } else if(bytes > 20 && bytes <= 60) {
        duration = 2.5f;
    } else if(bytes > 60 && bytes <= 100) {
        duration = 3.0f;
    } else{
        duration = 4.0f;
    }
    return duration;
}
#pragma mark - Getter
- (UIView*)contentView{
    if(!_contentView){
        _contentView = [[UIView alloc]init];
        _contentView.tag = kToastContentTag;
        _contentView.layer.borderWidth = 1;
        _contentView.layer.borderColor = [UIColor blueColor].CGColor;
        _contentView.layer.cornerRadius = 5;
        _contentView.clipsToBounds = YES;
        _contentView.backgroundColor = [UIColor whiteColor];
        _contentView.alpha = 0.9;
    }
    return _contentView;
}
- (UILabel*)titleLab{
    if(!_titleLab){
        _titleLab = [[UILabel alloc]init];
        _titleLab.textColor = [UIColor blueColor];
        _titleLab.userInteractionEnabled = false;
#if TARGET_OS_TV
        _titleLab.font = [UIFont systemFontOfSize:30 weight:UIFontWeightMedium];
#else
        _titleLab.font = [UIFont boldSystemFontOfSize:14];
#endif
        _titleLab.numberOfLines = 0;
        _titleLab.textAlignment = NSTextAlignmentCenter;
        _titleLab.lineBreakMode = NSLineBreakByWordWrapping;
//        _titleLab.text = _titleStr;
    }
    return _titleLab;
}

@end
