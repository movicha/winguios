//
//  EscapedString.m
//  wingufile
//
//  Created by Wang Wei on 9/7/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import "ExtentedString.h"

@implementation NSString (ExtentedString)

- (NSString *)escapedUrl
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes
                                         (
                                          NULL,
                                          (__bridge CFStringRef)self,
                                          NULL,
                                          (CFStringRef)@"!*'();:@&=+$,?%#[]",
                                          kCFStringEncodingUTF8));
}

- (NSString *)escapedPostForm
{
    return [self escapedUrl];
}

#define HTTP @"http://"
#define HTTPS @"https://"
#define WWW @"http://www."
#define WWWS @"https://www."

- (NSString *)trimUrl
{
    NSString *url = [self lowercaseString];

    if ([self hasPrefix:WWW]) {
        return [url substringFromIndex:WWW.length];
    } else if ([self hasPrefix:HTTP]) {
        return [url substringFromIndex:HTTP.length];
    } else if ([self hasPrefix:WWWS]) {
        return [url substringFromIndex:WWWS.length];
    } else if ([self hasPrefix:HTTPS]) {
        return [url substringFromIndex:HTTPS.length];
    }
    return url;
}


- (BOOL)isValidFolderName
{
    if([self compare:[NSString stringWithUTF8String:[[self lastPathComponent]  fileSystemRepresentation]]] == NSOrderedSame)
        return YES;
    return NO;
}

@end
