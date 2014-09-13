//
//  AFNetworkingHelper.m
//
//
//  Created by yang chenghu on 13-5-30.
//  Copyright (c) 2013年 Sina. All rights reserved.
//

#import "AFNetworkingHelper.h"

#import "Reachability.h"
#import "UIImageView+AFNetworking.h"
#import "Common+Cookies.h"


#define kLinkTag @"lt"

#define kFakeUserAgent @"Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Version/7.0 Mobile/11D257 Safari/9537.53"


@implementation AFNetworkingHelper

+ (BOOL)isNetworkReachable
{
    Reachability * netStyle = [Reachability reachabilityForInternetConnection];
    [netStyle startNotifier];
    NetworkStatus netStatus = [netStyle currentReachabilityStatus];
    [netStyle stopNotifier];
    
    BOOL bNetStatus = YES;
    
    if ( kNotReachable == netStatus )
    {
        bNetStatus = NO;
    }
    
    return bNetStatus;
}

+ (NSString *)getNetType
{
    Reachability * netStyle = [Reachability reachabilityForInternetConnection];
    [netStyle startNotifier];
    NetworkStatus netStatus = [netStyle currentReachabilityStatus];
    [netStyle stopNotifier];
    
    NSString * strNetType = nil;
    
    if ( kReachableViaWWAN == netStatus )
    {
        strNetType = @"2/3G";
    }
    else if(kReachableViaWiFi == netStatus)
    {
        strNetType = @"wifi";
    }
    else if(kNotReachable == netStatus)
    {
        strNetType = @"no net";
    }
    else if (kReachableVia2G == netStatus)
    {
        strNetType = @"2G";
    }
    else if (kReachableVia3G == netStatus)
    {
        strNetType = @"3G";
    }
    
    return strNetType;
}

+ (NetBase *)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _netOperationQueue = [[NSOperationQueue alloc] init];
        _netOperationQueue.maxConcurrentOperationCount = 3;
    }
    
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;

    return self;
}

- (void)getImageFromURL:(NSString *)strURL imageView:(UIImageView *)imageView
{
    [imageView setImageWithURL:[NSURL URLWithString:strURL]];
}

- (void)getImageFromURL:(NSString *)strURL successBlock:(successBlock)success failBlock:(failBlock)fail
{
    if (nil == strURL) {
        fail(nil, [NSError errorWithDomain:@"string url is nil" code:-200 userInfo:nil]);
        return;
    }
    NSURL * url = [NSURL URLWithString:strURL];
    
    if (nil == url) {
        fail(nil, [NSError errorWithDomain:@"string to url is fail" code:-200 userInfo:nil]);
        return;
    }
    
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
    if (nil == urlRequest) {
        fail(nil, [NSError errorWithDomain:@"url to request is fail" code:-200 userInfo:nil]);
        return;
    }
    
    AFImageRequestOperation *requestOperation = [[AFImageRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:success failure:fail];
    
    [_netOperationQueue addOperation:requestOperation];
}

#pragma mark - Net Methods
- (NSUInteger)postData:(NSDictionary *)dicParamenters toRootURL:(NSString *)strRoot toPath:(NSString *)strPath cookies:(NSArray *)arrCookies userAgent:(NSString *)strUserAgent userInfo:(NSDictionary *)dicUserInfo successBlock:(successBlock)success failBlock:(failBlock)fail
{
    NSURL *url = [NSURL URLWithString:strRoot];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:strPath parameters:dicParamenters];
    
    if (arrCookies)
    {
        [Common addCookies:arrCookies];
    }
    
    if (strUserAgent)
    {
        [request setValue:strUserAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    NSString * strUrl = [strRoot stringByAppendingString:strPath];
    
    NSUInteger iconnectHash = [strUrl hash];
    
    if (dicUserInfo)
    {
        NSMutableDictionary * mDicUserInfo = [dicUserInfo mutableCopy];
        mDicUserInfo[kLinkTag] = @(iconnectHash);
        operation.userInfo = mDicUserInfo;
    }
    else
    {
        operation.userInfo = @{kLinkTag : @(iconnectHash)};
    }
    
    [operation setCompletionBlockWithSuccess:success failure:fail];
    
    [_netOperationQueue addOperation:operation];
    
    return iconnectHash;
}

- (NSUInteger)postData:(NSDictionary *)dicParamenters toRootURL:(NSString *)strRoot toPath:(NSString *)strPath cookies:(NSArray *)arrCookies userInfo:(NSDictionary *)dicUserInfo successBlock:(successBlock)success failBlock:(failBlock)fail
{
    return [self postData:dicParamenters toRootURL:strRoot toPath:strPath cookies:arrCookies  userAgent:nil userInfo:dicUserInfo successBlock:success failBlock:fail];
}

- (NSUInteger)postData:(NSDictionary *)dicParamenters toRootURL:(NSString *)strRoot toPath:(NSString *)strPath userInfo:(NSDictionary *)dicUserInfo successBlock:(successBlock)success failBlock:(failBlock)fail
{
    return [self postData:dicParamenters toRootURL:strRoot toPath:strPath cookies:nil userInfo:dicUserInfo successBlock:success failBlock:fail];
}

- (NSUInteger)getRootURL:(NSString *)strRoot toPath:(NSString *)strPath userInfo:(NSDictionary *)dicUserInfo
      successBlock:(successBlock)success failBlock:(failBlock)fail
{
    NSURL *url = [NSURL URLWithString:strRoot];
    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:url];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET" path:strPath parameters:nil];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    NSString * strUrl = [strRoot stringByAppendingString:strPath];

    NSUInteger iconnectHash = [strUrl hash];
    
    if (dicUserInfo)
    {
        NSMutableDictionary * mDicUserInfo = [dicUserInfo mutableCopy];
        mDicUserInfo[kLinkTag] = @(iconnectHash);
        operation.userInfo = mDicUserInfo;
    }
    else
    {
        operation.userInfo = @{kLinkTag : @(iconnectHash)};
    }
    
    [operation setCompletionBlockWithSuccess:success failure:fail];
    
    [_netOperationQueue addOperation:operation];
    
    return iconnectHash;
}

//同步
- (void)synCallURL:(NSString *)urlString
{
    NSURL *url = [[NSURL alloc] initWithString:urlString];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	NSError *err = nil;
 	NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:nil
                                                     error:&err];
	if(nil == data)
	{		
//		NSLog(@"Code:%d, domain:%@, localizedDesc:%@", [err code], [err domain], [err localizedDescription]);
	}
	else
	{
	}

}

