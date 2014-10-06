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

static const NSInteger NUM_PAGES = 2;

@interface QBImagePickerController ()

@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, strong) UISegmentedControl *segmentControl;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation QBImagePickerController

@synthesize albumsController = _albumsController;
@synthesize selectedAssetsController = _selectedAssetsController;

- (instancetype)init
{
    self = [super init];
    if(self) {
        self.selectedIndex = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupPageView];
    [self setupBottomToolbar];
    [self setupNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
        UIViewController *viewController = [self viewControllerAtIndex:[sender selectedSegmentIndex]];
        UIPageViewControllerNavigationDirection direction = [sender selectedSegmentIndex] > self.selectedIndex
                ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
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
        _selectedAssetsController = [[QBAssetsCollectionViewController alloc] initWithCollectionViewLayout:[QBAssetsCollectionViewLayout layout]];

        
        _selectedAssetsController.allowsMultipleSelection = YES;
        _selectedAssetsController.filterType = self.albumsController.filterType;
//        _selectedAssetsController.imagePickerController = self.albumsController;
        _selectedAssetsController.minimumNumberOfSelection = self.albumsController.minimumNumberOfSelection;
        _selectedAssetsController.maximumNumberOfSelection = self.albumsController.maximumNumberOfSelection;
        _selectedAssetsController.delegate = (id<QBAssetsCollectionViewControllerDelegate>)self.albumsController;
    }

    return _selectedAssetsController;
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

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == NUM_PAGES) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (NSInteger)indexOfViewController:(UIViewController *)viewController {
    if([viewController isKindOfClass:[UITableView class]]) {
        return 0;
    } else if([viewController isKindOfClass:[UICollectionView class]]) {
        return 1;
    }
    return NSNotFound;
}

- (UIViewController *)viewControllerAtIndex:(NSInteger)index {
    if(index == 0) {
        return self.albumsController;
    } else if(index == 1) {
        return self.selectedAssetsController;
    }
    return nil;
}

#pragma mark - Navigation Bar

- (void)setupNavigationBar
{
//    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:nil action:nil];
//    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:nil action:nil];
    self.navigationItem.leftBarButtonItem  = self.albumsController.navigationItem.leftBarButtonItem;
    self.navigationItem.rightBarButtonItem = self.albumsController.navigationItem.rightBarButtonItem;
}

@end
