//
//  TinyHUD.swift
//  TinyHUD
//
//  Created by liulishuo on 2021/8/3.
//

import Foundation
import SnapKit

// swiftlint:disable force_cast
let keyWindow = UIApplication.shared.windows.first!

public class TinyHUDContentView: UIView {
    class func registered(hud: TinyHUD.Type) {}
    func updateConstraints(hud: TinyHUD) {}
}

public typealias TinyHUDFactory = (_ context: JSON?) -> TinyHUDContentView?

public struct TinyHUDKey {
    let rawValue: String
}

final class TinyHUD: Operation {

    let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()
    var contentView: TinyHUDContentView?
    var hostView: UIView?
    var duration: TimeInterval = 1
    var delay: TimeInterval = 0
    var maskColor: UIColor?
    var position: Position = .mid

    var contentViewInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    var maxWidthRatio: CGFloat = 0.8
    var fixedWidthRatio: CGFloat?

    private var _executing = false
    private var _finished = false

    static private var hudFactories = [String: TinyHUDFactory]()

    static private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    static var currentHUD: TinyHUD? {
        return self.queue.operations.first { !$0.isCancelled && !$0.isFinished } as? TinyHUD
    }

    static var isQueueEnabled: Bool = true

    static func register(_ views: [TinyHUDContentView.Type]) {
        views.forEach { view in
            view.registered(hud: self)
        }
    }

    static func register(_ key: String, _ factory: @escaping TinyHUDFactory) {
        hudFactories[key] = factory
    }

    init(_ type: TinyHUDKey, _ content: TinyJSON?) {

        if let contentView = TinyHUD.hudFactories[type.rawValue]?(content) {
            self.contentView = contentView
            containerView.addSubview(contentView)
            backgroundView.addSubview(containerView)
        }

        super.init()
    }

    func show() {
        if !TinyHUD.isQueueEnabled {
            TinyHUD.cancelAll()
        }
        TinyHUD.queue.addOperation(self)
    }

    static func cancelAll() {
        queue.cancelAllOperations()
    }

    private func finish() {
        self.isExecuting = false
        self.isFinished = true

        backgroundView.backgroundColor = UIColor.clear
        backgroundView.isUserInteractionEnabled = true
    }
}

// chain methods
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
        TinyHUD.isQueueEnabled = false
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
        self.containerView.backgroundColor = color
        return self
    }

    func cornerRadius(_ radius: CGFloat) -> TinyHUD {
        self.containerView.layer.cornerRadius = radius
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

// override Operation
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
        guard isRunnable else { return }
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
        self.backgroundView.removeFromSuperview()
    }

    override func main() {

        DispatchQueue.main.async {
            self.backgroundView.setNeedsLayout()
            self.containerView.alpha = 0

            if let maskColor = self.maskColor {
                self.backgroundView.backgroundColor = maskColor
                self.backgroundView.isUserInteractionEnabled = true
            } else {
                self.backgroundView.isUserInteractionEnabled = false
            }

            if let hostView = self.hostView {
                hostView.addSubview(self.backgroundView)
            } else {
                keyWindow.addSubview(self.backgroundView)
            }

            self.backgroundView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            self.containerView.snp.makeConstraints { make in
                switch self.position {
                case .mid:
                    make.center.equalToSuperview()
                case .top:
                    make.centerX.equalToSuperview()
                    make.top.equalToSuperview().offset(100)
                case .bottom:
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().offset(-50)
                case .custom(let center):
                    make.center.equalTo(center)
                }

                if let fixedWidthRatio = self.fixedWidthRatio {
                    make.width.equalToSuperview().multipliedBy(fixedWidthRatio)
                } else {
                    make.width.lessThanOrEqualToSuperview().multipliedBy(self.maxWidthRatio)
                }
            }

            self.contentView?.snp.makeConstraints { make in
                make.edges.equalTo(self.contentViewInsets)
            }

            // 修复某些情况下的约束问题 或者 内容有变化需要更新约束
            self.contentView?.updateConstraints(hud: self)
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                self.containerView.alpha = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + self.duration) {
                    self.finish()
                    UIView.animate(
                        withDuration: 0.5,
                        animations: {
                            self.containerView.alpha = 0
                        },
                        completion: { _ in
                            self.backgroundView.removeFromSuperview()
                        }
                    )
                }
            }
        }
    }
}
