import UIKit
import SwiftUI

struct RNMiniGameMenuWrapper: View {
    @Binding var isOpen: Bool
    
    let charName: String
    let charID: String
    let charImage: String
    let messages: [Message]
    let charDesc: String?
    let convId: String?
    let entryPoint: String?
    let maxGamesToShow: Int
    let theme: MiniGameTheme
    let delegateChar: Bool
    let showBanner: Bool
    
    let onGameOpen: ((String, String) -> Void)?
    let onGameClose: ((String) -> Void)?
    let onImpression: ((String) -> Void)?
    let onDestinationOpen: ((String, String) -> Void)?
    
    var body: some View {
        MiniGameMenu(
            isOpen: $isOpen,
            charName: charName,
            charID: charID,
            charImage: charImage,
            messages: messages,
            charDesc: charDesc,
            convId: convId,
            entryPoint: entryPoint,
            maxGamesToShow: maxGamesToShow,
            theme: theme,
            delegateChar: delegateChar,
            showBanner: showBanner,
            navigationType: "dot",
            onGameOpen: onGameOpen,
            onGameClose: onGameClose,
            onImpression: onImpression,
            onDestinationOpen: onDestinationOpen
        )
        .environmentObject(MiniGameProvider.shared)
    }
}

@objc(RNMiniGameMenuView)
public class RNMiniGameMenuView: UIView {
    
    @objc public var isOpen: Bool = false {
        didSet { updateView() }
    }
    @objc public var charName: String = "" {
        didSet { updateView() }
    }
    @objc public var charID: String = "" {
        didSet { updateView() }
    }
    @objc public var charImage: String = "" {
        didSet { updateView() }
    }
    @objc public var messages: [[String: String]] = [] {
        didSet { updateView() }
    }
    @objc public var charDesc: String? = nil {
        didSet { updateView() }
    }
    @objc public var convId: String? = nil {
        didSet { updateView() }
    }
    @objc public var entryPoint: String? = nil {
        didSet { updateView() }
    }
    @objc public var maxGamesToShow: NSNumber = 6 {
        didSet { updateView() }
    }
    @objc public var theme: NSDictionary? = nil {
        didSet { updateView() }
    }
    @objc public var delegateChar: Bool = true {
        didSet { updateView() }
    }
    @objc public var showBanner: Bool = true {
        didSet { updateView() }
    }
    
    @objc public var onGameOpen: RCTDirectEventBlock?
    @objc public var onGameClose: RCTDirectEventBlock?
    @objc public var onImpression: RCTDirectEventBlock?
    @objc public var onDestinationOpen: RCTDirectEventBlock?
    
    private var hostingController: UIHostingController<RNMiniGameMenuWrapper>?
    private var isGameScreenActive: Bool = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
    }
    
    private func updateView() {
        // Guard to ensure we have required fields before attempting to present anything
        guard isOpen, !charName.isEmpty, !charID.isEmpty else {
            if !isOpen && !isGameScreenActive {
                DispatchQueue.main.async {
                    self.dismissMenuModal()
                }
            }
            return
        }
        
        let parsedMessages = messages.map { dict -> Message in
            let role = dict["role"] ?? "user"
            let content = dict["content"] ?? ""
            return Message(role: role, content: content)
        }
        
        var parsedTheme = MiniGameTheme()
        if let themeDict = theme {
            parsedTheme.backgroundColor = themeDict["backgroundColor"] as? String
            parsedTheme.headerColor = themeDict["headerColor"] as? String
            parsedTheme.borderColor = themeDict["borderColor"] as? String
            parsedTheme.titleFont = themeDict["titleFont"] as? String
            parsedTheme.secondaryFont = themeDict["secondaryFont"] as? String
            parsedTheme.titleFontColor = themeDict["titleFontColor"] as? String
            parsedTheme.secondaryFontColor = themeDict["secondaryFontColor"] as? String
            parsedTheme.iconCornerRadius = themeDict["iconCornerRadius"] as? Int
            parsedTheme.accentColor = themeDict["accentColor"] as? String
            parsedTheme.playableHeight = themeDict["playableHeight"] as? String
            parsedTheme.playableBorderColor = themeDict["playableBorderColor"] as? String
        }
        
        let isOpenBinding = Binding<Bool>(
            get: { self.isOpen },
            set: { newValue in
                if self.isOpen != newValue {
                    self.isOpen = newValue
                    if !newValue {
                        self.onGameClose?(["gameName": "menu"])
                        if !self.isGameScreenActive {
                            self.dismissMenuModal()
                        }
                    }
                }
            }
        )
        
        let menuWrapper = RNMiniGameMenuWrapper(
            isOpen: isOpenBinding,
            charName: charName,
            charID: charID,
            charImage: charImage,
            messages: parsedMessages,
            charDesc: charDesc,
            convId: convId,
            entryPoint: entryPoint,
            maxGamesToShow: maxGamesToShow.intValue,
            theme: parsedTheme,
            delegateChar: delegateChar,
            showBanner: showBanner,
            onGameOpen: { [weak self] gameName, desc in
                self?.isGameScreenActive = true
                self?.onGameOpen?(["gameName": gameName, "description": desc])
            },
            onGameClose: { [weak self] gameName in
                self?.onGameClose?(["gameName": gameName])
                if gameName != "menu" {
                    self?.isGameScreenActive = false
                    DispatchQueue.main.async {
                        self?.dismissMenuModal()
                    }
                }
            },
            onImpression: { [weak self] menuId in
                self?.onImpression?(["menuId": menuId])
            },
            onDestinationOpen: { [weak self] type, target in
                self?.onDestinationOpen?(["destinationType": type, "target": target])
            }
        )
        
        DispatchQueue.main.async {
            self.presentMenuModal(with: menuWrapper)
        }
    }
    
    private func presentMenuModal(with wrapperView: RNMiniGameMenuWrapper) {
        guard let rootVC = AdDestinationPresenter.shared.getRootViewController() else { return }
        
        if let hc = self.hostingController {
            hc.rootView = wrapperView
        } else {
            let hc = UIHostingController(rootView: wrapperView)
            hc.modalPresentationStyle = .overFullScreen
            hc.modalTransitionStyle = .crossDissolve
            hc.view.backgroundColor = .clear
            self.hostingController = hc
            
            rootVC.present(hc, animated: false, completion: nil)
        }
    }
    
    private func dismissMenuModal() {
        if let hc = self.hostingController {
            hc.presentingViewController?.dismiss(animated: false, completion: nil)
            self.hostingController = nil
        }
    }
}
