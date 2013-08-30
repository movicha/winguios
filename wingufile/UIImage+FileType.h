//
//  UIImage+FileType.h
//  wingufile
//
//  Created by Wang Wei on 10/11/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (FileType)

+ (UIImage *)imageForMimeType:(NSString *)mimeType;

@end
