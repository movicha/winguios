//
//  SeafUploadsViewController.h
//  wingufile
//
//  Created by Wang Wei on 10/13/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SeafUploadFile.h"
#import "SeafConnection.h"
#import "SeafDir.h"

@interface SeafUploadsViewController : UITableViewController<SeafUploadDelegate, UIActionSheetDelegate>
@property (strong) SeafConnection *connection;

- (void)initTabBarItem;
- (void)chooseUploadDir:(SeafDir *)dir;

@end
