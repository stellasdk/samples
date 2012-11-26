/*
 * Copyright (c) 2011 Yeecco Limited
 */

#import "AppDelegate.h"
#import "EAGLView.h"

@implementation AppDelegate

@synthesize window;

static BOOL    _plasmaPurchasing       = NO;

- (void) applicationDidFinishLaunching: (UIApplication *) application
{
        window      = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        glView      = [[EAGLView alloc] initWithFrame: window.frame];

        window.backgroundColor      = [UIColor whiteColor];
        [window addSubview: glView];
        [window makeKeyAndVisible];

   #if defined (FREEMIUM_USING_PLASMA)
        glView.samsungappsEnabled           = YES;
   #endif

   #if defined (FREEMIUM_USING_GOOGLEIAB)
        glView.googleplayEnabled            = YES;
   #endif

   #if defined (FREEMIUM_USING_AMAZONIAP)
        glView.amazonappsEnabled            = YES;
   #endif

   #if defined (FREEMIUM_USING_TAPJOY)
        glView.tapjoyEnabled            = YES;
   #endif

   #if defined (FREEMIUM_USING_CHARTBOOST)
        glView.chartboostEnabled        = YES;
   #endif

   #if defined (FREEMIUM_USING_ADCOLONY)
        glView.adcolonyEnabled          = YES;
   #endif

        glView.delegate                 = self;
        [glView startAnimation];
}

- (void) applicationWillResignActive: (UIApplication *) application
{
        [glView stopAnimation];
}

- (void) applicationDidBecomeActive: (UIApplication *) application
{
        [glView startAnimation];
}

- (void) applicationWillTerminate: (UIApplication *) application
{
        [glView stopAnimation];

   /* Google IAB */
   #if defined (FREEMIUM_USING_GOOGLEIAB)
        [SKPaymentQueue unbindGoogleIAB];
   #endif
}

- (void) dealloc
{
        [window release];
        [glView release];

        [super dealloc];
}

#if defined (FREEMIUM_USING_PLASMA) || defined (FREEMIUM_USING_GOOGLEIAB) || defined (FREEMIUM_USING_AMAZONIAP)
- (void) buyShinePlasma
{
        _plasmaPurchasing   = YES;
        [SKPaymentQueue setVendor: @"SamsungPlasma"];
        [SKPaymentQueue setSamsungPlasmaItemGroupID: @"100000008752"];
        [SKPaymentQueue setSamsungPlasmaDeveloperMode];
        

        NSMutableArray      * productIdentifierList;
        productIdentifierList = [[NSMutableArray alloc] initWithCapacity: 2];

        [productIdentifierList addObject: [NSString stringWithFormat: @"000000012717"]];     /* buy this to shine */
        [productIdentifierList addObject: [NSString stringWithFormat: @"000000012725"]];     /* unavailable */

        if ([SKPaymentQueue canMakePayments]) {
                [[SKPaymentQueue defaultQueue] addTransactionObserver: self];

                SKProductsRequest     * request     =
                [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithArray: productIdentifierList]];

                request.delegate    = self;
                [request start];
        }
        else {
                NSLog (@"SamsungPlasma: cannot make payment");
        }
}
- (void) buyShineAmazon
{
        [SKPaymentQueue setVendor: @"AmazonIAP"];

        NSMutableArray      * productIdentifierList;
        productIdentifierList = [[NSMutableArray alloc] initWithCapacity: 2];

        [productIdentifierList addObject: [NSString stringWithFormat: @"com.amazon.buttonclicker.purple_button"]];     /* available */
        [productIdentifierList addObject: [NSString stringWithFormat: @"com.amazon.buttonclicker.yellow_button"]];     /* unavailable */

        if ([SKPaymentQueue canMakePayments]) {
                [[SKPaymentQueue defaultQueue] addTransactionObserver: self];

                SKProductsRequest     * request     =
                [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithArray: productIdentifierList]];

                request.delegate    = self;
                [request start];
        }
        else {
                NSLog (@"AmazonIAP: cannot make payment");
        }
}

- (void) buyShineGooglePlay
{
        [SKPaymentQueue setVendor: @"GoogleIAB"];
        [SKPaymentQueue connectGoogleIAB];
        [SKPaymentQueue setPublicKeyGoogleIAB: @"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmxURrUC2RQYCqPLJGLerGeNZMmBQdlxoROI6peV8waMbSwcrc8+vG4tZhTxv+NwvPa281DbwA9xWQmsZOlNr3rRWJ2e4Bo12N5thFNKTjJGp5Bmd4uiHX5UYKNDJtHqWkteHzAqZO/EaLjHSjCCNZ+3hmzgNtl+eo51DwrjC9UKwbvj+5W2uE5469a5aBkPFICxkaQ4nBkyg9B8WNVXwJptYEqLqlfvpbn1FDu6JVOz1GM6icvCHI7Ta7TSUv/c5RmRcorr5xYRB6Ie8YVg/PyvcGt1BEl+/rC84B5bYfoSbQ3b5bPqMqlXHYgdYUtmra4NB2hRD0Ke3Z6sCJaJ+oQIDAQAB"];

        // [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];

        NSMutableArray      * productIdentifierList;
        productIdentifierList = [[NSMutableArray alloc] initWithCapacity: 2];

        [productIdentifierList addObject: [NSString stringWithFormat: @"android.test.purchased"]];                     // available
        // [productIdentifierList addObject: [NSString stringWithFormat: @"android.test.item_unavailable"]];              // unavailable

        if ([SKPaymentQueue canMakePayments]) {
                [[SKPaymentQueue defaultQueue] addTransactionObserver: self];

                SKProductsRequest     * request     =
                [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithArray: productIdentifierList]];

                request.delegate    = self;
                [request start];
        }
        else {
                NSLog (@"GoogleIAB: cannot make payment");
        }

}

