//
//  SeafUploadFile.m
//  wingufile
//
//  Created by Wang Wei on 10/13/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import "SeafAppDelegate.h"
#import "SeafUploadFile.h"
#import "SeafConnection.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

#import "FileMimeType.h"
#import "UIImage+FileType.h"
#import "ExtentedString.h"
#import "Debug.h"

@interface SeafUploadFile ()
@property (readonly) NSString *mime;
@end

@implementation SeafUploadFile

@synthesize path = _path;
@synthesize filesize = _filesize;
@synthesize delegate = _delegate;
@synthesize uploading = _uploading;
@synthesize uploadProgress = _uploadProgress;

- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _path = path;
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        _filesize = attrs.fileSize;
        _uploadProgress = 0;
        _uploading = NO;
    }
    return self;
}

- (NSString *)name
{
    return [_path lastPathComponent];
}

- (NSString *)mime
{
    return [FileMimeType mimeType:self.name];
}

- (void)removeFile;
{
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
}

#pragma - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)aConn didFailWithError:(NSError *)error
{
    Debug("error=%@",[error localizedDescription]);
    _uploading = NO;
    [_delegate uploadProgress:self result:NO completeness:0];
    [SeafAppDelegate decUploadnum];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConn
{
    if (!_uploading)
        return;
    _uploading = NO;
    Debug("Upload file %@ success\n", self.name);
    [_delegate uploadProgress:self result:YES completeness:100];
    [SeafAppDelegate decUploadnum];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    [_delegate uploadProgress:self result:YES completeness:0];
    return request;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (totalBytesWritten == totalBytesExpectedToWrite) {
        _uploading = NO;
        [_delegate uploadProgress:self result:YES completeness:100];
    }
    int percent = totalBytesWritten * 100 / totalBytesExpectedToWrite;
    if (percent >= 100)
        percent = 99;
    [_delegate uploadProgress:self result:YES completeness:percent];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}

- (void)uploadFile2:(NSString *)surl dir:(NSString *)dir
{
    NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[surl escapedUrl]]];
    [uploadRequest setHTTPMethod:@"POST"];
    NSString *boundary = @"------WebKitFormBoundaryXaXmpsUEnSt1pbbp";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [uploadRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];

    NSMutableData *postbody = [[NSMutableData alloc] init];
    [postbody appendData:[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"csrfmiddlewaretoken\"\r\n\r\n8ba38951c9ba66418311a25195e2e380\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [postbody appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"parent_dir\"\r\n\r\n%@\r\n", dir] dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", self.name] dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[NSData dataWithContentsOfFile:self.path]];
    [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [uploadRequest setValue:[NSString stringWithFormat:@"%d", postbody.length] forHTTPHeaderField:@"Content-Length"];
    [uploadRequest setHTTPBody:postbody];

    NSURLConnection *uploadConncetion = [[NSURLConnection alloc] initWithRequest:uploadRequest delegate:self startImmediately:YES];
    if (!uploadConncetion) {
        _uploading = NO;
        [_delegate uploadProgress:self result:NO completeness:0];
    }
}

- (void)uploadFile:(NSString *)surl dir:(NSString *)dir
{
    NSURL *url = [NSURL URLWithString:surl];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:nil parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
        [formData appendPartWithFormData:[dir dataUsingEncoding:NSUTF8StringEncoding] name:@"parent_dir"];
        [formData appendPartWithFormData:[@"n8ba38951c9ba66418311a25195e2e380" dataUsingEncoding:NSUTF8StringEncoding] name:@"csrfmiddlewaretoken"];
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:self.path] name:@"file" error:nil];
    }];
    request.URL = url;
    [request setValue:@"close" forHTTPHeaderField:@"Connection"];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:
     ^(AFHTTPRequestOperation *operation, id responseObject) {
         Debug("Upload success\n");
         if (!_uploading)
             return;
         _uploading = NO;
         [SeafAppDelegate decUploadnum];
         [_delegate uploadProgress:self result:YES completeness:100];
     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         Debug("Upload failed :%@,code=%d, res=%@, %@\n", error, operation.response.statusCode, operation.responseData, operation.responseString);
                                         if (!_uploading)
                                             return;
                                         _uploading = NO;
                                         [SeafAppDelegate decUploadnum];
                                         [_delegate uploadProgress:self result:NO completeness:0];
                                     }];

    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        if (totalBytesWritten == totalBytesExpectedToWrite) {
            _uploading = NO;
           [_delegate uploadProgress:self result:YES completeness:100];
        } else {
           int percent;
           if (totalBytesExpectedToWrite > 0)
               percent = totalBytesWritten * 100 / totalBytesExpectedToWrite;
           else
               percent = 100;
           if (percent >= 100)
               percent = 99;
           [_delegate uploadProgress:self result:YES completeness:percent];
       }
    }];
    [operation setAuthenticationAgainstProtectionSpaceBlock:^BOOL(NSURLConnection *connection, NSURLProtectionSpace *protectionSpace) {
        return YES;
    }];
    [operation setAuthenticationChallengeBlock:^(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge) {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }];
    [operation start];
}

- (void)upload:(SeafConnection *)connection repo:(NSString *)repoId dir:(NSString *)dir
{
    @synchronized (self) {
        if (_uploading)
            return;
        _uploading = YES;
        _uploadProgress = 0;
    }
    [_delegate uploadProgress:self result:YES completeness:_uploadProgress];
    [SeafAppDelegate incUploadnum];
    NSString *upload_url = [NSString stringWithFormat:API_URL"/repos/%@/upload-link/", repoId];
    [connection sendRequest:upload_url repo:repoId success:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON, NSData *data) {
         NSString *identifierString = (__bridge NSString *)CFUUIDCreateString(NULL, CFUUIDCreate(NULL));
         NSString *url = [NSString stringWithFormat:@"%@?X-Progress-ID=%@", JSON, identifierString];
         Debug("Upload file %@ %@\n", self.name, url);
         [self uploadFile:url dir:dir];
     }
                    failure:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
         _uploading = NO;
         [SeafAppDelegate decUploadnum];
         [_delegate uploadProgress:self result:NO completeness:0];
     }];
}

#pragma mark - QLPreviewItem
- (NSString *)previewItemTitle
{
    return self.name;
}

- (NSURL *)previewItemURL
{
    return [NSURL fileURLWithPath:self.path];
}

- (UIImage *)image
{
    return [UIImage imageForMimeType:self.mime];
}

- (NSURL *)checkoutURL
{
    return [NSURL fileURLWithPath:self.path];
}

@end
