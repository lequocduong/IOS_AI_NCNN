//
//  ViewController.m
//  AIEnhance
//
//  Created by mike on 2024/9/11.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import "PWUIToast.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVPlayerViewController.h>
#import <opencv2/opencv.hpp>
#import <FLEX/FLEX.h>
#import "pw_ai_call.h"
#import "PWPotoVC.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UIStackView *stackView;
@property(nonatomic, strong) UIButton *imageButton;
@property(nonatomic, strong) UIButton *videoButton;
@property(nonatomic, strong) UIStackView *stack2View;
@property(nonatomic, strong) UIImageView *imageView;
@property(nonatomic, strong) UIImageView *imag2View;
@property(nonatomic, strong) UIButton *enhanceButton;
@property(nonatomic, strong) UIButton *saveBtton;
@property(nonatomic, strong) UIButton *deleteButton;
@property(nonatomic, strong) UIButton *deleteVideoButton;
@property(nonatomic, strong) UIButton *sandboxButton;

@property(nonatomic, strong) UIImagePickerController *imagePickerController;
@property(nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property(nonatomic, strong) UIActivityViewController *activityViewController;

@property(nonatomic, strong) UILabel *timeLabel;
@property(nonatomic, strong) NSURL *videoURL;
@property(nonatomic, strong) NSURL *imageURL;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AI Enhance";
    [self configView];
    [self configData];
}

- (void)configView {
    _contentView = [[UIView alloc] init];
    [self.view addSubview:_contentView];
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.bottom.mas_equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    _stackView = [[UIStackView alloc] init];
    _stackView.spacing = 15;
    _stackView.distribution = UIStackViewDistributionFillEqually;
    [_contentView addSubview:_stackView];
    [_stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_contentView).offset(50);
        make.left.equalTo(_contentView);
        make.right.equalTo(_contentView);
        make.height.mas_equalTo(40);
    }];
    
    _imageButton = [[UIButton alloc] init];
    [_imageButton setTitle:@"select photo" forState:UIControlStateNormal];
    [_imageButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_imageButton setTitleColor:[UIColor colorWithWhite:0 alpha:0.5] forState:UIControlStateHighlighted];
    _imageButton.layer.borderWidth = 1;
    _imageButton.layer.borderColor = [UIColor blueColor].CGColor;
    _imageButton.layer.cornerRadius = 12;
    [_imageButton addTarget:self action:@selector(imageAction) forControlEvents:UIControlEventTouchUpInside];
    [_stackView addArrangedSubview:_imageButton];
    
    _videoButton = [[UIButton alloc] init];
    [_videoButton setTitle:@"select video" forState:UIControlStateNormal];
    [_videoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_videoButton setTitleColor:[UIColor colorWithWhite:0 alpha:0.5] forState:UIControlStateHighlighted];
    _videoButton.layer.borderWidth = 1;
    _videoButton.layer.borderColor = [UIColor blueColor].CGColor;
    _videoButton.layer.cornerRadius = 12;
    [_videoButton addTarget:self action:@selector(videoAction) forControlEvents:UIControlEventTouchUpInside];
    [_stackView addArrangedSubview:_videoButton];
    
    _stack2View = [[UIStackView alloc] init];
    _stack2View.spacing = 15;
    _stack2View.axis = UILayoutConstraintAxisVertical;
    _stack2View.distribution = UIStackViewDistributionFillEqually;
    [_contentView addSubview:_stack2View];
    [_stack2View mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_stackView.mas_bottom).offset(30);
        make.left.equalTo(_contentView);
        make.right.equalTo(_contentView);
        make.bottom.equalTo(_contentView).offset(-200);
    }];
    
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.layer.borderWidth = 0.5;
    _imageView.layer.borderColor = [UIColor blackColor].CGColor;
    [_stack2View addArrangedSubview:_imageView];

    
    _imag2View = [[UIImageView alloc] init];
    _imag2View.contentMode = UIViewContentModeScaleAspectFit;
    _imag2View.layer.borderWidth = 0.5;
    _imag2View.layer.borderColor = [UIColor blackColor].CGColor;
    [_stack2View addArrangedSubview:_imag2View];
    
    _deleteButton = [[UIButton alloc] init];
    _deleteButton.hidden = true;
    [_deleteButton setImage:[UIImage imageNamed:@"button_close"] forState:UIControlStateNormal];
    [_deleteButton addTarget:self action:@selector(deleteAction) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_deleteButton];
    [_deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_imageView);
        make.right.equalTo(_imageView);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
    }];
    
    _saveBtton = [[UIButton alloc] init];
    _saveBtton.hidden = true;
    [_saveBtton setImage:[UIImage imageNamed:@"cloudVideoDownload"] forState:UIControlStateNormal];
    [_saveBtton addTarget:self action:@selector(saveAction) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_saveBtton];
    [_saveBtton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_imag2View);
        make.right.equalTo(_imag2View);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
    }];
    
    _enhanceButton = [[UIButton alloc] init];
    [_enhanceButton setTitle:@"enhance" forState:UIControlStateNormal];
    [_enhanceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_enhanceButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateHighlighted];
    _enhanceButton.backgroundColor = [UIColor systemPinkColor];
    _enhanceButton.layer.cornerRadius = 12;
    [_enhanceButton addTarget:self action:@selector(enhanceAction) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_enhanceButton];
    [_enhanceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_stack2View.mas_bottom).offset(80);
        make.centerX.equalTo(_contentView);
        make.height.mas_equalTo(46);
        make.width.mas_equalTo(160);
    }];
    
    _imageView.userInteractionEnabled = true;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [_imageView addGestureRecognizer:tap];
    
    _imag2View.userInteractionEnabled = true;
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [_imag2View addGestureRecognizer:tap2];
    
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _activityIndicator.center = self.view.center;
    _activityIndicator.hidesWhenStopped = YES;
    [_contentView addSubview:_activityIndicator];
    [_activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(_imag2View);
    }];
    
    _sandboxButton = [[UIButton alloc] init];
    [_sandboxButton setTitle:@"sandBox" forState:UIControlStateNormal];
    [_sandboxButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_sandboxButton addTarget:self action:@selector(sandboxBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_sandboxButton];
    [_sandboxButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_contentView);
        make.bottom.equalTo(_contentView);
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(100);
    }];
    
    _timeLabel = [[UILabel alloc] init];
    _timeLabel.textColor = [UIColor blackColor];
    _timeLabel.text = @"time:";
    [_contentView addSubview:_timeLabel];
    [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_stack2View.mas_bottom).offset(20);
        make.left.equalTo(_contentView);
    }];
}

