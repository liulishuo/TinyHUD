# TinyHUD

A tiny HUD for Swift

## Features

- Support mask, queue,  custom position,  delay
- Free to customization： In fact, you can show any view you want，your view and HUD are fully decoupled
- Support chaining Grammar 

## Getting Started

### Set Position

```swift
TinyHUD(.plainText, "top").position(.top).show()
TinyHUD(.plainText, "mid").show()
TinyHUD(.plainText, "Bottom").position(.bottom).show()
TinyHUD(.plainText, "Custom").position(.custom(CGPoint(x: 100, y: 100))).show()
```

<img src="/Screenshots/1.png" alt="1" style="width:50%; height:50%" />

### Set Delay

```swift
TinyHUD(.plainText, "first").delay(1).show()
```

### Set Mask

```swift
TinyHUD(.plainText, "mask clear").mask(color: UIColor.clear).show()
TinyHUD(.plainText, "mask color").mask(color: UIColor.red.withAlphaComponent(0.2)).show()
```

<img src="/Screenshots/2.png" alt="2" style="width:50%; height:50%" />

### Show on the specified view

HUD will show on the window by default，use .onView() change this behavior

```swift
TinyHUD(.plainText, "current View").onView(cell.contentView).duration(5).show()
```

### Set MaxWidthRatio

MaxWidthRatio is the ratio of hudView's maximum width to hostView's width, default is 0.8

```swift
TinyHUD(.plainText, "12345678901234567890").maxWidthRatio(0.2).show()
```

<img src="/Screenshots/3.png" alt="3" style="width:50%; height:50%" />

### Safe API

If you're not sure which thread you're on, please use this API:

```swift
TinyHUD.onMain(.plainText, "solution 1") { $0.show() }
```

It is a syntactic sugar for this:

```swift
DispatchQueue.main.async {
                    TinyHUD(.plainText, "solution 2").show()
                }
```

### Register your own HUD View

```swift
TinyHUD.register([TinyHUDView_Text.self, TinyHUDView_Image_Text.self, TinyHUDView_Text_Tap.self])
```

<img src="/Screenshots/4.png" alt="4" style="width:25%; height:25%" /><img src="/Screenshots/5.png" alt="5" style="width:25%; height:25%" /><img src="/Screenshots/6.png" alt="6" style="width:25%; height:25%" />

### UML

<img src="/Screenshots/7.png" alt="7" style="width:50%; height:50%" />
