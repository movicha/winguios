//
//  SeafStarredFile.h
//  wingufile
//
//  Created by Wang Wei on 11/4/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import "SeafFile.h"

@protocol SeafStarFileDelegate <NSObject>
- (void)fileStateChanged:(BOOL)starred file:(SeafFile *)sfile;
@end

@interface SeafStarredFile : SeafFile
@property (strong) id<SeafStarFileDelegate> starDelegate;
@property int org;


- (id)initWithConnection:(SeafConnection *)aConnection
                    repo:(NSString *)aRepo
                    path:(NSString *)aPath
                   mtime:(int)mtime
                    size:(int)size
                     org:(int)org;
@end
