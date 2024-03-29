//
//  TinyHUD.swift
//  TinyHUD
//
//  Created by liulishuo on 2021/8/3.
//

import Foundation
import UIKit

let mainWindow = UIApplication.shared.windows.first

public class TinyHUDView: UIView {
    class func registered(by hud: TinyHUD.Type) {}
    func updateConstraints(by hud: TinyHUD) {}
}

public struct TinyHUDKey {
    let rawValue: String
}

public typealias TinyHUDViewFactory = (_ context: JSON?) -> TinyHUDView?

/// View hierarchy:
///
/// hostView
///   ｜_ maskView (mask fill up the whole hostView) [optional]
///           |_ slotView (slot for TinyHUDView)
///                  |_ TinyHUDView (your custom view)

final class TinyHUD: Operation {

    var hostView: UIView?

    let maskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    /// Slot for your custom view
    var slotView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()

    var hudView: TinyHUDView?

    var duration: TimeInterval = 1

    var delay: TimeInterval = 0

    var maskColor: UIColor?

    var position: Position = .mid

    var contentViewInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    /// Ratio of hudView's maximum width to hostView's width
    var maxWidthRatio: CGFloat = 0.8

    /// HudView's width is fixed, a fixed ratio to hostView's width
    var fixedWidthRatio: CGFloat?

    private var _executing = false
    private var _finished = false

    static private var hudFactories = [String: TinyHUDViewFactory]()

    /// Register TinyHUDView
    static func register(_ views: [TinyHUDView.Type]) {
        views.forEach { view in
            view.registered(by: self)
        }
    }

    /// Register the initialization function of TinyHUDView
    static func register(_ key: String, _ factory: @escaping TinyHUDViewFactory) {
        hudFactories[key] = factory
    }

    static private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    static var currentHUD: TinyHUD? {
        return self.queue.operations.first { !$0.isCancelled && !$0.isFinished } as? TinyHUD
    }

    static var isQueueEnabled: Bool = true

    /// Init
    /// - Parameters:
    ///   - type: the key for the HUD view you had already registed
    ///   - content: the data for the HUD view
    /// - Attention: If you're not sure which thread you're on, please use
    /// static func onMain(_ type: TinyHUDKey, _ content: TinyJSON?, execute work: @escaping @convention(block) (TinyHUD) -> Void),
    /// or wrap the lines of code that call the UI API in DispatchQueue.main.async {}
    init(_ type: TinyHUDKey, _ content: TinyJSON?) {

        if let contentView = TinyHUD.hudFactories[type.rawValue]?(content) {
            self.hudView = contentView
            slotView.addSubview(contentView)
//            maskView.addSubview(slotView)
        }

        super.init()
    }

    static func onMain(_ type: TinyHUDKey, _ content: TinyJSON?, execute work: @escaping @convention(block) (TinyHUD) -> Void) {
        DispatchQueue.main.async {
            let hud = TinyHUD(type, content)
            work(hud)
        }
    }

    func show() {
        if !TinyHUD.isQueueEnabled {
            TinyHUD.cancelAll()
        }

        TinyHUD.queue.addOperation(self)
    }

    static func cancel() {
        currentHUD?.cancel()
    }

    static func cancelAll() {
        queue.cancelAllOperations()
    }

    private func finish() {
        self.isExecuting = false
        self.isFinished = true
    }
}

// MARK: override Operation
extension TinyHUD {

    override var isExecuting: Bool {
        get {
            return self._executing
        }
        set {
            self.willChangeValue(forKey: "isExecuting")
            self._executing = newValue
            self.didChangeValue(forKey: "isExecuting")
        }
    }

    override var isFinished: Bool {
        get {
            return self._finished
        }
        set {
            self.willChangeValue(forKey: "isFinished")
            self._finished = newValue
            self.didChangeValue(forKey: "isFinished")
        }
    }

