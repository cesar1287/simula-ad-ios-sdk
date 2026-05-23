#import <React/RCTBridgeModule.h>
#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(SimulaAdSDK, NSObject)

RCT_EXTERN_METHOD(configure:(NSString *)apiKey
                  primaryUserID:(NSString *)primaryUserID
                  hasPrivacyConsent:(BOOL)hasPrivacyConsent
                  devMode:(BOOL)devMode
                  appDomain:(NSString *)appDomain)

@end

@interface RCT_EXTERN_MODULE(SimulaMiniGameMenuManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(isOpen, BOOL)
RCT_EXPORT_VIEW_PROPERTY(charName, NSString)
RCT_EXPORT_VIEW_PROPERTY(charID, NSString)
RCT_EXPORT_VIEW_PROPERTY(charImage, NSString)
RCT_EXPORT_VIEW_PROPERTY(messages, NSArray)
RCT_EXPORT_VIEW_PROPERTY(charDesc, NSString)
RCT_EXPORT_VIEW_PROPERTY(convId, NSString)
RCT_EXPORT_VIEW_PROPERTY(entryPoint, NSString)
RCT_EXPORT_VIEW_PROPERTY(maxGamesToShow, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(theme, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(delegateChar, BOOL)
RCT_EXPORT_VIEW_PROPERTY(showBanner, BOOL)

RCT_EXPORT_VIEW_PROPERTY(onGameOpen, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onGameClose, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onImpression, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onDestinationOpen, RCTDirectEventBlock)

@end
