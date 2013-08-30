//
//  SeafUploadFileCell.h
//  wingufile
//
//  Created by Wang Wei on 10/20/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SeafUploadingFileCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;

@end