//异步
- (void)asynCallURL:(NSString *)urlString
{
    NSURL *url = [[NSURL alloc] initWithString:urlString];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if(connection)
	{
        _receivedData = [[NSMutableData alloc] init];
//        NSLog(@"intial done!");
    }
	else
	{
//        NSLog(@"sorry");
    }
}

#pragma mark - 
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//    NSLog(@"get the whole response");
    [_receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//    NSLog(@"get some data");
    [_receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
//    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

#pragma mark - DownLoad file
- (NSUInteger)downloadFileUrl:(NSString *)strUrl writefilePath:(NSString *)strPath userinfo:(NSDictionary *)dicUserInfo downloadProgressBlock:(downloadProgressBlock)progressblock completionBlock:(void(^)(void))completionBlock
{
    NSURL * url = [NSURL URLWithString:strUrl];
    NSURLRequest * request = [NSURLRequest requestWithURL:url];

    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];

    NSUInteger iconnectHash = [strUrl hash];
    
    if (dicUserInfo)
    {
        NSMutableDictionary * mDicUserInfo = [dicUserInfo mutableCopy];
        mDicUserInfo[kLinkTag] = @(iconnectHash);
        operation.userInfo = mDicUserInfo;
    }
    else
    {
        operation.userInfo = @{kLinkTag : @(iconnectHash)};
    }
    
    if (strPath)
    {
        NSOutputStream * outputStream = [NSOutputStream outputStreamToFileAtPath:strPath append:YES];
        operation.outputStream = outputStream;
    }
    
    [operation setDownloadProgressBlock:progressblock];

    [operation setCompletionBlock:completionBlock];
    
    [_netOperationQueue addOperation:operation];
    
    return iconnectHash;
}

- (BOOL)cancelTaskWithConnectHash:(NSUInteger)iHash
{
    NSArray * arrTaskList = [_netOperationQueue operations];
    
    AFURLConnectionOperation * selectecOperation = nil;
    
    for (AFURLConnectionOperation * operation in arrTaskList)
    {
        NSDictionary * dicUserInfo = operation.userInfo;
        if (!dicUserInfo)
        {
            continue;
        }
        
        NSNumber * hashNum = dicUserInfo[kLinkTag];
        if (!hashNum)
        {
            continue;
        }
        
        if (iHash == [hashNum integerValue])
        {
            selectecOperation = operation;
        }
    }
    
    if (!selectecOperation)
    {
        return NO;
    }
    
    [selectecOperation cancel];
    
    return YES;
}

- (BOOL)cancelTaskWithConnectUrl:(NSString *)strUrl
{
    NSUInteger iConnectHash = [strUrl hash];
    
    return [self cancelTaskWithConnectHash:iConnectHash];
}


@end
