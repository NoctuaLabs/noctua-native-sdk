#import <NoctuaSDK/NoctuaSDK.h>
#import <NoctuaSDK/NoctuaSDK-Swift.h>

@implementation NoctuaBridge

+ (void)initNoctua {
    @try {
        [Noctua initialize];
    } @catch (NSError *error) {
        NSLog(@"Error initializing Noctua: %@", error);
    }
}

+ (void)trackAdRevenue:(NSString *)source revenue:(double)revenue currency:(NSString *)currency extraPayload:(NSString *)payloadJson {
    NSData *data = [payloadJson dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    [Noctua trackAdRevenueWithSource:source revenue:revenue currency:currency extraPayload:payload];
}

+ (void)trackPurchase:(NSString *)orderId amount:(double)amount currency:(NSString *)currency extraPayload:(NSString *)payloadJson {
    NSData *data = [payloadJson dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    [Noctua trackPurchaseWithOrderId:orderId amount:amount currency:currency extraPayload:payload];
}

+ (void)trackCustomEvent:(NSString *)eventName payload:(NSString *)payloadJson {
    NSData *data = [payloadJson dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    [Noctua trackCustomEvent:eventName payload:payload];
}

+ (void)purchaseItem:(NSString *)productId completion:(void (^)(BOOL success, NSString *message))completion {
    [Noctua purchaseItemWithProductId:productId completion:^(BOOL success, NSString * _Nonnull message) {
        if (completion) {
            completion(success, message);
        }
    }];
}

@end