- (void)configData {
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.delegate = self;
}

- (void)imageAction {
    _imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}

- (void)videoAction {
    _imagePickerController.mediaTypes = @[(NSString *)kUTTypeMovie];
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}

- (void)deleteAction {
    _deleteButton.hidden = true;
    _saveBtton.hidden = true;
    _imageView.image = nil;
    _imag2View.image = nil;
    _videoURL = nil;
    _imageURL = nil;
    _timeLabel.text = @"time:";
}

- (void)saveAction {
    if (_imageURL) {
        UIImageWriteToSavedPhotosAlbum(_imag2View.image, nil,nil,nil);
        [PWUIToast showToastWithString:@"save photo to album success"];
    }
    if (_videoURL) {
        [self saveVideoToAlbum];
    }
}

- (void)saveVideoToAlbum {
    [self requestPhotoLibraryPermissionsWithCompletion:^(BOOL granted) {
        if (granted) {
            NSString *savePath = [self videoSavePath];
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:savePath]];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                NSLog(@"saveAction %@",error.description);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [PWUIToast showToastWithString:@"save video to album success"];
                    } else {
                        [PWUIToast showToastWithString:@"save video to album error"];
                    }
                });
            }];
        } else {
            NSLog(@"没有权限访问照片库");
            [PWUIToast showToastWithString:@"no access album permission"];
        }
    }];
}

- (void)enhanceAction {
    if (!_imageView.image) {
        return;
    }
    double startTime = [NSDate date].timeIntervalSince1970;
    if (_videoURL) {
        _enhanceButton.enabled = false;
        [_activityIndicator startAnimating];
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
        dispatch_after(delay, dispatch_get_main_queue(), ^{
            [self enhanceVdieo];
            [self updaetTime:startTime];
        });
    } else {
        [self enhanceImage];
        [self updaetTime:startTime];
    }
}

- (void)updaetTime:(double)startTime {
    double time = [NSDate date].timeIntervalSince1970 - startTime;
    _timeLabel.text = [NSString stringWithFormat:@"time: %.2f seconds",time];
}

- (void)enhanceVdieo {
    NSString *filePath = [self videoPath];
    NSString *savePath = [self videoSavePath];
//    NSString *model= @"reseffnet_gan_div12_core_model.ncnn";
    NSString *model= @"convnext_tiny_div12.ncnn";
//    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"convnext_tiny_llie" ofType:@"onnx"];
    //CHANGE HERE
    NSString *paramPath = [[NSBundle mainBundle] pathForResource:model ofType:@"param"];
    NSString *binPath = [[NSBundle mainBundle] pathForResource:model ofType:@"bin"];
    
    AIBox::InferOptions opt = {};
    AIBox::InferStatistic otx = {};
    std::string imageString([filePath UTF8String]);
//    std::string modeString([modelPath UTF8String]);
    //CHANGE HERE
    std::string modeStringParam([paramPath UTF8String]);
    std::string modeStringBin([binPath UTF8String]);
   
    std::string saveImageString([savePath UTF8String]);
//    int result = AIBox::imageRestore(modeString, imageString, saveImageString, opt, otx);
    //CHANGE HERE
    int result = AIBox::imageRestore(modeStringParam,modeStringBin, imageString, saveImageString, opt, otx);
    if (result == 0) {
        _imag2View.image = [self generateThumbnailForVideoAtURL:[NSURL fileURLWithPath:savePath]];
        _saveBtton.hidden = false;
    }
    _enhanceButton.enabled = true;
    [_activityIndicator stopAnimating];
    NSLog(@"AIBox enhanceVdieo :%d",result);
}