- (void) productsRequest: (SKProductsRequest *) request didReceiveResponse: (SKProductsResponse *) response
{
        if (response.products.count == 0) {
                NSLog (@"product request contains no object");
                return;
        }

        for (int i = 0; i < response.products.count; i++) {
                SKProduct     * product     = [response.products objectAtIndex: i];
                NSLog (@"IAP sku: %@", product.productIdentifier);
                SKPayment     * payment     = [SKPayment paymentWithProductIdentifier: product.productIdentifier];

                [[SKPaymentQueue defaultQueue] addPayment: payment];
        }
}

- (void) paymentQueue: (SKPaymentQueue *) queue updatedTransactions: (NSArray *) transactions
{
        NSLog (@"payment queue updated transactions");
        for (SKPaymentTransaction * transaction in transactions) {
                switch (transaction.transactionState) {
                        case SKPaymentTransactionStatePurchased:
                                [self completeTransaction: transaction];
                                break;

                        case SKPaymentTransactionStateFailed:
                                [self failedTransaction: transaction];
                                break;

                        case SKPaymentTransactionStateRestored:
                                [self restoreTransaction: transaction];
                                break;

                        default: ;
                }
        }
}

- (void) failedTransaction: (SKPaymentTransaction *) transaction
{
        NSLog  (@"AppDelegate: failed transaction");
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) restoreTransaction: (SKPaymentTransaction *) transaction
{
        NSLog  (@"AppDelegate: restore transaction");
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) completeTransaction: (SKPaymentTransaction *) transaction
{
        NSLog  (@"AppDelegate: complete transaction");
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];

        #if defined (FREEMIUM_USING_PLASMA)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"plasmaPurchased" object: nil];
        #endif
}

#endif

#if defined (FREEMIUM_USING_TAPJOY)
- (void) showOffersTJC
{
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pointUpdatedTJC:) name: TJC_TAP_POINTS_RESPONSE_NOTIFICATION object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pointUpdatedTJC:) name: TJC_SPEND_TAP_POINTS_RESPONSE_NOTIFICATION object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pointUpdatedTJC:) name: TJC_AWARD_TAP_POINTS_RESPONSE_NOTIFICATION object: nil];

        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pointUpdateFailedTJC:) name: TJC_TAP_POINTS_RESPONSE_NOTIFICATION_ERROR object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pointUpdateFailedTJC:) name: TJC_SPEND_TAP_POINTS_RESPONSE_NOTIFICATION_ERROR object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pointUpdateFailedTJC:) name: TJC_AWARD_TAP_POINTS_RESPONSE_NOTIFICATION_ERROR object: nil];

        [TapjoyConnect requestTapjoyConnect: @"d61d0732-7ecd-4b6f-8d81-78170da1ad9b" secretKey: @"3kCT5osGYdx3r5Ri9tSR"];
        [TapjoyConnect getTapPoints];

        [TapjoyConnect showOffers];
}

- (void) pointUpdatedTJC: (NSNotification *) notification
{
        NSNumber      * points       = notification.object;
        NSLog (@"tapjoy point updated: %@ points", points);
}

- (void) pointUpdateFailedTJC: (NSNotification *) notification
{
        NSString      * error       = notification.object;
        NSLog (@"tapjoy failed to get updated points: %@", error);
}
#endif


#if defined (FREEMIUM_USING_CHARTBOOST)
- (void) showInterstitialCB
{
       Chartboost     * chartboost      = [Chartboost sharedChartboost];
       chartboost.appId                 = @"4f7b433509b6025804000002";
       chartboost.appSignature          = @"dd2d41b69ac01b80f443f5b6cf06096d457f82bd";

       [chartboost startSession];
       [chartboost showInterstitial];
}
#endif

#if defined (FREEMIUM_USING_ADCOLONY)
- (void) showADC
{
       Adcolony     * adcolony          = [Adcolony sharedAdcolony];
       adcolony.appId                   = @"app4dc1bc42a5529";
       adcolony.zoneId                  = @"z4dc1bc79c5fc9";

       [adcolony configure];
       [adcolony show];
}
#endif

@end
