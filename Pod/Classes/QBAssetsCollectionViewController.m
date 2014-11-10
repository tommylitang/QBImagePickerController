//
//  QBAssetsCollectionViewController.m
//  QBImagePickerController
//
//  Created by Tanaka Katsuma on 2013/12/31.
//  Copyright (c) 2013年 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetsCollectionViewController.h"

// Views
#import "QBAssetsCollectionViewCell.h"
#import "QBAssetsCollectionFooterView.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <MobileCoreServices/UTType.h>

@interface QBAssetsCollectionViewController ()

@property (nonatomic, strong) NSMutableArray *assets;

@property (nonatomic, assign) NSUInteger numberOfAssets;
@property (nonatomic, assign) NSUInteger numberOfPhotos;
@property (nonatomic, assign) NSUInteger numberOfVideos;

@property (nonatomic, assign) BOOL disableScrollToBottom;

@end

@implementation QBAssetsCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // View settings
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 44.f, 0); // For toolbar
    
    // Register cell class
    [self.collectionView registerClass:[QBAssetsCollectionViewCell class]
            forCellWithReuseIdentifier:@"AssetsCell"];
    [self.collectionView registerClass:[QBAssetsCollectionFooterView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                   withReuseIdentifier:@"FooterView"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Scroll to bottom
    if (self.isMovingToParentViewController && !self.disableScrollToBottom) {
        CGFloat topInset;
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) { // iOS7 or later
            topInset = ((self.edgesForExtendedLayout && UIRectEdgeTop) && (self.collectionView.contentInset.top == 0)) ? (20.0 + 44.0) : 0.0;
        } else {
            topInset = (self.collectionView.contentInset.top == 0) ? (20.0 + 44.0) : 0.0;
        }

        [self.collectionView setContentOffset:CGPointMake(0, self.collectionView.collectionViewLayout.collectionViewContentSize.height - self.collectionView.frame.size.height + topInset)
                                     animated:NO];
    }
    
    // Validation
    if (self.allowsMultipleSelection) {
        self.navigationItem.rightBarButtonItem.enabled = [self validateNumberOfSelectionsWithImageCount:self.imagePickerController.numberOfSelectedImages
                                                                                             videoCount:self.imagePickerController.numberOfSelectedVideos];
        [self.navigationItem.rightBarButtonItem setTitle:self.imagePickerController.rightNavigationItemTitle];
    }
    
    [self setupBottomToolbar];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.disableScrollToBottom = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.disableScrollToBottom = NO;
}

#pragma mark - Bottom Toolbar

- (void)setupBottomToolbar
{
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *clear = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearSelection:)];
    UIBarButtonItem *selectAll = [[UIBarButtonItem alloc] initWithTitle:@"Select All" style:UIBarButtonItemStylePlain target:self action:@selector(selectAll:)];
    
    if(!self.allowsMultipleSelection) {
        clear.enabled     = NO;
        selectAll.enabled = NO;
    }
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setItems:@[clear, flexibleSpace, selectAll]];
    [self.view addSubview:toolbar];
    
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *arrConstraints = @[
        [NSLayoutConstraint constraintWithItem:toolbar   attribute:NSLayoutAttributeBottom  relatedBy:NSLayoutRelationEqual
                                        toItem:self.view attribute:NSLayoutAttributeBottom    multiplier:1.0f constant:0.0f],
        [NSLayoutConstraint constraintWithItem:toolbar   attribute:NSLayoutAttributeTop     relatedBy:NSLayoutRelationEqual
                                        toItem:self.view attribute:NSLayoutAttributeBottom    multiplier:1.0f constant:-44.0f],
        [NSLayoutConstraint constraintWithItem:toolbar   attribute:NSLayoutAttributeWidth   relatedBy:NSLayoutRelationEqual
                                        toItem:self.view attribute:NSLayoutAttributeWidth     multiplier:1.0f constant:0.0f],
        [NSLayoutConstraint constraintWithItem:toolbar   attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
                                        toItem:self.view attribute:NSLayoutAttributeCenterX   multiplier:1.0f constant:0.0f]
    ];
    [self.view addConstraints:arrConstraints];
    [self.view bringSubviewToFront:toolbar];
    
    toolbar.translucent = NO;
}

- (void)clearSelection:(id)sender
{
    for(NSInteger i = 0; i < [self.collectionView numberOfItemsInSection:0]; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        [self collectionView:self.collectionView didDeselectItemAtIndexPath:indexPath]; // Not called automatically
    }
}

- (void)selectAll:(id)sender
{
    for(NSInteger i = 0; i < [self.collectionView numberOfItemsInSection:0]; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
    }
}

#pragma mark - Accessors

