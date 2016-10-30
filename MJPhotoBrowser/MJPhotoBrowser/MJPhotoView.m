//
//  MJZoomingScrollView.m
//
//  Created by mj on 13-3-4.
//  Copyright (c) 2013年 itcast. All rights reserved.
//

#import "MJPhotoView.h"
#import "MJPhoto.h"
#import "MJPhotoLoadingView.h"
#import <QuartzCore/QuartzCore.h>

#define ESWeak(var, weakVar) __weak __typeof(&*var) weakVar = var
#define ESStrong_DoNotCheckNil(weakVar, _var) __typeof(&*weakVar) _var = weakVar
#define ESStrong(weakVar, _var) ESStrong_DoNotCheckNil(weakVar, _var); if (!_var) return;

#define ESWeak_(var) ESWeak(var, weak_##var);
#define ESStrong_(var) ESStrong(weak_##var, _##var);

/** defines a weak `self` named `__weakSelf` */
#define ESWeakSelf      ESWeak(self, __weakSelf);
/** defines a strong `self` named `_self` from `__weakSelf` */
#define ESStrongSelf    ESStrong(__weakSelf, _self);

@interface MJPhotoView ()
{
    YLImageView *_imageView;
    MJPhotoLoadingView *_photoLoadingView;
}
@property (nonatomic, strong) UIScrollView *scrollView;
@end

@implementation MJPhotoView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        
        UIScrollView *scrollView    = [[UIScrollView alloc] initWithFrame:self.bounds];
        scrollView.backgroundColor  = [UIColor blackColor];
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        scrollView.delegate         = self;
        scrollView.showsHorizontalScrollIndicator   = NO;
        scrollView.showsVerticalScrollIndicator     = NO;
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:scrollView];
        _scrollView = scrollView;
       
		// 图片
		_imageView = [[YLImageView alloc] init];
        _imageView.clipsToBounds = YES;
        _imageView.backgroundColor = [UIColor blackColor];
		_imageView.contentMode = UIViewContentModeScaleAspectFit;
		[scrollView addSubview:_imageView];
        
        // 进度条
        _photoLoadingView = [[MJPhotoLoadingView alloc] init];
		
        // 监听点击
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTap.delaysTouchesBegan = YES;
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        
        [singleTap requireGestureRecognizerToFail:doubleTap];
    }
    return self;
}
- (void)prepareForReuse{
    [super prepareForReuse];
    if (_photoLoadingView) {
        _photoLoadingView.progress = 0;
        if (_photoLoadingView.superview) {
            [_photoLoadingView removeFromSuperview];
        }
    }

}
//设置imageView的图片
- (void)configImageViewWithImage:(UIImage *)image{
    _imageView.image = image;
}

#pragma mark - photoSetter
- (void)setPhoto:(MJPhoto *)photo {
    _photo = photo;
    
    [self showImage];
}

#pragma mark 显示图片
- (void)showImage
{
    [self photoStartLoad];

    [self adjustFrame];
}

#pragma mark 开始加载图片
- (void)photoStartLoad
{
    if (_photo.image) {
        _imageView.image = _photo.image;
    } else {
        _imageView.image = _photo.placeholder;
        // 直接显示进度条
        [_photoLoadingView showLoading];
        [self addSubview:_photoLoadingView];
        
        ESWeakSelf;
        ESWeak_(_photoLoadingView);
        ESWeak_(_imageView);
        ESWeak_(_photo);
        [SDWebImageManager.sharedManager downloadImageWithURL:_photo.url options:SDWebImageRetryFailed| SDWebImageLowPriority| SDWebImageHandleCookies progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            ESStrong_(_photoLoadingView);
            if (receivedSize > kMinProgress) {
                __photoLoadingView.progress = (float)receivedSize/expectedSize;
            }
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if ([weak__photo.url isEqual:imageURL]) {
                ESStrongSelf;
                ESStrong_(_imageView);
                __imageView.image = image;
                [_self photoDidFinishLoadWithImage:image];
            }
        }];
    }
}

#pragma mark 加载完毕
- (void)photoDidFinishLoadWithImage:(UIImage *)image
{
    if (image) {
        _photo.image = image;
        if (_photoLoadingView.superview) {
            [_photoLoadingView removeFromSuperview];
        }
        
        if ([self.photoViewDelegate respondsToSelector:@selector(photoViewImageFinishLoad:)]) {
            [self.photoViewDelegate photoViewImageFinishLoad:self];
        }
    } else {
        if (_photoLoadingView.superview == nil) {
            [self addSubview:_photoLoadingView];
        }
        [_photoLoadingView showFailure];
    }
    
    // 设置缩放比例
    [self adjustFrame];
}
#pragma mark 调整frame
- (void)adjustFrame
{
    if (_imageView.image == nil) return;
    
    // 基本尺寸参数
    CGFloat boundsWidth = self.bounds.size.width;
    CGFloat boundsHeight = self.bounds.size.height;
    CGFloat imageWidth = _imageView.image.size.width;
    CGFloat imageHeight = _imageView.image.size.height;
    
    CGFloat widthScale  = boundsWidth/imageWidth;
    CGFloat heightScale = boundsHeight/imageHeight;
    
    {
        CGFloat scale = MIN(widthScale, heightScale);
        self.scrollView.maximumZoomScale = 1/scale;
        self.scrollView.minimumZoomScale = 1;
        if (self.scrollView.zoomScale != 1.0f) {
            self.scrollView.zoomScale = 1.0f;
        }
        
        imageWidth  = imageWidth*scale;
        imageHeight = imageHeight*scale;
        
        CGRect imageFrame = CGRectMake((boundsWidth - imageWidth)*0.5, (boundsHeight - imageHeight)*0.5, imageWidth, imageHeight);
        self.scrollView.contentSize = CGSizeMake(boundsWidth, boundsHeight);
        _imageView.frame = imageFrame;
    }
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    CGSize boundsSize = self.bounds.size;
    
    CGRect frameToCenter = _imageView.frame;
    
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    _imageView.frame = frameToCenter;
}

#pragma mark - 手势处理
//单击隐藏
- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    // 移除进度条
    if (_photoLoadingView.superview) {
        [_photoLoadingView removeFromSuperview];
    }
    
    // 通知代理
    if ([self.photoViewDelegate respondsToSelector:@selector(photoViewSingleTap:)]) {
        [self.photoViewDelegate photoViewSingleTap:self];
    }
}
//双击放大
- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    if (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) {
        CGPoint touchPoint  = [tap locationInView:_imageView];
        CGRect rectTozoom=[self zoomRectForScale:self.scrollView.maximumZoomScale withCenter:touchPoint];
        [self.scrollView zoomToRect:rectTozoom animated:YES];
    } else {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    }
}
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    zoomRect.size.height = [self frame].size.height / scale;
    zoomRect.size.width  = [self frame].size.width  / scale;
    
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}
- (void)dealloc
{
    // 取消请求
    [_imageView sd_setImageWithURL:[NSURL URLWithString:@"file:///abc"]];
}
@end