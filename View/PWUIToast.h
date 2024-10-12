//  PWUIKit
//
//  Created by wangwei on 2023/11/16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PWUIToast : NSObject
/// 全局设置 边框颜色
@property (nonatomic,strong,class) UIColor *borderColor;
/// 展示持续时间，如果不设置 将会根据文字长度 自行计算展示持续时间
@property (nonatomic,assign) int duration;

@property (nonatomic,strong) UIColor *bgColor;
@property (nonatomic,strong) UIColor *borderColor;
@property (nonatomic,strong) UIColor *titleColor;

///
+ (void)showToastWithString:(NSString*)str;
+ (void)showToastWithAttributedString:(NSAttributedString*)attributedString;

- (instancetype)initWithString:(NSString*)str;
- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString;
/// MARK: 这里面有一个逻辑 就是show的时候 默认是在keyWindow上的 上一个在keyWindow的Toast将会被直接移除
- (void)show;
- (void)showOnView:(UIView*)aView;
- (void)disappearAnimation;


@end
