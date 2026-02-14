#!/usr/bin/env swift

import Foundation

// App icon sizes required for iOS
let iconSizes: [(size: Int, scale: Int, idiom: String)] = [
    // iPhone
    (20, 2, "iphone"),   // Notification @2x
    (20, 3, "iphone"),   // Notification @3x
    (29, 2, "iphone"),   // Settings @2x
    (29, 3, "iphone"),   // Settings @3x
    (40, 2, "iphone"),   // Spotlight @2x
    (40, 3, "iphone"),   // Spotlight @3x
    (60, 2, "iphone"),   // App @2x
    (60, 3, "iphone"),   // App @3x
    
    // iPad
    (20, 1, "ipad"),     // Notification @1x
    (20, 2, "ipad"),     // Notification @2x
    (29, 1, "ipad"),     // Settings @1x
    (29, 2, "ipad"),     // Settings @2x
    (40, 1, "ipad"),     // Spotlight @1x
    (40, 2, "ipad"),     // Spotlight @2x
    (76, 1, "ipad"),     // App @1x
    (76, 2, "ipad"),     // App @2x
    (83, 2, "ipad"),     // Pro @2x (83.5pt)
    
    // iOS Marketing
    (1024, 1, "ios-marketing"),  // App Store
]

// Generate Contents.json for Assets.xcassets
var images: [[String: Any]] = []

for (size, scale, idiom) in iconSizes {
    let pixelSize = size * scale
    let filename = "AppIcon-\(size)x\(size)@\(scale)x.png"
    
    var imageDict: [String: Any] = [
        "size": "\(size)x\(size)",
        "idiom": idiom,
        "filename": filename,
        "scale": "\(scale)x"
    ]
    
    // Special case for iPad Pro 83.5pt
    if size == 83 && scale == 2 {
        imageDict["size"] = "83.5x83.5"
    }
    
    images.append(imageDict)
}

let contents: [String: Any] = [
    "images": images,
    "info": [
        "author": "xcode",
        "version": 1
    ]
]

// Print the JSON
let jsonData = try! JSONSerialization.data(withJSONObject: contents, options: .prettyPrinted)
let jsonString = String(data: jsonData, encoding: .utf8)!

print("Save this to Assets.xcassets/AppIcon.appiconset/Contents.json:")
print(jsonString)

// Create directory structure
let fm = FileManager.default
let assetsPath = "Assets.xcassets/AppIcon.appiconset"

try? fm.createDirectory(atPath: assetsPath, withIntermediateDirectories: true, attributes: nil)

let contentsPath = "\(assetsPath)/Contents.json"
try? jsonString.write(toFile: contentsPath, atomically: true, encoding: .utf8)

print("\nCreated: \(contentsPath)")
print("\nNote: To generate the actual PNG icons, you need to:")
print("1. Open the project in Xcode")
print("2. Use the AppIconView preview to export a 1024x1024 image")
print("3. Or use the canvas to render and export")
print("4. Then use an icon generator tool to create all sizes")
print("\nAlternatively, you can use a placeholder system for now.")