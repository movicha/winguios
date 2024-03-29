//
//  FileSizeFormatter.h
//  wingufile
//
//  Created by Wang Wei on 10/11/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileSizeFormatter : NSNumberFormatter

/** Flag signaling whether to calculate file size in binary units (1024) or base ten units (1000).  Default is binary units. */
+ (NSString *)stringFromNumber:(NSNumber *)number useBaseTen:(BOOL)useBaseTen;

+ (NSString *)stringFromInt:(int)number;

@end
