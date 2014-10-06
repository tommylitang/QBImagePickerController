//
//  QBImagePickerController.m
//  QBImagePickerController
//
//  Created by Tanaka Katsuma on 2013/12/30.
//  Copyright (c) 2013 Katsuma Tanaka. All rights reserved.
//

#import "QBImagePickerController.h"
#import <AssetsLibrary/AssetsLibrary.h>

// Views
#import "QBImagePickerGroupCell.h"
#import "QBAssetsCollectionViewLayout.h"

// ViewControllers
#import "QBAssetsCollectionViewController.h"

ALAssetsFilter* ALAssetsFilterFromQBImagePickerControllerFilterType(QBImagePickerControllerFilterType type) {
    switch (type) {
        case QBImagePickerControllerFilterTypeNone:
            return [ALAssetsFilter allAssets];
            break;
            
        case QBImagePickerControllerFilterTypePhotos:
            return [ALAssetsFilter allPhotos];
            break;
            
        case QBImagePickerControllerFilterTypeVideos:
            return [ALAssetsFilter allVideos];
            break;
    }
}

static const NSInteger NUM_PAGES = 2;

@interface QBImagePickerController () <QBAssetsCollectionViewControllerDelegate,
    UIImagePickerControllerDelegate, UINavigationControllerDelegate, // For camera
    UICollectionViewDelegate, UICollectionViewDataSource,            // For selected assets collection view
    UIPageViewControllerDelegate, UIPageViewControllerDataSource>    // For page view controller

@property (nonatomic, strong) UITableView *albumsTableView;
@property (nonatomic, strong) UICollectionView *selectedAssetsCollectionView;

@property (nonatomic, strong) UISegmentedControl *segmentControl;
@property (nonatomic, strong, readwrite) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, copy, readwrite) NSArray *assetsGroups;
@property (nonatomic, strong, readwrite) NSMutableOrderedSet *selectedAssetURLs;

@end

@implementation QBImagePickerController

+ (BOOL)isAccessible
{
    return ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] &&
            [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]);
}

+ (BOOL)cameraIsAccessible
{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (instancetype)init
{
    self = [super init];
    if(self) {
        [self setupAlbumsTableView];
        [self setupSelectedAssetsCollectionView];
        [self setupProperties];
        [self setupBottomToolbar];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupProperties];
}

- (void)setupAlbumsTableView
{
    self.albumsTableView = [[UITableView alloc] init];
    self.albumsTableView.delegate = self;
    self.albumsTableView.dataSource = self;
//    [self.view addSubview:self.albumsTableView];
    
//    self.albumsTableView.translatesAutoresizingMaskIntoConstraints = NO;
//    NSArray *arrConstraints = @[
//                               [NSLayoutConstraint constraintWithItem:self.albumsTableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
//                                                               toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f],
//                               [NSLayoutConstraint constraintWithItem:self.albumsTableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
//                                                               toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f],
//                               [NSLayoutConstraint constraintWithItem:self.albumsTableView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
//                                                               toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f],
//                               [NSLayoutConstraint constraintWithItem:self.albumsTableView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
//                                                               toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f]];
//    [self.view addConstraints:arrConstraints];
}

- (void)setupSelectedAssetsCollectionView
{
    self.selectedAssetsCollectionView = [[UICollectionView alloc] init];
    self.selectedAssetsCollectionView.delegate = self;
    self.selectedAssetsCollectionView.dataSource = self;
}

- (void)setupProperties
{
    // Property settings
    self.selectedAssetURLs = [NSMutableOrderedSet orderedSet];
    
    self.groupTypes = @[
                        @(ALAssetsGroupSavedPhotos),
                        @(ALAssetsGroupPhotoStream),
                        @(ALAssetsGroupAlbum)
                        ];
    self.filterType = QBImagePickerControllerFilterTypeNone;
    self.showsCancelButton = YES;
    
    // View settings
    self.albumsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Create assets library instance
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    self.assetsLibrary = assetsLibrary;
    
    // Register cell classes
    [self.albumsTableView registerClass:[QBImagePickerGroupCell class] forCellReuseIdentifier:@"GroupCell"];
}

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
//        [sender selectedSegmentIndex]
#warning Implement me
    }
}

