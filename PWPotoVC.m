//
//  PWPotoVC.m
//  HomeV
//
//  Created by mike on 2023/12/28.
//  Copyright © 2023 PUWELL. All rights reserved.
//

#import "PWPotoVC.h"
#import <Photos/Photos.h>
#import <Masonry/Masonry.h>
#import "PWUIToast.h"

@interface PWPotoVC () <UIScrollViewDelegate>

@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UIButton *saveButton;
@property(nonatomic, strong) UIButton *closeButton;
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIImageView *imageView;

@end

@implementation PWPotoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configView];
    [self configData];
}

- (void)configView {
    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
    [self.view addSubview:_contentView];
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.multipleTouchEnabled = YES;
    _scrollView.maximumZoomScale = 4.8f;
    _scrollView.minimumZoomScale = 1.0f;
    _scrollView.zoomScale = 1.0f;
    _scrollView.delegate = self;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:_scrollView];
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_scrollView addSubview:_imageView];
    
    _saveButton = [[UIButton alloc] init];
    [_saveButton setImage:[UIImage imageNamed:@"cloud_download"] forState:UIControlStateNormal];
    [_saveButton addTarget:self action:@selector(saveAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_saveButton];
    [_saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(45);
        make.width.mas_equalTo(45);
    }];
    
    _closeButton = [[UIButton alloc] init];
    [_closeButton setImage:[UIImage imageNamed:@"close_24"] forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_closeButton];
    [_closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.right.equalTo(self.view);
        make.height.mas_equalTo(64);
        make.width.mas_equalTo(64);
    }];
}

- (void)configData {
    _imageView.image = _image;
    double rate = _image.size.width/_image.size.height;
    double height = self.view.bounds.size.width/rate;
    _imageView.bounds = CGRectMake(0, 0, self.view.bounds.size.width, height);
    _imageView.center = self.view.center;
    _scrollView.contentSize = self.view.bounds.size;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.view addGestureRecognizer:tap];
}

- (void)closeAction {
    [self dismissViewControllerAnimated:false completion:nil];
}

- (void)saveAction {
    UIImageWriteToSavedPhotosAlbum(self.image, nil,nil,nil);
    [PWUIToast showToastWithString:@"save photo to album success"];
}

- (void)tapAction:(UITapGestureRecognizer * )tap {
    [self closeAction];
}

#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGRect imageViewFrame = _imageView.frame;
    CGFloat width = imageViewFrame.size.width,
    height = imageViewFrame.size.height,
    sHeight = scrollView.bounds.size.height,
    sWidth = scrollView.bounds.size.width;
    if (height > sHeight) {
        imageViewFrame.origin.y = 0;
    } else {
        imageViewFrame.origin.y = (sHeight - height) / 2.0;
    }
    if (width > sWidth) {
        imageViewFrame.origin.x = 0;
    } else {
        imageViewFrame.origin.x = (sWidth - width) / 2.0;
    }
    _imageView.frame = imageViewFrame;
}

@end
