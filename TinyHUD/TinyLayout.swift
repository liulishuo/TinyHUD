import UIKit

extension UIView: TinyExtended {}

extension TinyWrapper where Base : UIView {
    func makeConstraints(@ConstraintsBuilder _ make: (_ view: UIView, _ superView: UIView) -> [NSLayoutConstraint]) {
        if let superview = base.superview {
            base.translatesAutoresizingMaskIntoConstraints = false
            let constraints = make(base, superview)
            NSLayoutConstraint.activate(constraints)
            base.ty_add(constraints: constraints)
        }
    }
    
    func updateConstraints(@ConstraintsBuilder _ make: (_ view: UIView, _ superView: UIView) -> [NSLayoutConstraint]) {
        if let superview = base.superview {
            let newConstraints = make(base, superview)
            
            if let oldConstraints = base.ty_constraintsSet as? Set<NSLayoutConstraint> {
                for newConstraint in newConstraints {
                    let updateLayoutConstraint = oldConstraints.first { l in
                        l == newConstraint
                    }
                    updateLayoutConstraint?.constant = newConstraint.constant
                }
            }
        }
    }
    
    func remakeConstraints(@ConstraintsBuilder _ make: (_ view: UIView, _ superView: UIView) -> [NSLayoutConstraint]) {
        base.ty_removeConstraints()
        makeConstraints(make)
    }
    
    func removeConstraints() {
        base.ty_removeConstraints()
    }
}

extension UILayoutGuide: TinyExtended {}

extension TinyWrapper where Base : UILayoutGuide {
    func makeConstraints(@ConstraintsBuilder _ make: (_ guide: UILayoutGuide, _ superView: UIView) -> [NSLayoutConstraint]) {
        if let superview = base.owningView {
            let constraints = make(base, superview)
            NSLayoutConstraint.activate(constraints)
            base.ty_add(constraints: constraints)
        }
    }
    
    func updateConstraints(@ConstraintsBuilder _ make: (_ guide: UILayoutGuide, _ superView: UIView) -> [NSLayoutConstraint]) {
        if let superview = base.owningView {
            let newConstraints = make(base, superview)
            
            if let oldConstraints = base.ty_constraintsSet as? Set<NSLayoutConstraint> {
                for newConstraint in newConstraints {
                    let updateLayoutConstraint = oldConstraints.first { l in
                        l == newConstraint
                    }
                    updateLayoutConstraint?.constant = newConstraint.constant
                }
            }
        }
    }
    
    func remakeConstraints(@ConstraintsBuilder _ make: (_ guide: UILayoutGuide, _ superView: UIView) -> [NSLayoutConstraint]) {
        base.ty_removeConstraints()
        makeConstraints(make)
    }
    
    func removeConstraints() {
        base.ty_removeConstraints()
    }
}

@resultBuilder struct ConstraintsBuilder {
    static func buildBlock<NSLayoutConstraint>(_ constraints: NSLayoutConstraint...) -> [NSLayoutConstraint] { constraints }
}

public struct LayoutContext {
    let item: AnyObject
    let attribute: NSLayoutConstraint.Attribute
    let multiplier: CGFloat
    let constant: CGFloat
    
    fileprivate func constrain(_ second: LayoutContext, relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: item,
                                  attribute: attribute,
                                  relatedBy: relation,
                                  toItem: second.item,
                                  attribute: second.attribute,
                                  multiplier: second.multiplier,
                                  constant: second.constant)
    }
    
    fileprivate func constrain(_ constant: CGFloat, relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: item,
                                  attribute: attribute,
                                  relatedBy: relation,
                                  toItem: nil,
                                  attribute: .notAnAttribute,
                                  multiplier: 1.0,
                                  constant: constant)
    }
}

protocol UILayoutRegion: AnyObject {}
extension UIView: UILayoutRegion {}
extension UILayoutGuide: UILayoutRegion {}

extension UILayoutRegion {
    var left: LayoutContext { context(.left) }
    var right: LayoutContext { context(.right) }
    var top: LayoutContext { context(.top) }
    var bottom: LayoutContext { context(.bottom) }
    var leading: LayoutContext { context(.leading) }
    var trailing: LayoutContext { context(.trailing) }
    var width: LayoutContext { context(.width) }
    var height: LayoutContext { context(.height) }
    var centerX: LayoutContext { context(.centerX) }
    var centerY: LayoutContext{ context(.centerY) }
    var lastBaseline: LayoutContext { context(.lastBaseline) }
    var firstBaseline: LayoutContext { context(.firstBaseline) }
    var leftMargin: LayoutContext { context(.leftMargin) }
    var rightMargin: LayoutContext { context(.rightMargin) }
    var topMargin: LayoutContext { context(.topMargin) }
    var bottomMargin: LayoutContext { context(.bottomMargin) }
    var leadingMargin: LayoutContext { context(.leadingMargin) }
    var trailingMargin: LayoutContext { context(.trailingMargin) }
    var centerXWithinMargins: LayoutContext { context(.centerXWithinMargins) }
    var centerYWithinMargins: LayoutContext { context(.centerYWithinMargins) }
    
