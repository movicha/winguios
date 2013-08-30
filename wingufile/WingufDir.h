//
//  SeafDir.h
//  wingufile
//
//  Created by Wang Wei on 10/11/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import "SeafBase.h"


@interface SeafDir : SeafBase

- (id)initWithConnection:(SeafConnection *)aConnection
                     oid:(NSString *)anId
                  repoId:(NSString *)aRepoId
                    name:(NSString *)aName
                    path:(NSString *)aPath;

@property (readonly, copy) NSMutableArray *items;
@property (readonly) BOOL editable;

- (void)loadedItems:(NSMutableArray *)items;
- (void)mkdir:(NSString *)newDirName;
- (void)delEntries:(NSArray *)entries;

@end