- (void)setFilterType:(QBImagePickerControllerFilterType)filterType
{
    _filterType = filterType;
    
    // Set assets filter
    [self.assetsGroup setAssetsFilter:ALAssetsFilterFromQBImagePickerControllerFilterType(self.filterType)];
}

- (void)setAssetsGroup:(ALAssetsGroup *)assetsGroup
{
    _assetsGroup = assetsGroup;
    
    // Set title
    self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
    // Set assets filter
    [self.assetsGroup setAssetsFilter:ALAssetsFilterFromQBImagePickerControllerFilterType(self.filterType)];
    
    // Load assets
    NSMutableArray *assets = [NSMutableArray array];
    __block NSUInteger numberOfAssets = 0;
    __block NSUInteger numberOfPhotos = 0;
    __block NSUInteger numberOfVideos = 0;
    
    [self.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result) {
            numberOfAssets++;
            
            NSString *type = [result valueForProperty:ALAssetPropertyType];
            if ([type isEqualToString:ALAssetTypePhoto]) numberOfPhotos++;
            else if ([type isEqualToString:ALAssetTypeVideo]) numberOfVideos++;
            
            [assets addObject:result];
        }
    }];
    
    self.assets = assets;
    self.numberOfAssets = numberOfAssets;
    self.numberOfPhotos = numberOfPhotos;
    self.numberOfVideos = numberOfVideos;
    
    // Update view
    [self.collectionView reloadData];
}

- (void)setAlAssets:(NSMutableArray *)alAssets
{
    // Load assets
    NSMutableArray *assets = [NSMutableArray array];
    __block NSUInteger numberOfAssets = 0;
    __block NSUInteger numberOfPhotos = 0;
    __block NSUInteger numberOfVideos = 0;
    
    [alAssets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        NSString *type = [asset valueForProperty:ALAssetPropertyType];
        BOOL filtered = [type isEqual:ALAssetsFilterFromQBImagePickerControllerFilterType(self.filterType)];
        
        if (asset && !filtered) {
            numberOfAssets++;
            
            if ([type isEqualToString:ALAssetTypePhoto]) numberOfPhotos++;
            else if ([type isEqualToString:ALAssetTypeVideo]) numberOfVideos++;
            
            [assets addObject:asset];
        }
    }];
    
    self.assets = assets;
    self.numberOfAssets = numberOfAssets;
    self.numberOfPhotos = numberOfPhotos;
    self.numberOfVideos = numberOfVideos;
    
    // Update view
    [self.collectionView reloadData];
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    self.collectionView.allowsMultipleSelection = allowsMultipleSelection;
    
    // Show/hide done button
    if (allowsMultipleSelection) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:self.imagePickerController.rightNavigationItemTitle
            style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
        [self.navigationItem setRightBarButtonItem:doneButton animated:NO];
    } else {
        [self.navigationItem setRightBarButtonItem:nil animated:NO];
    }
}

- (BOOL)allowsMultipleSelection
{
    return self.collectionView.allowsMultipleSelection;
}


#pragma mark - Actions

- (void)done:(id)sender
{
    // Delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(assetsCollectionViewControllerDidFinishSelection:)]) {
        [self.delegate assetsCollectionViewControllerDidFinishSelection:self];
    }
}


#pragma mark - Managing Selection

- (void)selectAssetHavingURL:(NSURL *)URL
{
    for (NSInteger i = 0; i < self.assets.count; i++) {
        ALAsset *asset = self.assets[i];
        NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
        
        if ([assetURL isEqual:URL]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            
            return;
        }
    }
}


#pragma mark - Validating Selections

- (BOOL)validateNumberOfSelectionsWithImageCount:(NSUInteger)imageCount videoCount:(NSUInteger)videoCount
{
    // Check the number of selected assets
    NSUInteger minimumNumberOfImageSelection = MAX(1, self.minimumNumberOfImageSelection);
    NSUInteger minimumNumberOfVideoSelection = MAX(1, self.minimumNumberOfVideoSelection);
    BOOL qualifiesMinimumNumberOfSelection = (imageCount >= minimumNumberOfImageSelection) && (videoCount >= minimumNumberOfVideoSelection);
    
    BOOL qualifiesMaximumNumberOfSelection = YES;
    if (minimumNumberOfImageSelection <= self.maximumNumberOfImageSelection) {
        qualifiesMaximumNumberOfSelection = (imageCount <= self.maximumNumberOfImageSelection);
    }
    if (minimumNumberOfVideoSelection <= self.maximumNumberOfVideoSelection) {
        qualifiesMaximumNumberOfSelection = qualifiesMaximumNumberOfSelection || (videoCount <= self.maximumNumberOfVideoSelection);
    }
    
    return (qualifiesMinimumNumberOfSelection && qualifiesMaximumNumberOfSelection);
}

