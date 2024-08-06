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

+ (void)trackAdRevenue:(NSString *)source revenue:(double)revenue currency:(NSString *)currency extraPayload:(NSDictionary *)extraPayload {
    [Noctua trackAdRevenueWithSource:source revenue:revenue currency:currency extraPayload:extraPayload];
}

+ (void)trackPurchase:(NSString *)orderId amount:(double)amount currency:(NSString *)currency extraPayload:(NSDictionary *)extraPayload {
    [Noctua trackPurchaseWithOrderId:orderId amount:amount currency:currency extraPayload:extraPayload];
}

+ (void)trackCustomEvent:(NSString *)eventName payload:(NSDictionary *)payload {
    [Noctua trackCustomEvent:eventName payload:payload];
}

@end