- (void)setupBottomToolbar
{
    UIBarButtonItem *flexibleSpace  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *cameraButton   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraAction:)];
    UIBarButtonItem *segmentControl = [[UIBarButtonItem alloc] initWithCustomView:self.segmentControl];

    
    cameraButton.enabled = [QBImagePickerController cameraIsAccessible];

    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setItems:@[flexibleSpace, segmentControl, flexibleSpace, cameraButton]];
    [self.view addSubview:toolbar];
    
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *arrConstraints = @[
                               [NSLayoutConstraint constraintWithItem:toolbar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
                                                               toItem:self.view attribute:NSLayoutAttributeBottom  multiplier:1.0f constant:0.0f],
                               [NSLayoutConstraint constraintWithItem:toolbar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                                               toItem:self.view attribute:NSLayoutAttributeBottom  multiplier:1.0f constant:-44.0f],
                               [NSLayoutConstraint constraintWithItem:toolbar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                               toItem:self.view attribute:NSLayoutAttributeWidth   multiplier:1.0f constant:0.0f],
                               [NSLayoutConstraint constraintWithItem:toolbar attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
                                                               toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [self.view addConstraints:arrConstraints];
    [self.view bringSubviewToFront:toolbar];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // View controller settings
    self.title = NSLocalizedStringFromTable(@"title", @"QBImagePickerController", nil);
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Load assets groups
    [self loadAssetsGroupsWithTypes:self.groupTypes
                         completion:^(NSArray *assetsGroups) {
                             self.assetsGroups = assetsGroups;
                             
                             [self.albumsTableView reloadData];
                         }];
    
    // Validation
    self.navigationItem.rightBarButtonItem.enabled = [self validateNumberOfSelections:self.selectedAssetURLs.count];
}

#pragma mark - Page View Controller

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
        return self.albumsTableView;
    }
    return nil;
}

#pragma mark - Accessors

- (void)setShowsCancelButton:(BOOL)showsCancelButton
{
    _showsCancelButton = showsCancelButton;
    
    // Show/hide cancel button
    if (showsCancelButton) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        [self.navigationItem setLeftBarButtonItem:cancelButton animated:NO];
    } else {
        [self.navigationItem setLeftBarButtonItem:nil animated:NO];
    }
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    _allowsMultipleSelection = allowsMultipleSelection;
    
    // Show/hide done button
    if (allowsMultipleSelection) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
        [self.navigationItem setRightBarButtonItem:doneButton animated:NO];
    } else {
        [self.navigationItem setRightBarButtonItem:nil animated:NO];
    }
}


#pragma mark - Actions

- (void)done:(id)sender
{
    [self passSelectedAssetsToDelegate];
}

- (void)cancel:(id)sender
{
    // Delegate
    if (self.imagePickerDelegate && [self.imagePickerDelegate respondsToSelector:@selector(qb_imagePickerControllerDidCancel:)]) {
		[self.imagePickerDelegate qb_imagePickerControllerDidCancel:self];
    }
}

- (void)cameraAction:(id)sender
{
    NSLog(@"Opening Camera");
    
    UIImagePickerController *cameraPicker = [[UIImagePickerController alloc] init];
    cameraPicker.allowsEditing = YES;
    cameraPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    cameraPicker.modalPresentationStyle = UIModalPresentationFullScreen;
    cameraPicker.showsCameraControls = YES;
    cameraPicker.delegate = self;
    
    [self presentViewController:cameraPicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"Camera took image");
    [self.assetsLibrary writeImageToSavedPhotosAlbum:((UIImage*)[info objectForKey:UIImagePickerControllerEditedImage]).CGImage
                                            metadata:[info objectForKey:UIImagePickerControllerMediaMetadata]
                                     completionBlock:^(NSURL *assetURL, NSError *error)
    {
        if(!error) {
            [self.selectedAssetURLs addObject:assetURL];
            [self passSelectedAssetsToDelegate];
        }
    }];
}

