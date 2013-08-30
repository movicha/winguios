//
//  SeafStarredFile.m
//  wingufile
//
//  Created by Wang Wei on 11/4/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import "SeafStarredFile.h"
#import "SeafConnection.h"
#import "FileMimeType.h"


@implementation SeafStarredFile
@synthesize starDelegate = _starDelegate;
@synthesize org = _org;

- (id)initWithConnection:(SeafConnection *)aConnection
                    repo:(NSString *)aRepo
                    path:(NSString *)aPath
                   mtime:(int)mtime
                    size:(int)size
                     org:(int)org
{
    NSString *name = aPath.lastPathComponent;
    if (self = [super initWithConnection:aConnection oid:nil repoId:aRepo name:name path:aPath mtime:mtime size:size ]) {
        _org = org;
    }
    return self;
}

- (void)setStarred:(BOOL)starred
{
    [connection setStarred:starred repo:self.repoId path:self.path];
    [_starDelegate fileStateChanged:starred file:self];
}

@end
