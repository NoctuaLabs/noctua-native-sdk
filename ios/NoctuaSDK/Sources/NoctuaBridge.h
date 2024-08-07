@interface NoctuaBridge : NSObject

+ (void)initNoctua;
+ (void)trackAdRevenue:(NSString *)source revenue:(double)revenue currency:(NSString *)currency extraPayload:(NSString *)payloadJson;
+ (void)trackPurchase:(NSString *)orderId amount:(double)amount currency:(NSString *)currency extraPayload:(NSString *)payloadJson;
+ (void)trackCustomEvent:(NSString *)eventName payload:(NSString *)payloadJson;

@end
