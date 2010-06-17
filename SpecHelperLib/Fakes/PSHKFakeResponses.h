#import <Foundation/Foundation.h>

@class PSHKFakeHTTPURLResponse;

@interface PSHKFakeResponses : NSObject {
    NSString * request_;
}

+ (id)responsesForRequest:(NSString *)request;
- (id)initForRequest:(NSString *)request;

- (PSHKFakeHTTPURLResponse *)success;
- (PSHKFakeHTTPURLResponse *)badRequest;

@end
