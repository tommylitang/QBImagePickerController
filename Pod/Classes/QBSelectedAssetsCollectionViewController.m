//
//  QBSelectedAssetsCollectionViewController.m
//  Fluidmedia
//
//  Created by Julian Villella on 2014-10-06.
//  Copyright (c) 2014 Fluid Media Inc. All rights reserved.
//

#import "QBSelectedAssetsCollectionViewController.h"

@interface QBSelectedAssetsCollectionViewController ()

@end

@implementation QBSelectedAssetsCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // View settings
    self.collectionView.backgroundColor = [UIColor whiteColor];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 0;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

@end