- (BOOL)validateMaximumNumberOfSelectionsWithImageCount:(NSUInteger)imageCount videoCount:(NSUInteger)videoCount
{
    NSUInteger minimumNumberOfImageSelection = MAX(1, self.minimumNumberOfImageSelection);
    NSUInteger minimumNumberOfVideoSelection = MAX(1, self.minimumNumberOfVideoSelection);
    
    BOOL qualifiesMaximumNumberOfSelection = YES;
    if (minimumNumberOfImageSelection <= self.maximumNumberOfImageSelection) {
        qualifiesMaximumNumberOfSelection = (imageCount <= self.maximumNumberOfImageSelection);
    }
    if (minimumNumberOfVideoSelection <= self.maximumNumberOfVideoSelection) {
        qualifiesMaximumNumberOfSelection = qualifiesMaximumNumberOfSelection && (videoCount <= self.maximumNumberOfVideoSelection);
    }
    
    return qualifiesMaximumNumberOfSelection;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.numberOfAssets;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    QBAssetsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AssetsCell" forIndexPath:indexPath];
    cell.showsOverlayViewWhenSelected = self.allowsMultipleSelection;
    
    ALAsset *asset = self.assets[indexPath.row];
    cell.asset = asset;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return CGSizeMake(collectionView.bounds.size.width, 46.0);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionFooter) {
        QBAssetsCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                      withReuseIdentifier:@"FooterView"
                                                                                             forIndexPath:indexPath];
        
        switch (self.filterType) {
            case QBImagePickerControllerFilterTypeNone:{
                NSString *format;
                if (self.numberOfPhotos == 1) {
                    if (self.numberOfVideos == 1) {
                        format = @"format_photo_and_video";
                    } else {
                        format = @"format_photo_and_videos";
                    }
                } else if (self.numberOfVideos == 1) {
                    format = @"format_photos_and_video";
                } else {
                    format = @"format_photos_and_videos";
                }
                footerView.textLabel.text = [NSString stringWithFormat:NSLocalizedString(format, nil), self.numberOfPhotos, self.numberOfVideos];
                break;
            }
                
            case QBImagePickerControllerFilterTypePhotos:{
                NSString *format = (self.numberOfPhotos == 1) ? @"format_photo" : @"format_photos";
                footerView.textLabel.text = [NSString stringWithFormat:NSLocalizedString(format, nil), self.numberOfPhotos];
                break;
            }
                
            case QBImagePickerControllerFilterTypeVideos:{
                NSString *format = (self.numberOfVideos == 1) ? @"format_video" : @"format_videos";
                footerView.textLabel.text = [NSString stringWithFormat:NSLocalizedString(format, nil), self.numberOfVideos];
                break;
            }
        }
        
        return footerView;
    }
    
    return nil;
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(77.5, 77.5);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(2, 2, 2, 2);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = self.assets[indexPath.row];
    
    BOOL selectedImage = [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]; // Will be YES/NO or NO/YES
    BOOL selectedVideo = [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo];
    
    return [self validateMaximumNumberOfSelectionsWithImageCount:(self.imagePickerController.numberOfSelectedImages + selectedImage)
                                                      videoCount:(self.imagePickerController.numberOfSelectedVideos + selectedVideo)];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = self.assets[indexPath.row];
    
    // Validation
    if (self.allowsMultipleSelection) {
        BOOL selectedImage = [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]; // Will be YES/NO or NO/YES
        BOOL selectedVideo = [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo];
        
        self.navigationItem.rightBarButtonItem.enabled = [self validateNumberOfSelectionsWithImageCount:(self.imagePickerController.numberOfSelectedImages + selectedImage)
                                                                                             videoCount:(self.imagePickerController.numberOfSelectedVideos + selectedVideo)];
    }
    
    // Delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(assetsCollectionViewController:didSelectAsset:)]) {
        [self.delegate assetsCollectionViewController:self didSelectAsset:asset];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = self.assets[indexPath.row];
    
    // Validation
    if (self.allowsMultipleSelection) {
        BOOL selectedImage = [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]; // Will be YES/NO or NO/YES
        BOOL selectedVideo = [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo];
        
        self.navigationItem.rightBarButtonItem.enabled = [self validateNumberOfSelectionsWithImageCount:(self.imagePickerController.numberOfSelectedImages - selectedImage)
                                                                                             videoCount:(self.imagePickerController.numberOfSelectedVideos - selectedVideo)];
    }
    
    // Delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(assetsCollectionViewController:didDeselectAsset:)]) {
        [self.delegate assetsCollectionViewController:self didDeselectAsset:asset];
    }
}

@end
