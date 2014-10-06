//
//  QBAlbumsTableViewController.m
//  Fluidmedia
//
//  Created by Julian Villella on 2014-10-06.
//  Copyright (c) 2014 Fluid Media Inc. All rights reserved.
//

#import "QBImagePickerController.h"
#import "QBAlbumsTableViewController.h"
#import "QBSelectedAssetsCollectionViewController.h"

static const NSInteger NUM_PAGES = 2;

@interface QBImagePickerController () <UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (nonatomic, strong) QBAlbumsTableViewController *albumsController;
@property (nonatomic, strong) QBSelectedAssetsCollectionViewController *selectedAssetsController;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, strong) UISegmentedControl *segmentControl;

@end

@implementation QBImagePickerController

- (instancetype)init
{
    self = [super init];
    if(self) {
        [self setupBottomToolbar];
        [self setupPageView];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Segment Control

- (UISegmentedControl *)segmentControl
{
    if(!_segmentControl) {
        _segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Albums", @"Selected"]];
        [_segmentControl setEnabled:YES forSegmentAtIndex:0];
        [_segmentControl addTarget:self action:@selector(segmentControlAction:) forControlEvents:UIControlEventValueChanged];
    }
    return _segmentControl;
}

- (void)segmentControlAction:(id)sender
{
    if([sender respondsToSelector:@selector(selectedSegmentIndex)]) {
        UIViewController *viewController = [self viewControllerAtIndex:[sender selectedSegmentIndex]];
        [self.pageViewController setViewControllers:@[viewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
}

#pragma mark - Bottom Toolbar

- (void)setupBottomToolbar
{
    UIBarButtonItem *flexibleSpace  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *cameraButton   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraAction:)];
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
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    self.view.gestureRecognizers = self.pageViewController.view.gestureRecognizers;
    
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

@end
