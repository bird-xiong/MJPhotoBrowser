//
//  MJPhotoBrowser.m
//
//  Created by mj on 13-3-4.
//  Copyright (c) 2013年 itcast. All rights reserved.

#import "MJPhotoBrowser.h"
#import "MJPhoto.h"
#import "MJPhotoView.h"
#import "MJPhotoToolbar.h"
#import <SDWebImage/SDWebImagePrefetcher.h>
#import "CollectionViewCell.h"
#import <Masonry.h>
#define kPadding 10

@interface MJPhotoBrowser () <MJPhotoViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>
@property (nonatomic, strong) NSMutableArray *reusableCells;
@property (strong, nonatomic) MJPhotoToolbar *toolbar;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *collectionViewLayout;
@property (nonatomic, assign) NSInteger previousPage;
@property (nonatomic, assign) NSInteger firstLoad;
@end

static NSString *const ReusableLeftCellIdentifier   = @"ReusableLeftCellIdentifier";
static NSString *const ReusableMidIdentifier        = @"ReusableMidIdentifier";
static NSString *const ReusableRightIdentifier      = @"ReusableRightIdentifier";

@implementation MJPhotoBrowser

#pragma mark - init M

- (instancetype)init
{
    self = [super init];
    if (self) {
        _previousPage = -1;
        
        self.reusableCells  = [NSMutableArray array];
    }
    return self;
}
- (void)viewDidLoad{
    [super viewDidLoad];
    [self setupViews];
}
- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if (_firstLoad <=1) {
          NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_currentPhotoIndex inSection:0];
          [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
      }
    _firstLoad ++;
}
#pragma mark -
- (void)setupViews{
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    UICollectionViewFlowLayout *layout  = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection              = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing           = kPadding;
    
    UICollectionView *collectionView    = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    collectionView.backgroundColor      = [UIColor whiteColor];
    collectionView.dataSource           = self;
    collectionView.delegate             = self;
    collectionView.pagingEnabled        = YES;
    collectionView.contentInset         = UIEdgeInsetsMake(0, 0, 0, kPadding);
    [self.view addSubview:collectionView];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0f) {
        collectionView.prefetchingEnabled = NO;
    }
    
    [collectionView registerClass:[MJPhotoView class] forCellWithReuseIdentifier:ReusableLeftCellIdentifier];
    [collectionView registerClass:[MJPhotoView class] forCellWithReuseIdentifier:ReusableMidIdentifier];
    [collectionView registerClass:[MJPhotoView class] forCellWithReuseIdentifier:ReusableRightIdentifier];
    
    [collectionView mas_makeConstraints:^(MASConstraintMaker *make){
        make.top.equalTo(self.view);
        make.left.equalTo(self.view);
        make.width.equalTo(self.view).offset(kPadding);
        make.height.equalTo(self.view);
    }];
    self.collectionView         = collectionView;
    self.collectionViewLayout   = layout;
    
    [self.view addSubview:self.toolbar];
}
- (MJPhotoToolbar *)toolbar{
    if (!_toolbar) {
        CGFloat barHeight = 49;
        CGFloat barY = self.view.frame.size.height - barHeight;
        _toolbar = [[MJPhotoToolbar alloc] init];
        _toolbar.frame = CGRectMake(0, barY, self.view.frame.size.width, barHeight);
        _toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    }
    return _toolbar;
}

- (void)show
{
    //初始化数据
    {
        self.toolbar.photos = self.photos;
    }
    
    self.transitioningDelegate = self;
    [[self topPresentedViewController] presentViewController:self animated:YES completion:^{
        
    }];
}

#pragma mark - set M
- (void)setPhotos:(NSArray *)photos
{
    _photos = photos;
    if (_photos.count <= 0) {
        return;
    }
    for (int i = 0; i<_photos.count; i++) {
        MJPhoto *photo = _photos[i];
        photo.index = i;
    }
}

- (void)setCurrentPhotoIndex:(NSUInteger)currentPhotoIndex
{
    _currentPhotoIndex = currentPhotoIndex;
}

#pragma mark - MJPhotoViewDelegate
- (void)photoViewSingleTap:(MJPhotoView *)photoView
{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)photoViewImageFinishLoad:(MJPhotoView *)photoView
{
 
}

