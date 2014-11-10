//
//  QBAlbumsTableViewController.m
//  Fluidmedia
//
//  Created by Julian Villella on 2014-10-06.
//  Copyright (c) 2014 Fluid Media Inc. All rights reserved.
//

#import "QBImagePickerController.h"
#import "QBAlbumsTableViewController.h"
#import "QBAssetsCollectionViewLayout.h"

@interface QBImagePickerController ()

@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, strong) UISegmentedControl *segmentControl;
@end

@implementation QBImagePickerController

@synthesize albumsController = _albumsController;
@synthesize selectedAssetsController = _selectedAssetsController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupPageView];
    [self setupBottomToolbar];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupNavigationBar];
    
    self.navigationController.navigationBar.translucent = NO;
}

#pragma mark - Segment Control

- (UISegmentedControl *)segmentControl
{
    if(!_segmentControl) {
        _segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Albums", @"Selected"]];
        _segmentControl.selectedSegmentIndex = 0;
        [_segmentControl addTarget:self action:@selector(segmentControlAction:) forControlEvents:UIControlEventValueChanged];
    }
    return _segmentControl;
}

- (void)segmentControlAction:(id)sender
{
    if([sender respondsToSelector:@selector(selectedSegmentIndex)]) {
        NSInteger selectedIndex = [sender selectedSegmentIndex];
        UIPageViewControllerNavigationDirection direction;
        UIViewController *viewController;
        if(selectedIndex == 0) {
            viewController = self.albumsController;
            direction = UIPageViewControllerNavigationDirectionReverse;
        } else {
            viewController = self.selectedAssetsController;
            direction = UIPageViewControllerNavigationDirectionForward;
            [self passAssetsToAssetsControllerAndSelect];
        }

        [self.pageViewController setViewControllers:@[viewController] direction:direction animated:YES completion:nil];
    }
}

#pragma mark - Albums Controller

- (QBAlbumsTableViewController *)albumsController
{
    if(!_albumsController) {
        _albumsController = [[QBAlbumsTableViewController alloc] init];
    }
    return _albumsController;
}

- (void)setDelegate:(id<QBImagePickerControllerDelegate>)delegate
{
    self.albumsController.delegate = delegate;
}

- (id<QBImagePickerControllerDelegate>)delegate
{
    return self.albumsController.delegate;
}

+ (BOOL)isAccessible
{
    return [QBAlbumsTableViewController isAccessible];
}

+ (BOOL)cameraIsAccessible
{
    return [QBAlbumsTableViewController cameraIsAccessible];
}

#pragma mark - Selected Assets Controller

- (QBAssetsCollectionViewController *)selectedAssetsController
{
    if(!_selectedAssetsController) {
        _selectedAssetsController = [[QBAssetsCollectionViewController alloc]
                                     initWithCollectionViewLayout:[QBAssetsCollectionViewLayout layout]];

        _selectedAssetsController.allowsMultipleSelection = YES;
        _selectedAssetsController.filterType = self.albumsController.filterType;
        _selectedAssetsController.minimumNumberOfImageSelection = self.albumsController.minimumNumberOfImageSelection;
        _selectedAssetsController.minimumNumberOfVideoSelection = self.albumsController.minimumNumberOfVideoSelection;
        _selectedAssetsController.maximumNumberOfImageSelection = self.albumsController.maximumNumberOfImageSelection;
        _selectedAssetsController.maximumNumberOfVideoSelection = self.albumsController.maximumNumberOfVideoSelection;
        _selectedAssetsController.delegate = (id<QBAssetsCollectionViewControllerDelegate>)self.albumsController;
    }

    return _selectedAssetsController;
}

- (void)passAssetsToAssetsControllerAndSelect
{
    // Reset then ...
    [self.selectedAssetsController setAlAssets:nil];
    
    // Load assets from URLs
    __block NSMutableArray *assets = [NSMutableArray array];
    for (NSURL *selectedAssetURL in self.albumsController.selectedAssetURLs) {
        __weak typeof(self) weakSelf = self;
        [self.albumsController.assetsLibrary assetForURL:selectedAssetURL resultBlock:^(ALAsset *asset) {
            [assets addObject:asset];
            
            // If load complete
            if (assets.count == weakSelf.albumsController.selectedAssetURLs.count) {
                [weakSelf.selectedAssetsController setAlAssets:assets];
                
                for (NSURL *assetURL in weakSelf.albumsController.selectedAssetURLs) {
                    [weakSelf.selectedAssetsController selectAssetHavingURL:assetURL];
                }
                
            }
        } failureBlock:^(NSError *error) {
            NSLog(@"Error: %@", [error localizedDescription]);
        }];
    }
}

#pragma mark - Bottom Toolbar

- (void)setupBottomToolbar
{
    UIBarButtonItem *flexibleSpace  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                    target:nil action:nil];
    UIBarButtonItem *cameraButton   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                    target:self.albumsController action:@selector(cameraAction:)];
    UIBarButtonItem *segmentControl = [[UIBarButtonItem alloc] initWithCustomView:self.segmentControl];
    
    
    cameraButton.enabled = [QBAlbumsTableViewController cameraIsAccessible];
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setItems:@[flexibleSpace, segmentControl, flexibleSpace, cameraButton]];
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

#pragma mark - Page View Controller

- (void)setupPageView
{
    // Setup page view controller
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
    
    [self.pageViewController setViewControllers:@[self.albumsController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    UIView *pageView = self.pageViewController.view;
    pageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *arrConstraints = @[
        [NSLayoutConstraint constraintWithItem:pageView  attribute:NSLayoutAttributeBottom   relatedBy:NSLayoutRelationEqual
                                        toItem:self.view attribute:NSLayoutAttributeBottom     multiplier:1.0f constant:0.0f],
        [NSLayoutConstraint constraintWithItem:pageView  attribute:NSLayoutAttributeTop      relatedBy:NSLayoutRelationEqual
                                        toItem:self.view attribute:NSLayoutAttributeTop        multiplier:1.0f constant:0.0f],
        [NSLayoutConstraint constraintWithItem:pageView  attribute:NSLayoutAttributeLeading  relatedBy:NSLayoutRelationEqual
                                        toItem:self.view attribute:NSLayoutAttributeLeading    multiplier:1.0f constant:0.0f],
        [NSLayoutConstraint constraintWithItem:pageView  attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                        toItem:self.view attribute:NSLayoutAttributeTrailing   multiplier:1.0f constant:0.0f]
    ];
    [self.view addConstraints:arrConstraints];
}

- (void)setupNavigationBar
{
    self.navigationItem.leftBarButtonItem  = self.albumsController.navigationItem.leftBarButtonItem;
    self.title = self.albumsController.title;
    self.navigationItem.rightBarButtonItem = self.albumsController.navigationItem.rightBarButtonItem;
}

@end
