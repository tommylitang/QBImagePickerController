//
//  ViewController.m
//  QBImagePickerControllerDemo
//
//  Created by Tanaka Katsuma on 2013/12/30.
//  Copyright (c) 2013年 Katsuma Tanaka. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (![QBImagePickerController isAccessible]) {
        NSLog(@"Error: Source is not accessible.");
    }
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QBImagePickerController *imagePickerController = [[QBImagePickerController alloc] init];
    imagePickerController.albumsController.delegate = self;
    imagePickerController.albumsController.allowsMultipleSelection = (indexPath.section == 1);
    
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 1:
                imagePickerController.albumsController.minimumNumberOfImageSelection = 3;
                imagePickerController.albumsController.minimumNumberOfVideoSelection = 2;
                break;
                
            case 2:
                imagePickerController.albumsController.maximumNumberOfImageSelection = 6;
                imagePickerController.albumsController.maximumNumberOfVideoSelection = 8;
                break;
                
            case 3:
                imagePickerController.albumsController.minimumNumberOfImageSelection = 1;
                imagePickerController.albumsController.minimumNumberOfVideoSelection = 1;
                imagePickerController.albumsController.maximumNumberOfImageSelection = 3;
                imagePickerController.albumsController.maximumNumberOfVideoSelection = 3;
                break;
                
            default:
                break;
        }
    }
    
    if (indexPath.section == 0 && indexPath.row == 1) {
        [self.navigationController pushViewController:imagePickerController animated:YES];
    } else {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
        [self presentViewController:navigationController animated:YES completion:NULL];
    }
}

- (void)dismissImagePickerController
{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [self.navigationController popToViewController:self animated:YES];
    }
}


#pragma mark - QBImagePickerControllerDelegate

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAsset:(ALAsset *)asset
{
    NSLog(@"*** qb_imagePickerController:didSelectAsset:");
    NSLog(@"%@", asset);
    
    [self dismissImagePickerController];
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAssets:(NSArray *)assets
{
    NSLog(@"*** qb_imagePickerController:didSelectAssets:");
    NSLog(@"%@", assets);
    
    [self dismissImagePickerController];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    NSLog(@"*** qb_imagePickerControllerDidCancel:");
    
    [self dismissImagePickerController];
}

@end
