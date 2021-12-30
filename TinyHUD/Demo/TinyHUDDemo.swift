//
//  TinyHUDDemo.swift
//  TinyHUD
//
//  Created by liulishuo on 2021/8/6.
//

import Foundation
import UIKit

class TinyHUDDemo: UITableViewController {

    var data: JSON = [
        [
            "title": "Position",
            "row": ["Top", "Mid", "Bottom", "Custom"]
        ],

        [
            "title": "Delay",
            "row": ["first then second",
                    "delay first then second"]
        ],

        [
            "title": "Mask",
            "row": ["enable mask, disable background userInteraction（clear）",
                    "enable mask, disable background userInteraction （color）"]
        ],

        [
            "title": "HostView",
            "row": ["current viewController's view", "keyWindow", "keyWindow2"]
        ],

        [
            "title": "MaxWidthRatio",
            "row": ["50%", "20%"]
        ],

        [
            "title": "Custom View",
            "row": ["success", "failure", "info", "with tap gesture"]
        ]
    ]
    var navButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = RespondingButton(type: .custom)
        button.setTitle("Show Keyboard", for: .normal)
        button.setTitleColor(UIColor.blue, for: .normal)
        button.addTarget(self, action: #selector(keyboardButtonTouchUpInside), for: .touchUpInside)
        navButton = UIBarButtonItem(customView: button)

        navigationItem.rightBarButtonItem = navButton
    }

    @objc dynamic func keyboardButtonTouchUpInside(sender: RespondingButton) {
      if sender.isFirstResponder {
        sender.resignFirstResponder()
      } else {
        sender.becomeFirstResponder()
      }
    }
}

extension TinyHUDDemo {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.arrayValue.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section]["row"].arrayValue.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return data[section]["title"].stringValue
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
            cell?.textLabel?.numberOfLines = 0
        }

        cell?.textLabel?.text = data[indexPath.section]["row"][indexPath.row].stringValue

        return cell ?? UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            TinyHUD(.plainText, "top").position(.top).show()
        case (0, 1):
            TinyHUD(.plainText, "mid").show()
        case (0, 2):
            TinyHUD(.plainText, "Bottom").position(.bottom).show()
        case (0, 3):
            TinyHUD(.plainText, "Custom").position(.custom(CGPoint(x: 100, y: 100))).show()
        case (1, 0):
            TinyHUD(.plainText, "first").show()
            TinyHUD(.plainText, "second").show()
        case (1, 1):
            TinyHUD(.plainText, "first").delay(1).show()
            TinyHUD(.plainText, "second").show()
        case (2, 0):
            TinyHUD(.plainText, "mask clear").mask(color: UIColor.clear).show()
        case (2, 1):
            TinyHUD(.plainText, "mask color").mask(color: UIColor.red.withAlphaComponent(0.2)).show()
        case (3, 0):
            if let cell = tableView.cellForRow(at: indexPath) {
                TinyHUD(.plainText, "current View").onView(cell.contentView).duration(5).show()
            }

            let viewController = UIViewController()
            viewController.view.backgroundColor = UIColor.white
            self.navigationController?.pushViewController(viewController, animated: true)
        case (3, 1):
            TinyHUD(.plainText, "keyWindow").show()
            let viewController = UIViewController()
            viewController.view.backgroundColor = UIColor.white
            self.navigationController?.pushViewController(viewController, animated: true)
        case (3, 2):
            TinyHUD(.plainText, "keyWindow2").position(.bottom).duration(10).show()
        case (4, 0):
            TinyHUD(.plainText, "12345678901234567890").maxWidthRatio(0.5).show()
        case (4, 1):
            TinyHUD(.plainText, "12345678901234567890").maxWidthRatio(0.2).show()
        case (5, 0):
            TinyHUD(.success, "1234567890123456789012345678901234567890").show()
        case (5, 1):
            TinyHUD(.failure, "1234567890123456789012345678901234567890").maxWidthRatio(0.5).show()
        case (5, 2):
            TinyHUD(.info, "1234567890123456789012345678901234567890")
                .maxWidthRatio(0.5)
                .show()
        case (5, 3):
            TinyHUD(.demoTap, "with tap gesture")
                .duration(10)
                .show()
        default:
            break
        }
    }
}

class RespondingButton: UIButton, UIKeyInput {
  override var canBecomeFirstResponder: Bool {
    return true
  }
  var hasText: Bool = true
  var autocorrectionType: UITextAutocorrectionType = .no
  func insertText(_ text: String) {}
  func deleteBackward() {}
}
