//
//  CollectionViewController.m
//  MJPhotoBrowser
//
//  Created by Sunnyyoung on 15/5/22.
//  Copyright (c) 2015年 Sunnyyoung. All rights reserved.
//

#import "CollectionViewController.h"
#import "CollectionViewCell.h"
#import "MJPhotoBrowser.h"

static NSString * const reuseIdentifier = @"Cell";

@interface CollectionViewController ()

@property (nonatomic, strong) NSArray *imageURLArray;

@end

@implementation CollectionViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _imageURLArray = @[@"http://pic71.nipic.com/file/20150707/13559303_233732580000_2.jpg",
                           @"http://pic10.nipic.com/20101103/5063545_000227976000_2.jpg",
                           @"http://pic24.nipic.com/20120928/6062547_081856296000_2.jpg",
                           @"http://pic50.nipic.com/file/20141014/8442159_182826708000_2.jpg",
                           @"http://pic14.nipic.com/20110607/6776092_111031284000_2.jpg",
                           @"http://pic4.nipic.com/20090811/1547288_100757007_2.jpg",
                           @"http://pic25.nipic.com/20121203/213291_135120242136_2.jpg",
                           @"http://a0.att.hudong.com/15/08/300218769736132194086202411_950.jpg",
                           @"http://pic27.nipic.com/20130310/4499633_163759170000_2.jpg"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _imageURLArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:_imageURLArray[indexPath.row]]];
    return cell;
}

#pragma mark <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = 0;
    NSMutableArray *photoArray = [NSMutableArray array];
    MJPhotoBrowser *photoBrowser = [[MJPhotoBrowser alloc] init];
    for (NSString *imageURL in _imageURLArray) {
        MJPhoto *photo = ({
            MJPhoto *photo = [[MJPhoto alloc] init];
            photo.url = [NSURL URLWithString:imageURL];
            photo.srcImageView = ((CollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]]).imageView;
            photo;
        });
        row++;
        [photoArray addObject:photo];
    }
    photoBrowser.photos = photoArray;
    photoBrowser.currentPhotoIndex = indexPath.row;
    [photoBrowser show];
}

@end