    fileprivate func context(_ attribute: NSLayoutConstraint.Attribute) -> LayoutContext {
        return LayoutContext(item: self, attribute: attribute, multiplier: 1.0, constant: 0.0)
    }
}

// MARK: Operator Overloading

precedencegroup PriorityPrecedence {
    lowerThan: ComparisonPrecedence
    higherThan: AssignmentPrecedence
}
infix operator ~ : PriorityPrecedence

func ~(left: NSLayoutConstraint, right: UILayoutPriority) -> NSLayoutConstraint {
    let newConstraint = NSLayoutConstraint(item: left.firstItem as Any,
                                           attribute: left.firstAttribute,
                                           relatedBy: left.relation,
                                           toItem: left.secondItem,
                                           attribute: left.secondAttribute,
                                           multiplier: left.multiplier,
                                           constant: left.constant)
    newConstraint.priority = right
    return newConstraint
}

func ==(lhs: NSLayoutConstraint, rhs: NSLayoutConstraint) -> Bool {
    guard lhs.firstAttribute == rhs.firstAttribute &&
            lhs.secondAttribute == rhs.secondAttribute &&
            lhs.relation == rhs.relation &&
            lhs.priority == rhs.priority &&
            lhs.multiplier == rhs.multiplier &&
            lhs.secondItem === rhs.secondItem &&
            lhs.firstItem === rhs.firstItem else {
        return false
    }
    return true
}

func *(left: LayoutContext, right: CGFloat) -> LayoutContext {
    LayoutContext(item: left.item, attribute: left.attribute, multiplier: left.multiplier * right, constant: left.constant)
}

func /(left: LayoutContext, right: CGFloat) -> LayoutContext {
    LayoutContext(item: left.item, attribute: left.attribute, multiplier: left.multiplier / right, constant: left.constant)
}

func +(left: LayoutContext, right: CGFloat) -> LayoutContext {
    LayoutContext(item: left.item, attribute: left.attribute, multiplier: left.multiplier, constant: left.constant + right)
}

func -(left: LayoutContext, right: CGFloat) -> LayoutContext {
    LayoutContext(item: left.item, attribute: left.attribute, multiplier: left.multiplier, constant: left.constant - right)
}

func ==(left: LayoutContext, right: LayoutContext) -> NSLayoutConstraint {
    return left.constrain(right, relation: .equal)
}

func ==(left: LayoutContext, right: CGFloat) -> NSLayoutConstraint {
    return left.constrain(right, relation: .equal)
}

func >=(left: LayoutContext, right: LayoutContext) -> NSLayoutConstraint {
    return left.constrain(right, relation: .greaterThanOrEqual)
}

func >=(left: LayoutContext, right: CGFloat) -> NSLayoutConstraint {
    return left.constrain(right, relation: .greaterThanOrEqual)
}

func <=(left: LayoutContext, right: LayoutContext) -> NSLayoutConstraint {
    return left.constrain(right, relation: .lessThanOrEqual)
}

func <=(left: LayoutContext, right: CGFloat) -> NSLayoutConstraint {
    return left.constrain(right, relation: .lessThanOrEqual)
}


// MARK: Shortcut for UILayoutPriority

extension UILayoutPriority: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Float) {
        self = UILayoutPriority(value)
    }
}

extension UILayoutPriority: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = UILayoutPriority(Float(value))
    }
}

// MARK: Name Space => ty

public struct TinyWrapper<Base> {
    public private(set) var base: Base
    
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol TinyExtended {
    associatedtype ExtendedType
    
    static var ty: TinyWrapper<ExtendedType>.Type { get set }
    
    var ty: TinyWrapper<ExtendedType> { get set }
}

extension TinyExtended {
    public static var ty: TinyWrapper<Self>.Type {
        get { TinyWrapper<Self>.self }
        set {}
    }
    
    public var ty: TinyWrapper<Self> {
        get { TinyWrapper(self) }
        set {}
    }
}

// MARK: Extension for UILayoutRegion to hold constraints

private var constraintsKey: UInt8 = 0
extension UILayoutRegion {
    fileprivate func ty_add(constraints: [NSLayoutConstraint]) {
        let constraintsSet = self.ty_constraintsSet
        constraintsSet.addObjects(from: constraints)
    }
    
    fileprivate var ty_constraintsSet: NSMutableSet {
        let constraintsSet: NSMutableSet
        
        if let existing = objc_getAssociatedObject(self, &constraintsKey) as? NSMutableSet {
            constraintsSet = existing
        } else {
            constraintsSet = NSMutableSet()
            objc_setAssociatedObject(self, &constraintsKey, constraintsSet, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return constraintsSet
    }
    
    fileprivate func ty_removeConstraints() {
        
        let constraintsSetM = self.ty_constraintsSet
        if let constraints = constraintsSetM.allObjects as? [NSLayoutConstraint] {
            NSLayoutConstraint.deactivate(constraints)
        }
        constraintsSetM.removeAllObjects()
    }
}

