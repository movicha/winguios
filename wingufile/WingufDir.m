//
//  SeafDir.m
//  wingufile
//
//  Created by Wang Wei on 10/11/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import "SeafData.h"
#import "SeafDir.h"
#import "SeafFile.h"
#import "SeafConnection.h"
#import "SeafBase.h"
#import "SeafAppDelegate.h"

#import "ExtentedString.h"
#import "Utils.h"
#import "Debug.h"

@interface SeafDir ()
@end

@implementation SeafDir
@synthesize items = _items;


- (id)initWithConnection:(SeafConnection *)aConnection
                     oid:(NSString *)anId
                  repoId:(NSString *)aRepoId
                    name:(NSString *)aName
                    path:(NSString *)aPath
{
    self = [super initWithConnection:aConnection oid:anId repoId:aRepoId name:aName path:aPath mime:@"text/directory"];
    return self;
}

- (BOOL)editable
{
    return [connection repoEditable:self.repoId];
}

- (BOOL)handleData:(NSString *)oid data:(id)JSON
{
    @synchronized(self) {
        if (oid) {
            if ([oid isEqualToString:self.ooid])
                return NO;
            self.ooid = oid;
        } else {
            if ([@"uptodate" isEqual:JSON])
                return NO;
        }
    }

    NSMutableArray *newItems = [NSMutableArray array];
    for (NSDictionary *itemInfo in JSON) {
        if ([itemInfo objectForKey:@"name"] == [NSNull null])
            continue;
        SeafBase *newItem = nil;
        NSString *type = [itemInfo objectForKey:@"type"];
        NSString *name = [itemInfo objectForKey:@"name"];
        NSString *path = [self.path isEqualToString:@"/"] ? [NSString stringWithFormat:@"/%@", name]:[NSString stringWithFormat:@"%@/%@", self.path, name];

        if ([type isEqual:@"file"]) {
            newItem = [[SeafFile alloc] initWithConnection:connection oid:[itemInfo objectForKey:@"id"] repoId:self.repoId name:name path:path mtime:[[itemInfo objectForKey:@"mtime"] integerValue:0] size:[[itemInfo objectForKey:@"size"] integerValue:0]];
        } else if ([type isEqual:@"dir"]) {
            newItem = [[SeafDir alloc] initWithConnection:connection oid:[itemInfo objectForKey:@"id"] repoId:self.repoId name:name path:path];
        }
        [newItems addObject:newItem];
    }
    [self loadedItems:newItems];
    [self.delegate entry:self contentUpdated:YES completeness:100];
    return YES;
}

- (void)handleResponse:(NSHTTPURLResponse *)response json:(id)JSON data:(NSData *)data
{
    @synchronized(self) {
        self.state = SEAF_DENTRY_UPTODATE;
        NSString *curId = [[response allHeaderFields] objectForKey:@"oid"];
        if (!curId)
            curId = self.oid;
        if ([self handleData:curId data:JSON]) {
            self.ooid = curId;
            [self savetoCache:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        } else {
            Debug("already uptodate oid=%@, %@\n", self.ooid, curId);
            self.state = SEAF_DENTRY_UPTODATE;
            [self.delegate entry:self contentUpdated:NO completeness:0];
        }
        if (![self.oid isEqualToString:curId]) {
            Debug("%@, %@,%@\n", @"the parent is out of date and need to reload", self.oid, curId);
            self.oid = curId;
        }
    }
}

- (NSString *)url
{
    NSString *requestStr = [NSString stringWithFormat:API_URL"/repos/%@/dir/?p=%@", self.repoId, [self.path escapedUrl]];
    if (self.ooid)
        requestStr = [requestStr stringByAppendingFormat:@"&oid=%@", self.ooid ];

    return requestStr;
}

/*
 curl -D a.txt -H 'Cookie:sessionid=7eb567868b5df5b22b2ba2440854589c' http://127.0.0.1:8000/api/dir/640fd90d-ef4e-490d-be1c-b34c24040da7/?p=/SSD-FTL

 [{"id": "0d6a4cc4e084fec6cde0f50d628cf4f502ced622", "type": "file", "name": "shin_SSD.pdf", "size": 1092236}, {"id": "2ac5dfb7126bea3a2038069688337bd3f64e80e2", "type": "file", "name": "FTL design exploration in reconfigurable high-performance SSD for server applications.pdf", "size": 675464}, {"id": "eee56009908153baf5cf21615cea00cba657cb0a", "type": "file", "name": "DFTL.pdf", "size": 1232088}, {"id": "97eb7fd4f9ad45c821ed3ddd662c5d2b27ab7e45", "type": "file", "name": "BPLRU a buffer management scheme for improving random writes in flash storage.pdf", "size": 1113100}, {"id": "1578adbc33c143f68c5a79b421f1d9d7f0d52bc8", "type": "file", "name": "Algorithms and Data Structures for Flash Memories.pdf", "size": 689915}, {"id": "8dd0a3be9289aea6795c1203351691fcc1373fbb", "type": "file", "name": "2006-Intel TR-Understanding the flash translation layer (FTL)specification.pdf", "size": 84054}]
 */
- (void)realLoadContent
{
    [connection sendRequest:self.url repo:self.repoId
                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON, NSData *data) {
                        [self handleResponse:response json:JSON data:data];
                    }
                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                        self.state = SEAF_DENTRY_INIT;
                        [self.delegate entryContentLoadingFailed:response.statusCode entry:self];
                    }];
}

