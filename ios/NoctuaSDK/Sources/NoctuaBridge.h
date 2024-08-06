@interface NoctuaBridge : NSObject

+ (void)initNoctua;
+ (void)trackAdRevenue:(NSString *)source revenue:(double)revenue currency:(NSString *)currency extraPayload:(NSDictionary *)extraPayload;
+ (void)trackPurchase:(NSString *)orderId amount:(double)amount currency:(NSString *)currency extraPayload:(NSDictionary *)extraPayload;
+ (void)trackCustomEvent:(NSString *)eventName payload:(NSDictionary *)payload;

@end
