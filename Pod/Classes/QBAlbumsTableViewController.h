//
//  QBImagePickerController.h
//  QBImagePickerController
//
//  Created by Tanaka Katsuma on 2013/12/30.
//  Copyright (c) 2013 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef NS_ENUM(NSUInteger, QBImagePickerControllerFilterType) {
    QBImagePickerControllerFilterTypeNone,
    QBImagePickerControllerFilterTypePhotos,
    QBImagePickerControllerFilterTypeVideos
};

UIKIT_EXTERN ALAssetsFilter *ALAssetsFilterFromQBImagePickerControllerFilterType(QBImagePickerControllerFilterType type);

@class QBAlbumsTableViewController;

@protocol QBImagePickerControllerDelegate <NSObject>

@optional
- (void)qb_imagePickerController:(QBAlbumsTableViewController *)imagePickerController didSelectAsset:(ALAsset *)asset;
- (void)qb_imagePickerController:(QBAlbumsTableViewController *)imagePickerController didSelectAssets:(NSArray *)assets;
- (void)qb_imagePickerControllerDidCancel:(QBAlbumsTableViewController *)imagePickerController;

@end

@interface QBAlbumsTableViewController : UITableViewController

@property (nonatomic, strong, readonly) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, assign) BOOL showsPhotostream;
@property (nonatomic, copy,   readonly) NSArray *assetsGroups;
@property (nonatomic, strong, readonly) NSMutableOrderedSet *selectedAssetURLs;
@property (nonatomic, assign) NSUInteger numberOfSelectedImages;
@property (nonatomic, assign) NSUInteger numberOfSelectedVideos;

@property (nonatomic, weak) id<QBImagePickerControllerDelegate> delegate;
@property (nonatomic, copy) NSArray *groupTypes;
@property (nonatomic, assign) QBImagePickerControllerFilterType filterType;
@property (nonatomic, assign) BOOL showsCancelButton;
@property (nonatomic, assign) BOOL allowsMultipleSelection;
//@property (nonatomic, assign) NSUInteger minimumNumberOfSelection;
@property (nonatomic, assign) NSUInteger minimumNumberOfImageSelection;
@property (nonatomic, assign) NSUInteger minimumNumberOfVideoSelection;
//@property (nonatomic, assign) NSUInteger maximumNumberOfSelection;
@property (nonatomic, assign) NSUInteger maximumNumberOfImageSelection;
@property (nonatomic, assign) NSUInteger maximumNumberOfVideoSelection;
@property (nonatomic, assign) NSString *rightNavigationItemTitle;

+ (BOOL)isAccessible;
+ (BOOL)cameraIsAccessible;

@end
