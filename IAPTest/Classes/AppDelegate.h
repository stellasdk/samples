/*
 * Copyright (c) 2011 Yeecco Limited
 */

#import <UIKit/UIKit.h>

@class EAGLView;

#define FREEMIUM_USING_PLASMA
#define FREEMIUM_USING_GOOGLEIAB
#define FREEMIUM_USING_AMAZONIAP

#define FREEMIUM_USING_TAPJOY
#define FREEMIUM_USING_CHARTBOOST
#define FREEMIUM_USING_ADCOLONY

#if defined (__STELLA_VERSION_MAX_ALLOWED)
#import <StellaStore/StellaStore.h>
#endif
#if defined (FREEMIUM_USING_TAPJOY)
#import <StellaMarket/TapjoyConnect.h>
#endif
#if defined (FREEMIUM_USING_CHARTBOOST)
#import <StellaMarket/Chartboost.h>
#endif
#if defined (FREEMIUM_USING_ADCOLONY)
#import <StellaMarket/AdColony.h>
#endif

@interface AppDelegate : NSObject <UIApplicationDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
        IBOutlet UIWindow     * window;
        IBOutlet EAGLView     * glView;
}

@property(nonatomic, retain) UIWindow      * window;

- (void) applicationDidFinishLaunching: (UIApplication *) application;
- (void) applicationWillResignActive: (UIApplication *) application;
- (void) applicationDidBecomeActive: (UIApplication *) application;
- (void) applicationWillTerminate: (UIApplication *) application;

- (void) dealloc;

- (void) buyShineGooglePlay;
- (void) buyShinePlasma;
- (void) buyShineAmazon;

- (void) productsRequest: (SKProductsRequest *) request didReceiveResponse: (SKProductsResponse *) response;
- (void) paymentQueue: (SKPaymentQueue *) queue updatedTransactions: (NSArray *) transactions;

- (void) failedTransaction: (SKPaymentTransaction *) transaction;
- (void) restoreTransaction: (SKPaymentTransaction *) transaction;
- (void) completeTransaction: (SKPaymentTransaction *) transaction;

#if defined (FREEMIUM_USING_TAPJOY)
- (void) showOffersTJC;
- (void) pointUpdateFailedTJC: (NSNotification *) notification;
- (void) pointUpdatedTJC: (NSNotification *) notification;
#endif

#if defined (FREEMIUM_USING_CHARTBOOST)
- (void) showInterstitialCB;
#endif

#if defined (FREEMIUM_USING_ADCOLONY)
- (void) showADC;
#endif

@end

