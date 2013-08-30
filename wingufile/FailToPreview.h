//
//  FailToPreview.h
//  wingufile
//
//  Created by Wang Wei on 10/3/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

#import "Utils.h"

@interface FailToPreview : UIView
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
- (IBAction)openElsewhere:(id)sender;

- (void)configureViewWithPrevireItem:(id<QLPreviewItem, PreViewDelegate>)item;

@end
