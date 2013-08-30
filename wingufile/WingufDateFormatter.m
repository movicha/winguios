//
//  SeafDateFormatter.m
//  wingufile
//
//  Created by Wang Wei on 8/30/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import "SeafDateFormatter.h"

@implementation SeafDateFormatter
static SeafDateFormatter *sharedLoader = nil;


+ (SeafDateFormatter *)sharedLoader
{
    if (sharedLoader==nil) {
        sharedLoader = [[SeafDateFormatter alloc] init];
        [sharedLoader setDateFormat:@"yyyy-MM-dd HH:mm"];
    }
    return sharedLoader;
}

+ (NSString *)stringFromInt:(int)time
{
    return [[SeafDateFormatter sharedLoader] stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];
}

@end