    override func start() {
        let isRunnable = !self.isFinished && !self.isCancelled && !self.isExecuting
        guard isRunnable else {
            return
        }
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.start()
            }
            return
        }
        main()
    }

    override func cancel() {
        super.cancel()
        self.finish()
        if self.maskView.superview != nil {
            self.maskView.removeFromSuperview()
        } else {
            self.slotView.removeFromSuperview()
        }
    }

    override func main() {
        self.isExecuting = true

        DispatchQueue.main.async {
            if mainWindow == nil && self.hostView == nil {
                return
            }

            self.slotView.alpha = 0

            if let hostView = self.hostView {
                if let maskColor = self.maskColor {
                    hostView.addSubview(self.maskView)
                    self.maskView.backgroundColor = maskColor
                    self.maskView.ty.makeConstraints { view, superView in
                        view.left == superView.left
                        view.right == superView.right
                        view.top == superView.top
                        view.bottom == superView.bottom
                    }
                } else {
                    hostView.addSubview(self.slotView)
                }
            } else {
                if let maskColor = self.maskColor {
                    mainWindow?.addSubview(self.maskView)
                    self.maskView.backgroundColor = maskColor
                    self.maskView.ty.makeConstraints { view, superView in
                        view.left == superView.left
                        view.right == superView.right
                        view.top == superView.top
                        view.bottom == superView.bottom
                    }
                } else {
                    mainWindow?.addSubview(self.slotView)
                }
            }
            
            if let fixedWidthRatio = self.fixedWidthRatio {
                self.slotView.ty.makeConstraints { view, superView in
                    view.width == superView.width * fixedWidthRatio
                }
            } else {
                self.slotView.ty.makeConstraints { view, superView in
                    view.width <= superView.width * self.maxWidthRatio
                }
            }
            
            switch self.position {
            case .mid:
                self.slotView.ty.makeConstraints { view, superView in
                    view.centerX == superView.centerX
                    view.centerY == superView.centerY
                }
                
            case .top:
                self.slotView.ty.makeConstraints { view, superView in
                    view.centerX == superView.centerX
                    view.top == superView.top + 100
                }
            case .bottom:
                self.slotView.ty.makeConstraints { view, superView in
                    view.centerX == superView.centerX
                    view.bottom == superView.bottom - 50
                }
            case .custom(let center):
                self.slotView.ty.makeConstraints { view, superView in
                    view.centerX == superView.centerX + center.x
                    view.centerY == superView.centerY + center.y
                }
            }
            
            
            
            
            
            

//            self.slotView.snp.makeConstraints { make in
//                switch self.position {
//                case .mid:
//                    make.center.equalToSuperview()
//                case .top:
//                    make.centerX.equalToSuperview()
//                    make.top.equalToSuperview().offset(100)
//                case .bottom:
//                    make.centerX.equalToSuperview()
//                    make.bottom.equalToSuperview().offset(-50)
//                case .custom(let center):
//                    make.center.equalTo(center)
//                }
//
//                if let fixedWidthRatio = self.fixedWidthRatio {
//                    make.width.equalToSuperview().multipliedBy(fixedWidthRatio)
//                } else {
//                    make.width.lessThanOrEqualToSuperview().multipliedBy(self.maxWidthRatio)
//                }
//            }
            
            self.hudView?.ty.makeConstraints({ view, superView in
                view.left == superView.left + self.contentViewInsets.left
                view.right == superView.right - self.contentViewInsets.right
                view.top == superView.top + self.contentViewInsets.top
                view.bottom == superView.bottom - self.contentViewInsets.bottom
            })

//            self.hudView?.snp.makeConstraints { make in
//                make.edges.equalTo(self.contentViewInsets)
//            }

            self.hudView?.updateConstraints(by: self)

            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                self.slotView.alpha = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + self.duration) {
                    self.finish()
                    UIView.animate(
                        withDuration: 0.5,
                        animations: {
                            self.slotView.alpha = 0
                        },
                        completion: { _ in
                            if self.maskView.superview != nil {
                                self.maskView.removeFromSuperview()
                            } else {
                                self.slotView.removeFromSuperview()
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: chain methods
extension TinyHUD {
    func onViewController(_ viewController: UIViewController) -> TinyHUD {
        hostView = viewController.view
        return self
    }

    func onView(_ view: UIView) -> TinyHUD {
        hostView = view
        return self
    }

    func duration(_ duration: TimeInterval) -> TinyHUD {
        self.duration = duration
        return self
    }

    func delay(_ delay: TimeInterval) -> TinyHUD {
        self.delay = delay
        return self
    }

    func mask(color: UIColor = UIColor.black.withAlphaComponent(0.2)) -> TinyHUD {
        self.maskColor = color
        return self
    }

    enum Position {
        case top, mid, bottom
        case custom(CGPoint)
    }

    func position(_ position: Position) -> TinyHUD {
        self.position = position
        return self
    }

    func containerViewColor(_ color: UIColor) -> TinyHUD {
        self.slotView.backgroundColor = color
        return self
    }

    func cornerRadius(_ radius: CGFloat) -> TinyHUD {
        self.slotView.layer.cornerRadius = radius
        return self
    }

    func insets(_ insets: UIEdgeInsets) -> TinyHUD {
        contentViewInsets = insets
        return self
    }

    func maxWidthRatio(_ ratio: CGFloat) -> TinyHUD {
        self.maxWidthRatio = ratio
        return self
    }

    func fixedWidthRatio(_ ratio: CGFloat) -> TinyHUD {
        self.fixedWidthRatio = ratio
        return self
    }
}