#pragma mark - Validating Selections

- (BOOL)validateNumberOfSelections:(NSUInteger)numberOfSelections
{
    // Check the number of selected assets
    NSUInteger minimumNumberOfSelection = MAX(1, self.minimumNumberOfSelection);
    BOOL qualifiesMinimumNumberOfSelection = (numberOfSelections >= minimumNumberOfSelection);
    
    BOOL qualifiesMaximumNumberOfSelection = YES;
    if (minimumNumberOfSelection <= self.maximumNumberOfSelection) {
        qualifiesMaximumNumberOfSelection = (numberOfSelections <= self.maximumNumberOfSelection);
    }
    
    return (qualifiesMinimumNumberOfSelection && qualifiesMaximumNumberOfSelection);
}


#pragma mark - Managing Assets

- (void)loadAssetsGroupsWithTypes:(NSArray *)types completion:(void (^)(NSArray *assetsGroups))completion
{
    __block NSMutableArray *assetsGroups = [NSMutableArray array];
    __block NSUInteger numberOfFinishedTypes = 0;
    
    for (NSNumber *type in types) {
        __weak typeof(self) weakSelf = self;
        
        [self.assetsLibrary enumerateGroupsWithTypes:[type unsignedIntegerValue]
                                          usingBlock:^(ALAssetsGroup *assetsGroup, BOOL *stop) {
                                              if (assetsGroup) {
                                                  // Filter the assets group
                                                  [assetsGroup setAssetsFilter:ALAssetsFilterFromQBImagePickerControllerFilterType(weakSelf.filterType)];
                                                  
                                                  if (assetsGroup.numberOfAssets > 0) {
                                                      // Add assets group
                                                      [assetsGroups addObject:assetsGroup];
                                                  }
                                              } else {
                                                  numberOfFinishedTypes++;
                                              }
                                              
                                              // Check if the loading finished
                                              if (numberOfFinishedTypes == types.count) {
                                                  // Sort assets groups
                                                  NSArray *sortedAssetsGroups = [self sortAssetsGroups:(NSArray *)assetsGroups typesOrder:types];
                                                  
                                                  // Call completion block
                                                  if (completion) {
                                                      completion(sortedAssetsGroups);
                                                  }
                                              }
                                          } failureBlock:^(NSError *error) {
                                              NSLog(@"Error: %@", [error localizedDescription]);
                                          }];
    }
}

- (NSArray *)sortAssetsGroups:(NSArray *)assetsGroups typesOrder:(NSArray *)typesOrder
{
    NSMutableArray *sortedAssetsGroups = [NSMutableArray array];
    
    for (ALAssetsGroup *assetsGroup in assetsGroups) {
        if (sortedAssetsGroups.count == 0) {
            [sortedAssetsGroups addObject:assetsGroup];
            continue;
        }
        
        ALAssetsGroupType assetsGroupType = [[assetsGroup valueForProperty:ALAssetsGroupPropertyType] unsignedIntegerValue];
        NSUInteger indexOfAssetsGroupType = [typesOrder indexOfObject:@(assetsGroupType)];
        
        for (NSInteger i = 0; i <= sortedAssetsGroups.count; i++) {
            if (i == sortedAssetsGroups.count) {
                [sortedAssetsGroups addObject:assetsGroup];
                break;
            }
            
            ALAssetsGroup *sortedAssetsGroup = sortedAssetsGroups[i];
            ALAssetsGroupType sortedAssetsGroupType = [[sortedAssetsGroup valueForProperty:ALAssetsGroupPropertyType] unsignedIntegerValue];
            NSUInteger indexOfSortedAssetsGroupType = [typesOrder indexOfObject:@(sortedAssetsGroupType)];
            
            if (indexOfAssetsGroupType < indexOfSortedAssetsGroupType) {
                [sortedAssetsGroups insertObject:assetsGroup atIndex:i];
                break;
            }
        }
    }
    
    return [sortedAssetsGroups copy];
}

