/*
 * The contents of this file are subject to the terms of the Common Development and
 * Distribution License (the License). You may not use this file except in compliance with the
 * License.
 *
 * You can obtain a copy of the License at legal/CDDLv1.0.txt. See the License for the
 * specific language governing permission and limitations under the License.
 *
 * When distributing Covered Software, include this CDDL Header Notice in each file and include
 * the License file at legal/CDDLv1.0.txt. If applicable, add the following below the CDDL
 * Header, with the fields enclosed by brackets [] replaced by your own identifying
 * information: "Portions copyright [year] [name of copyright owner]".
 *
 * Copyright 2016 ForgeRock AS.
 *
 * Portions Copyright 2014 Nathaniel McCallum, Red Hat
 */

#import "CollectionViewController.h"

#import "FRAQRScanViewController.h"

#import "BlockActionSheet.h"
#import "FRAOathMechanismCell.h"
#import "FRAIdentityDatabase.h"
#import "FRAOathMechanism.h"

@interface CollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) UIPopoverController* popover;

- (FRAOathMechanism *)mechanismForTokenAtCell:(FRAOathMechanismCell*)cell;
- (void)generateCodeForTokenAtCell:(FRAOathMechanismCell *)cell usingMechanism:(FRAOathMechanism *)mechanism;
- (void)showEditActionSheetForTokenAtCell:(FRAOathMechanismCell *)cell withIndexPath:(NSIndexPath *)indexPath usingMechanism:(FRAOathMechanism *)mechanism;

@end

@implementation CollectionViewController {
    FRAIdentityDatabase* database;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [database identities].count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    switch ((int) collectionView.frame.size.width) {
    case 1024: // iPad
    case 768:  // iPad
        return CGSizeMake(328, 96);

    case 568:  // iPhone5 landscape
    case 320:  // iPhone* portrait
        return CGSizeMake(269, 80);

    case 480:  // iPhone4 landscape
    default:
        return CGSizeMake(225, 64);
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString* name = nil;
    switch ((int) collectionView.frame.size.width) {
    case 1024: // iPad
    case 768:  // iPad
        name = @"iPad";
        break;

    case 568:  // iPhone5 landscape
    case 320:  // iPhone* portrait
        name = @"iPhone5";
        break;

    case 480:  // iPhone4 landscape
    default:
        name = @"iPhone4";
        break;
    }

    FRAOathMechanismCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:name forIndexPath:indexPath];
    FRAIdentity* identity = (FRAIdentity*) [[database identities] objectAtIndex:indexPath.row];
    NSArray* mechanisms = [database mechanismsWithOwner:identity];
    return [cell bind:[mechanisms objectAtIndex:0]] ? cell : nil;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // If the device is smaller than an iPhone5,
    // then reload the data to pick up the new cell size.
    // This is unfortunate because it resets token UI state.
    // However, this works until we get completely dynamic resizing.
    if ([[UIScreen mainScreen] bounds].size.height < 568) {
        [self.collectionView reloadData];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // Perform animation.
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

    // Get the current cell and mechanism
    FRAOathMechanismCell* cell = (FRAOathMechanismCell*)[collectionView cellForItemAtIndexPath:indexPath];
    FRAOathMechanism* mechanism = [self mechanismForTokenAtCell:cell];
    
    if (self.navigationItem.rightBarButtonItem.style == UIBarButtonItemStylePlain) {
        // If we are not in edit mode, generate the token.
        [self generateCodeForTokenAtCell:cell usingMechanism:mechanism];
    } else {
        // If we are in edit mode, show the action sheet for deletion.
        [self showEditActionSheetForTokenAtCell:cell withIndexPath:indexPath usingMechanism:mechanism];
    }
}

- (FRAOathMechanism *)mechanismForTokenAtCell:(FRAOathMechanismCell*)cell {
    if (cell == nil) {
        return nil;
    }
    return [database mechanismWithId:cell.mechanismId];
}

- (void)generateCodeForTokenAtCell:(FRAOathMechanismCell *)cell usingMechanism:(FRAOathMechanism *)mechanism {
    // Get the code and save the mechanism state.
    FRAOathCode* oathCode = mechanism.code;
    [database updateMechanism:mechanism];
    
    // Show the code.
    cell.state = oathCode;
    
    // Copy the code to the clipboard.
    NSString* code = oathCode.currentCode;
    if (code != nil) {
        [[UIPasteboard generalPasteboard] setString:code];
    }
}

- (void)showEditActionSheetForTokenAtCell:(FRAOathMechanismCell *)cell withIndexPath:(NSIndexPath *)indexPath usingMechanism:(FRAOathMechanism *)mechanism {
    // Create the action sheet.
    BlockActionSheet* as = [[BlockActionSheet alloc] init];
    
    // On iPads, the sheet points to the token.
    // Otherwise, add a title to make the context clear.
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        as.title = [NSString stringWithFormat:@"%@\n%@", cell.issuer.text, cell.label.text];
    }
    // Add the remaining buttons.
    as.destructiveButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
    as.cancelButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    
    [as showFromRect:cell.frame inView:self.collectionView animated:YES];
    as.callback = ^(NSInteger offset) {
        switch (offset) {
            case 1: { // Delete
                BlockActionSheet* as = [[BlockActionSheet alloc] init];
                
                as.title = NSLocalizedString(@"Are you sure?", nil);
                if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
                    as.title = [NSString stringWithFormat:@"%@\n\n%@\n%@", as.title, cell.issuer.text, cell.label.text];
                }
                as.destructiveButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
                as.cancelButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                [as showFromRect:cell.frame inView:self.collectionView animated:YES];
                as.callback = ^(NSInteger offset) {
                    if (offset != 1) {
                        return;
                    }
                    [database removeMechanismWithId:mechanism.uid];
                    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
                };
                
                break;
            }
        }
    };
}

- (IBAction)editClicked:(id)sender {
    UIBarButtonItem* edit = sender;
    [self.collectionView reloadData];

    switch (edit.style) {
        case UIBarButtonItemStylePlain:
            edit.title = NSLocalizedString(@"Done", nil);
            edit.style = UIBarButtonItemStyleDone;
            break;

        default:
            edit.title = NSLocalizedString(@"Edit", nil);
            edit.style = UIBarButtonItemStylePlain;
            break;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popover = nil;
    [self.collectionView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Setup store.
    database = [FRAIdentityDatabase singleton];

    // Setup collection view.
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
}

@end
