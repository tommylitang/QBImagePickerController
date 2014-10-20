//
//  QBAlbumsTableViewController.h
//  Fluidmedia
//
//  Created by Julian Villella on 2014-10-06.
//  Copyright (c) 2014 Fluid Media Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "QBAlbumsTableViewController.h"
#import "QBAssetsCollectionViewController.h"

@interface QBImagePickerController : UIViewController

@property (nonatomic, strong, readonly) QBAlbumsTableViewController *albumsController;
@property (nonatomic, strong, readonly) QBAssetsCollectionViewController *selectedAssetsController;

+ (BOOL)isAccessible;
+ (BOOL)cameraIsAccessible;

- (void)provideDestinationViewController:(UIViewController *)destinationViewController;

@end
