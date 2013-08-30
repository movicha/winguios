//
//  WingufAccountViewController.h
//  wingufile
//
//  Created by Wang Wei on 1/12/13.
//  Copyright (c) 2012 ClouidIO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StartViewController.h"

@interface WingufAccountViewController : UIViewController<SSConnectionDelegate, UITextFieldDelegate>

- (id)initWithController:(StartViewController *)controller connection: (WingufConnection *)conn;

@end
