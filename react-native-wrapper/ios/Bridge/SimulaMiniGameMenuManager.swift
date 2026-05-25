import Foundation

@objc(SimulaMiniGameMenuManager)
public class SimulaMiniGameMenuManager: RCTViewManager {
    
    public override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    public override func view() -> UIView! {
        return RNMiniGameMenuView()
    }
}
