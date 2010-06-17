#import "PCKHTTPInterface.h"
#import "NSURLConnectionDelegate.h"

@interface PCKHTTPInterface (PCKHTTPConnectionFriend)
- (void)clearConnection:(NSURLConnection *)connection;
@end

@implementation PCKHTTPConnection

- (id)initWithHTTPInterface:(PCKHTTPInterface *)interface forRequest:(NSURLRequest *)request andDelegate:(id<NSURLConnectionDelegate>)delegate {
    if (self = [super initWithRequest:request delegate:self]) {
        interface_ = interface;
        delegate_ = delegate;
    }
    return self;
}

- (void)cancel{
    [interface_ clearConnection:self];
    [super cancel];
}

#pragma mark NSURLConnectionDelegate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [delegate_ connectionDidFinishLoading:connection];
    [interface_ clearConnection:connection];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [delegate_ connection:connection didFailWithError:error];
    [interface_ clearConnection:connection];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([delegate_ respondsToSelector:@selector(connection:didReceiveResponse:)]) {
        [delegate_ connection:connection didReceiveResponse:response];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if ([delegate_ respondsToSelector:@selector(connection:didReceiveData:)]) {
        [delegate_ connection:connection didReceiveData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([delegate_ respondsToSelector:@selector(connection:didReceiveAuthenticationChallenge:)]) {
        [delegate_ connection:connection didReceiveAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([delegate_ respondsToSelector:@selector(connection:didCancelAuthenticationChallenge:)]) {
        [delegate_ connection:connection didCancelAuthenticationChallenge:challenge];
    }
    [interface_ clearConnection:connection];
}

@end

@interface PCKHTTPInterface (private)
- (NSURL *)urlForPath:(NSString *)path secure:(BOOL)secure;
- (NSURL *)baseURLAndPathWithSecurity:(BOOL)secure;
- (NSURL *)newBaseURLAndPathWithProtocol:(NSString *)protocol;
@end

@implementation PCKHTTPInterface

@synthesize activeConnections = activeConnections_;

- (id)init {
    if (self = [super init]) {
        activeConnections_ = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [activeConnections_ release]; activeConnections_ = nil;
    [baseURLAndPath_ release]; baseURLAndPath_ = nil;
    [baseSecureURLAndPath_ release]; baseSecureURLAndPath_ = nil;
    [super dealloc];
}

- (NSURLConnection *)connectionOfClass:(Class)class forPath:(NSString *)path andDelegate:(id<NSURLConnectionDelegate>)delegate secure:(BOOL)secure {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self urlForPath:path secure:secure]];
    NSURLConnection *connection = [[class alloc] initWithHTTPInterface:self forRequest:request andDelegate:delegate];
    [activeConnections_ addObject:connection];

    [connection release];
    [request release];

    return connection;
}

#pragma mark friend interface for PCKHTTPConnection

- (void)clearConnection:(NSURLConnection *)connection {
    [activeConnections_ removeObject:connection];
}

#pragma mark private interface

- (NSURL *)urlForPath:(NSString *)path secure:(BOOL)secure {
    return [[[NSURL alloc] initWithString:path relativeToURL:[self baseURLAndPathWithSecurity:secure]] autorelease];
}

- (NSURL *)baseURLAndPathWithSecurity:(BOOL)secure {
    if (secure) {
        if (!baseSecureURLAndPath_) {
            baseSecureURLAndPath_ = [self newBaseURLAndPathWithProtocol:@"https://"];
        }
        return baseSecureURLAndPath_;
    } else {
        if (!baseURLAndPath_) {
            baseURLAndPath_ = [self newBaseURLAndPathWithProtocol:@"http://"];
        }
        return baseURLAndPath_;
    }
}

- (NSURL *)newBaseURLAndPathWithProtocol:(NSString *)protocol {
    NSMutableString *baseURLString = [[NSMutableString alloc] initWithFormat:@"%@%@", protocol, [self host]];
    if ([self respondsToSelector:@selector(basePath)]) {
        [baseURLString appendString:[self basePath]];
    }
    NSURL *url = [[NSURL alloc] initWithString:baseURLString];
    [baseURLString release];
    return url;
}

@end
