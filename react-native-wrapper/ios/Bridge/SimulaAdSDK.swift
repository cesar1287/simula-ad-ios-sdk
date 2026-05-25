import Foundation

@objc(SimulaAdSDK)
public class SimulaAdSDK: NSObject, RCTBridgeModule {
    
    public static func moduleName() -> String! {
        return "SimulaAdSDK"
    }
    
    public static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc(configure:primaryUserID:hasPrivacyConsent:devMode:appDomain:)
    public func configure(
        apiKey: String,
        primaryUserID: String?,
        hasPrivacyConsent: Bool,
        devMode: Bool,
        appDomain: String?
    ) {
        DispatchQueue.main.async {
            MiniGameProvider.shared.configure(
                apiKey: apiKey,
                primaryUserID: primaryUserID,
                hasPrivacyConsent: hasPrivacyConsent,
                devMode: devMode,
                appDomain: appDomain
            )
        }
    }
}