- (void)enhanceImage {
    NSString *filePath = [self imagePath] ;
    NSString *savePath = [self imageSavePath];
//    NSString *model= @"reseffnet_gan_div12_core_model.ncnn";
    NSString *model= @"convnext_tiny_div12.ncnn";
    
//    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"convnext_tiny_llie" ofType:@"onnx"];
    /// CHANGE HERE
    NSString *paramPath = [[NSBundle mainBundle] pathForResource:model ofType:@"param"];
    NSString *binPath = [[NSBundle mainBundle] pathForResource:model ofType:@"bin"];

    AIBox::InferOptions opt = {};
    AIBox::InferStatistic otx = {};
    std::string imageString([filePath UTF8String]);
    
//    std::string modeString([modelPath UTF8String]);
    std::string modeStringParam([paramPath UTF8String]);
    std::string modeStringBin([binPath UTF8String]);
    
    std::string saveImageString([savePath UTF8String]);
    
    // CHANGE HERE
    int result = AIBox::imageRestore(modeStringParam,modeStringBin, imageString, saveImageString, opt, otx);
    
    if (result == 0) {
        _imag2View.image = [UIImage imageWithContentsOfFile:savePath];
        _saveBtton.hidden = false;
    }
    NSLog(@"AIBox enhanceImage :%d",result);
}

- (void)tapAction:(UITapGestureRecognizer * )tap {
    if (_videoURL) {
        NSString *fileName = nil;
        if (tap.view == _imageView) {
            fileName = [self videoPath];
        }
        if (tap.view == _imag2View) {
            fileName = [self videoSavePath];
        }
        if (fileName) {
            NSURL *url = [NSURL fileURLWithPath:fileName];
            [self avplay:url];
        }
    }
    if (_imageURL) {
        UIImage *image = nil;
        if (tap.view == _imageView) {
            image = _imageView.image;
        }
        if (tap.view == _imag2View) {
            image = _imag2View.image;
        }
        if (image) {
            PWPotoVC *vc = [[PWPotoVC alloc] init];
            vc.image = image;
            vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
            [self presentViewController:vc animated:false completion:nil];
        }
    }
}

- (void)sandboxBtnAction {
    [[FLEXManager sharedManager] showExplorer];
}

- (void)avplay:(NSURL *)url {
    AVPlayer * player = [AVPlayer playerWithURL:url];
    AVPlayerViewController * playerViewController = [[AVPlayerViewController alloc]init];
    playerViewController.player = player;
    playerViewController.exitsFullScreenWhenPlaybackEnds = TRUE;
    [self presentViewController:playerViewController animated:YES completion:nil];
    [playerViewController.player play];
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self deleteAction];
    NSString * mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        NSURL *url = info[UIImagePickerControllerImageURL];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:data];
//        image = [self scaleImage:image Tosize:CGSizeMake(600, 600)];
        
        self.imageURL = url;
        self.videoURL = nil;
        if (image) {
            NSString *filePath = [self imagePath];
            NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
            [imageData writeToFile:filePath atomically:YES];
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = image;
                    self.deleteButton.hidden = false;
                });
            }
        }
    }
    if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *url = info[UIImagePickerControllerMediaURL];
        self.imageURL = nil;
        self.videoURL = url;
        if (url) {
            NSURL *destinationURL = [NSURL fileURLWithPath:[self videoPath]];
            NSURL *destination2URL = [NSURL fileURLWithPath:[self videoSavePath]];
            NSError *error;
            [[NSFileManager defaultManager] copyItemAtURL:url toURL:destinationURL error:&error];
            [[NSFileManager defaultManager] copyItemAtURL:url toURL:destination2URL error:nil];
            UIImage *image = [self generateThumbnailForVideoAtURL:url];
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = image;
                    self.deleteButton.hidden = false;
                });
            }
        }
    }
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Tool

- (UIImage *)generateThumbnailForVideoAtURL:(NSURL *)videoURL {
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMake(1, 1);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return thumbnail;
}

- (NSString *)imagePath {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:_imageURL.lastPathComponent];
    return filePath;
}

- (NSString *)imageSavePath {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"save_%@",_imageURL.lastPathComponent]];
    return filePath;
}

- (NSString *)videoPath {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:_videoURL.lastPathComponent];
    return filePath;
}

- (NSString *)videoSavePath {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"save_%@",_videoURL.lastPathComponent]];
    return filePath;
}

// 裁剪图片
- (UIImage *)scaleImage:(UIImage *)img Tosize:(CGSize)size {
    /// 当图片尺寸小于要转换的尺寸时 使用图片的
    if(img.size.width < size.width){
        size = img.size;
    }
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    //返回新的改变大小后的图片
    return scaledImage;
}

- (void)requestPhotoLibraryPermissionsWithCompletion:(void (^)(BOOL granted))completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusAuthorized) {
                completion(YES);
            } else {
                completion(NO);
            }
        });
    }];
}

@end
