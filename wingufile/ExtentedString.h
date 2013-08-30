//
//  EscapedString.h
//  wingufile
//
//  Created by Wang Wei on 9/7/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (ExtentedString)

- (NSString *)escapedUrl;
- (NSString *)escapedPostForm;
- (NSString *)trimUrl;
- (BOOL)isValidFolderName;

@end