- (void)updateItems:(NSMutableArray *)items
{
    int i = 0;
    if (!_items)
        _items = items;
    else {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        for (i = 0; i < [_items count]; ++i) {
            SeafBase *obj = (SeafBase*)[_items objectAtIndex:i];
            [dict setObject:obj forKey:[obj key]];
        }
        for (i = 0; i < [items count]; ++i) {
            SeafBase *obj = (SeafBase*)[items objectAtIndex:i];
            SeafBase *oldObj = [dict objectForKey:[obj key]];
            if (oldObj && [obj class] == [oldObj class]) {
                [oldObj updateWithEntry:obj];
                [items replaceObjectAtIndex:i withObject:oldObj];
            }
        }
        _items = items;
    }
}

- (BOOL)checkSorted:(NSArray *)items
{
    int i;
    for (i = 1; i < [items count]; ++i) {
        SeafBase *obj1 = (SeafBase*)[items objectAtIndex:i-1];
        SeafBase *obj2 = (SeafBase*)[items objectAtIndex:i];
        if ([obj1 class] == [obj2 class]) {
            if ([obj1.key caseInsensitiveCompare:obj2.key] != NSOrderedAscending)
                return NO;
        } else {
            if (![obj1 isKindOfClass:[SeafDir class]])
                return NO;
        }
    }
    return YES;
}

- (void)loadedItems:(NSMutableArray *)items
{
    if ([self checkSorted:items] == NO) {
        [items sortUsingComparator:(NSComparator)^NSComparisonResult(id obj1, id obj2){
            if ([obj1 class]==[obj2 class]) {
                return [((SeafBase*)obj1).key caseInsensitiveCompare:((SeafBase*)obj2).key];
            } else {
                if ([obj1 isKindOfClass:[SeafDir class]]) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedDescending;
                }
            }
            return NSOrderedSame;
        }];
    }
    [self updateItems:items];
    Debug("load oid=%@, %@, %@\n", self.ooid, self.path, self.mime);
}

- (Directory *)loadCacheObj
{
    SeafAppDelegate *appdelegate = (SeafAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appdelegate managedObjectContext];

    NSFetchRequest *fetchRequest=[[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Directory"
                                        inManagedObjectContext:context]];
    NSSortDescriptor *sortDescriptor=[[NSSortDescriptor alloc] initWithKey:@"path" ascending:YES selector:nil];
    NSArray *descriptor=[NSArray arrayWithObject:sortDescriptor];
    [fetchRequest setSortDescriptors:descriptor];

    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"repoid==%@ AND path==%@", self.repoId, self.path]];

    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc]
                                              initWithFetchRequest:fetchRequest
                                              managedObjectContext:context
                                              sectionNameKeyPath:nil
                                              cacheName:nil];
    NSError *error;
    if (![controller performFetch:&error]) {
        Debug(@"Fetch cache error:%@",[error localizedDescription]);
        return nil;
    }
    NSArray *results = [controller fetchedObjects];
    if ([results count] == 0)
        return nil;
    Directory *dir = [results objectAtIndex:0];
    return dir;
}

- (BOOL)savetoCache:(NSString *)content
{
    SeafAppDelegate *appdelegate = (SeafAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appdelegate managedObjectContext];
    Directory *dir = [self loadCacheObj];
    if (!dir) {
        dir = (Directory *)[NSEntityDescription insertNewObjectForEntityForName:@"Directory" inManagedObjectContext:context];
        dir.oid = self.ooid;
        dir.repoid = self.repoId;
        dir.content = content;
        dir.path = self.path;
    } else {
        dir.oid = self.ooid;
        dir.content = content;
        [context updatedObjects];
    }
    [appdelegate saveContext];
    return YES;
}

- (BOOL)realLoadCache
{
    NSError *error = nil;
    Directory *dir = [self loadCacheObj];
    if (!dir)
        return NO;
    NSData *data = [NSData dataWithBytes:[[dir content] UTF8String] length:[[dir content] length]];

    id JSON = [Utils JSONDecode:data error:&error];
    if (error) {
        SeafAppDelegate *appdelegate = (SeafAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = [appdelegate managedObjectContext];
        [context deleteObject:dir];
        return NO;
    }

    [self handleData:dir.oid data:JSON];
    return YES;
}

- (void)mkdir:(NSString *)newDirName
{
    NSString *path = [self.path stringByAppendingPathComponent:newDirName];
    NSString *requestUrl = [NSString stringWithFormat:API_URL"/repos/%@/dir/?p=%@&reloaddir=true", self.repoId, [path escapedUrl]];

    [connection sendPost:requestUrl repo:self.repoId form:@"operation=mkdir"
                 success:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON, NSData *data) {
         Debug("resp=%d\n", response.statusCode);
         [self handleResponse:response json:JSON data:data];
     }
                 failure:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
         Warning("resp=%d\n", response.statusCode);
         [self.delegate entryContentLoadingFailed:response.statusCode entry:self];
     }];
}

- (void)delEntries:(NSArray *)entries
{
    int i = 0;
    NSAssert(entries.count > 0, @"There must be at least one entry");
    NSString *requestUrl = [NSString stringWithFormat:API_URL"/repos/%@/fileops/delete/?p=%@&reloaddir=true", self.repoId, [self.path escapedUrl]];

    NSMutableString *form = [[NSMutableString alloc] init];
    [form appendFormat:@"file_names=%@", [[[entries objectAtIndex:0] name] escapedPostForm]];

    for (i = 1; i < entries.count; ++i) {
        SeafBase *entry = [entries objectAtIndex:i];
        [form appendFormat:@":%@", [entry.name escapedPostForm]];
    }

    [connection sendPost:requestUrl repo:self.repoId form:form
                 success:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON, NSData *data) {
         Debug("resp=%d\n", response.statusCode);
         [self handleResponse:response json:JSON data:data];
     }
                 failure:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
         Warning("resp=%d\n", response.statusCode);
         [self.delegate entryContentLoadingFailed:response.statusCode entry:self];
     }];
}

@end
