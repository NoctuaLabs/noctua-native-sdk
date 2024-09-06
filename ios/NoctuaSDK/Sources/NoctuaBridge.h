#import <Foundation/Foundation.h>

@interface NoctuaBridge : NSObject

// Define the PurchaseCompletion type
typedef void (^PurchaseCompletion)(BOOL success, NSString * _Nonnull message);


+ (void)initNoctua;
+ (void)trackAdRevenue:(NSString *)source revenue:(double)revenue currency:(NSString *)currency extraPayload:(NSString *)payloadJson;
+ (void)trackPurchase:(NSString *)orderId amount:(double)amount currency:(NSString *)currency extraPayload:(NSString *)payloadJson;
+ (void)trackCustomEvent:(NSString *)eventName payload:(NSString *)payloadJson;
+ (void)purchaseItem:(NSString *)productId completion:(PurchaseCompletion)completion;

@end

