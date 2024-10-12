#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
+ (NSString *)getOpenCVVersion;
+ (UIImage *)grayscaleImg:(UIImage *)image;
+ (UIImage *)resizeImg:(UIImage *)image :(int)width :(int)height :(int)interpolation;
@end


@interface ModelWrapper : NSObject
- (instancetype)init;
- (BOOL)loadModel:(NSString *)paramPath binPath:(NSString *)binPath;
- (NSDictionary *)prewithResize:(UIImage *)inputImage;
- (NSDictionary *)predict:(UIImage *)inputImages;
- (NSDictionary *)predictGF:(NSArray<UIImage *> *)inputFrames;
- (NSDictionary *)predictGFwithframes:(NSArray<UIImage *> *)inputFrames;
@end
NS_ASSUME_NONNULL_END
