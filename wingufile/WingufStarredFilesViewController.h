//
//  SeafStarredFilesViewController.h
//  wingufile
//
//  Created by Wang Wei on 11/4/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SeafConnection.h"
#import "SeafStarredFile.h"


@interface SeafStarredFilesViewController : UITableViewController<SeafDentryDelegate, SeafStarFileDelegate>

@property (strong) SeafConnection *connection;

- (void)initTabBarItem;

@end
