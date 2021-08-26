//
//  TinyHUDContentView.swift
//  TinyHUD
//
//  Created by liulishuo on 2021/8/4.
//
// swiftlint:disable force_cast
// swiftlint:disable type_name

import Foundation
import SnapKit
import CoreGraphics

extension TinyHUDKey {
    static let plainText = TinyHUDKey(rawValue: "plainText")
    static let success = TinyHUDKey(rawValue: "success")
    static let failure = TinyHUDKey(rawValue: "failure")
    static let info = TinyHUDKey(rawValue: "info")
}

class TinyHUDContentView_Text: TinyHUDContentView {
    let label = UILabel()

    override class func registered(hud: TinyHUD.Type) {
        hud.register(TinyHUDKey.plainText.rawValue) { (context) -> TinyHUDContentView? in
            let view = TinyHUDContentView_Text()
            view.label.numberOfLines = 0
            view.label.textColor = UIColor.white
            view.label.text = context?.stringValue
            view.addSubview(view.label)
            view.label.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            return view
        }
    }
}

class TinyHUDContentView_Image_Text: TinyHUDContentView {

    let imageView: UIImageView!
    let label: UILabel!
    let stackView: UIStackView!

    private var imageViewSize: CGSize = CGSize(width: 0, height: 0)

    init(text: String, image: UIImage, axis: NSLayoutConstraint.Axis = .vertical) {

        imageView = UIImageView()
        imageView.image = image

        if let cgi = image.cgImage {
            let width = CGFloat( cgi.width ) / UIScreen.main.scale
            let height = CGFloat( cgi.height ) / UIScreen.main.scale
            imageViewSize = CGSize(width: width, height: height)
            imageView.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: width, height: height))
            }
        }

        label = UILabel()
        label.text = text
        label.numberOfLines = 0

        stackView = UIStackView()
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.axis = axis
        stackView.spacing = 5

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)

        label.textColor = UIColor.white

        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

        self.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override init(frame: CGRect) {
        imageView = UIImageView()
        label = UILabel()
        stackView = UIStackView()
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints(hud: TinyHUD) {
        var labelSize: CGSize!
        let width = hud.hostView?.bounds.size.width ?? keyWindow.bounds.size.width
        if stackView.axis == .horizontal {
            let size = CGSize(width: width * hud.maxWidthRatio - hud.contentViewInsets.left - hud.contentViewInsets.right - stackView.spacing - imageView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude)
            labelSize = label.sizeThatFits(size)

            if imageViewSize.height > labelSize.height {
                imageView.snp.updateConstraints { make in
                    make.size.equalTo(CGSize(width: labelSize.height / imageViewSize.height * imageViewSize.width, height: labelSize.height))
                }
            }

        } else {
            let size = CGSize(width: width * hud.maxWidthRatio - hud.contentViewInsets.left - hud.contentViewInsets.right, height: CGFloat.greatestFiniteMagnitude)
            labelSize = label.sizeThatFits(size)

            if imageViewSize.width > labelSize.width {
                imageView.snp.updateConstraints { make in
                    make.size.equalTo(CGSize(width: labelSize.width, height: labelSize.width / imageViewSize.width * imageViewSize.height))
                }
            }
        }

        label.snp.makeConstraints { make in
            make.size.equalTo(labelSize)
        }
    }

    override class func registered(hud: TinyHUD.Type) {
        hud.register(TinyHUDKey.success.rawValue) { (context) -> TinyHUDContentView? in
            let view = TinyHUDContentView_Image_Text(text: context?.stringValue ?? "", image: UIImage(named: "check")!)
            return view
        }

        hud.register(TinyHUDKey.failure.rawValue) { (context) -> TinyHUDContentView? in
            let view = TinyHUDContentView_Image_Text(text: context?.stringValue ?? "", image: UIImage(named: "wrong")!)
            return view
        }

        hud.register(TinyHUDKey.info.rawValue) { (context) -> TinyHUDContentView? in
            let view = TinyHUDContentView_Image_Text(text: context?.stringValue ?? "", image: UIImage(named: "information")!, axis: .horizontal)
            return view
        }
    }
}