#pragma mark - UIScrollView Delegate
- (void)getNearByPrepareReuseAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *identifiers = @[ReusableLeftCellIdentifier,ReusableMidIdentifier,ReusableRightIdentifier];
    NSInteger tag = indexPath.item%3;
    
    NSString *identifier = identifiers[tag];
    NSString *left  = ReusableLeftCellIdentifier;
    NSString *right = ReusableRightIdentifier;
    if ([identifier isEqual:ReusableLeftCellIdentifier]) {
        left = ReusableRightIdentifier;
        right= ReusableMidIdentifier;
    }
    if ([identifier isEqual:ReusableRightIdentifier]) {
        left = ReusableMidIdentifier;
        right= ReusableLeftCellIdentifier;
    }
    
    MJPhotoView *leftCell   = [self findReuseCellAtForIdentifier:left];
    MJPhotoView *rightCell  = [self findReuseCellAtForIdentifier:right];
    
    if (indexPath.item > 0) {
        MJPhoto *photo = _photos[indexPath.item-1];
        if (leftCell != nil) {
            leftCell.photo = photo;
        }
        else{
            [self loadUnReuseCellPhotoImage:photo];
        }
    }
    
    if (indexPath.item < _photos.count-1) {
        MJPhoto *photo = _photos[indexPath.item+1];
        if (rightCell != nil) {
            rightCell.photo = photo;
        }
        else{
            [self loadUnReuseCellPhotoImage:photo];
        }
    }
}
- (MJPhotoView *)findReuseCellAtForIdentifier:(NSString *)identifier{
    __block MJPhotoView *cell = nil;
    [_reusableCells enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([((UICollectionViewCell *)obj).reuseIdentifier isEqualToString:identifier]) {
            cell = obj;
            *stop = YES;
        }
    }];
    return cell;
}
- (void)loadUnReuseCellPhotoImage:(MJPhoto *)photo{
    [[SDWebImageManager sharedManager] downloadImageWithURL:photo.url options:SDWebImageRetryFailed|SDWebImageLowPriority progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        //do nothing
    }];
}
#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photos.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MJPhoto *photo = _photos[indexPath.item];
    NSArray *identifiers = @[ReusableLeftCellIdentifier,ReusableMidIdentifier,ReusableRightIdentifier];
    MJPhotoView *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifiers[indexPath.item %3] forIndexPath:indexPath];
    cell.photo              = photo;
    cell.photoViewDelegate  = self;
    
    if (![_reusableCells containsObject:cell]) {
        [_reusableCells addObject:cell];
    }
    
    [self getNearByPrepareReuseAtIndexPath:indexPath];
    
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
}
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    NSInteger page  = (int)scrollView.contentOffset.x/(int)_collectionView.frame.size.width;
    NSInteger delx  = (int)scrollView.contentOffset.x%(int)_collectionView.frame.size.width;
    
    if (delx > _collectionView.frame.size.width *0.5f) {
        page ++;
    }
    if (_previousPage != page && page < _photos.count) {
        _previousPage = page;
        _toolbar.currentPhotoIndex = page;
        _currentPhotoIndex = page;
    }
}
#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.view.bounds.size;
}
#pragma mark -
- (UIViewController *)topPresentedViewController{
    UIViewController *ctr   = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *next  = ctr.presentedViewController;
    while (next != nil && !next.isBeingDismissed) {
        ctr     = next;
        next    = ctr.presentedViewController;
    }
    return ctr;
}
#pragma mark - UIViewControllerTransitioningDelegate method
- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return self;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return self;
}
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext{
    MJPhoto *photo = _photos[_currentPhotoIndex];
    //not exist srcImageView will get no animating
    if (!photo.srcImageView) {
        [transitionContext completeTransition:YES];
        return;
    }
    
    UIViewController *toViewController      = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController    = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:toViewController.view];
    toViewController.view.alpha = 0;
    
    UIView *backgroudView = [[UIView alloc] initWithFrame:containerView.bounds];
    backgroudView.backgroundColor = [UIColor blackColor];
    [containerView addSubview:backgroudView];
    
    UIImage *image = photo.image;
    if (image == nil && photo.placeholder) {
        image = photo.placeholder;
    }
    
    //origin rect
    CGRect orginRect    = [photo.srcImageView.superview convertRect:photo.srcImageView.frame toView:containerView];
    //finial rect
    CGFloat scale       = MIN(containerView.bounds.size.width/image.size.width, containerView.bounds.size.height/image.size.height);
    CGFloat imageWidth  = image.size.width*scale;
    CGFloat imageHeight = image.size.height*scale;
    CGRect finialRect   = CGRectMake((containerView.bounds.size.width - imageWidth)*0.5, (containerView.bounds.size.height - imageHeight)*0.5, imageWidth, imageHeight);
    
    UIImageView *animatingImageView = [[UIImageView alloc] initWithImage:image];
    animatingImageView.contentMode  = UIViewContentModeScaleAspectFit;
    [containerView addSubview:animatingImageView];
    [containerView setBackgroundColor:[UIColor clearColor]];
    //present
    if ([toViewController isEqual:self]) {
        animatingImageView.frame = orginRect;
        photo.srcImageView.hidden = YES;
        backgroudView.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
            animatingImageView.frame = finialRect;
            backgroudView.alpha = 1;
        } completion:^(BOOL finished) {
             photo.srcImageView.hidden = NO;
            toViewController.view.alpha = 1;
            [animatingImageView removeFromSuperview];
            [backgroudView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }
    //dismiss
    else if([fromViewController isEqual:self]){
        toViewController.view.alpha = 1;
        fromViewController.view.hidden  = YES;
        animatingImageView.frame        = finialRect;
        backgroudView.alpha = 1;
        photo.srcImageView.hidden = YES;
        [UIView animateWithDuration:0.3 animations:^{
            animatingImageView.frame = orginRect;
            backgroudView.alpha = 0;
        } completion:^(BOOL finished) {
            photo.srcImageView.hidden = NO;
            [animatingImageView removeFromSuperview];
            [backgroudView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }
}
- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext{
    return 0.3;
}
@end