- (void)passSelectedAssetsToDelegate
{
    // Load assets from URLs
    __block NSMutableArray *assets = [NSMutableArray array];
    
    for (NSURL *selectedAssetURL in self.selectedAssetURLs) {
        __weak typeof(self) weakSelf = self;
        [self.assetsLibrary assetForURL:selectedAssetURL
                            resultBlock:^(ALAsset *asset) {
                                // Add asset
                                [assets addObject:asset];
                                
                                // Check if the loading finished
                                if (assets.count == weakSelf.selectedAssetURLs.count) {
                                    // Delegate
                                    if (self.imagePickerDelegate && [self.imagePickerDelegate respondsToSelector:@selector(qb_imagePickerController:didSelectAssets:)]) {
										[self.imagePickerDelegate qb_imagePickerController:self didSelectAssets:[assets copy]];
                                    }
                                }
                            } failureBlock:^(NSError *error) {
                                NSLog(@"Error: %@", [error localizedDescription]);
                            }];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.assetsGroups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    QBImagePickerGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupCell" forIndexPath:indexPath];
    
    ALAssetsGroup *assetsGroup = self.assetsGroups[indexPath.row];
    cell.assetsGroup = assetsGroup;
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 86.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QBAssetsCollectionViewController *assetsCollectionViewController = [[QBAssetsCollectionViewController alloc] initWithCollectionViewLayout:[QBAssetsCollectionViewLayout layout]];
    assetsCollectionViewController.imagePickerController = self;
    assetsCollectionViewController.filterType = self.filterType;
    assetsCollectionViewController.allowsMultipleSelection = self.allowsMultipleSelection;
    assetsCollectionViewController.minimumNumberOfSelection = self.minimumNumberOfSelection;
    assetsCollectionViewController.maximumNumberOfSelection = self.maximumNumberOfSelection;
    
    ALAssetsGroup *assetsGroup = self.assetsGroups[indexPath.row];
    assetsCollectionViewController.delegate = self;
    assetsCollectionViewController.assetsGroup = assetsGroup;
    
    for (NSURL *assetURL in self.selectedAssetURLs) {
        [assetsCollectionViewController selectAssetHavingURL:assetURL];
    }
    
    [self.navigationController pushViewController:assetsCollectionViewController animated:YES];
}


#pragma mark - QBAssetsCollectionViewControllerDelegate

- (void)assetsCollectionViewController:(QBAssetsCollectionViewController *)assetsCollectionViewController didSelectAsset:(ALAsset *)asset
{
    if (self.allowsMultipleSelection) {
        // Add asset URL
        NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
        [self.selectedAssetURLs addObject:assetURL];
        
        // Validation
        self.navigationItem.rightBarButtonItem.enabled = [self validateNumberOfSelections:self.selectedAssetURLs.count];
    } else {
        // Delegate
        if (self.imagePickerDelegate && [self.imagePickerDelegate respondsToSelector:@selector(qb_imagePickerController:didSelectAsset:)]) {
			[self.imagePickerDelegate qb_imagePickerController:self didSelectAsset:asset];
        }
    }
}

- (void)assetsCollectionViewController:(QBAssetsCollectionViewController *)assetsCollectionViewController didDeselectAsset:(ALAsset *)asset
{
    if (self.allowsMultipleSelection) {
        // Remove asset URL
        NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
        [self.selectedAssetURLs removeObject:assetURL];
        
        // Validation
        self.navigationItem.rightBarButtonItem.enabled = [self validateNumberOfSelections:self.selectedAssetURLs.count];
    }
}

- (void)assetsCollectionViewControllerDidFinishSelection:(QBAssetsCollectionViewController *)assetsCollectionViewController
{
    [self passSelectedAssetsToDelegate];
}

@end
