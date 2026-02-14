#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO

// Create the app icon using CoreGraphics (L-shaped tetromino only)
func createAppIcon(size: CGSize) -> CGImage? {
    let width = Int(size.width)
    let height = Int(size.height)
    
    // Create bitmap context
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
    ) else {
        return nil
    }
    
    // Fill background with dark gradient-like color
    let backgroundColor = CGColor(red: 0.12, green: 0.12, blue: 0.2, alpha: 1.0)
    context.setFillColor(backgroundColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    
    // Calculate block size based on icon size
    let blockSize = CGFloat(width) / 5.5
    let spacing: CGFloat = max(2, CGFloat(width) / 60.0)
    let cornerRadius = max(4, blockSize / 6.0)
    
    // Orange color for L piece (vibrant orange)
    let orangeColor = CGColor(red: 1.0, green: 0.55, blue: 0.1, alpha: 1.0)
    let highlightColor = CGColor(red: 1.0, green: 0.75, blue: 0.4, alpha: 0.5)
    let shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.35)
    
    // Helper to draw a block
    func drawBlock(x: CGFloat, y: CGFloat) {
        let rect = CGRect(x: x, y: y, width: blockSize, height: blockSize)
        
        // Draw shadow
        context.saveGState()
        context.setShadow(offset: CGSize(width: max(2, CGFloat(width)/100), height: max(2, CGFloat(width)/100)), 
                          blur: max(4, CGFloat(width)/50), 
                          color: shadowColor)
        
        // Draw block
        context.setFillColor(orangeColor)
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        context.addPath(path)
        context.fillPath()
        context.restoreGState()
        
        // Draw highlight (inner bevel)
        let highlightInset = blockSize / 8
        let highlightRect = rect.insetBy(dx: highlightInset, dy: highlightInset)
        let highlightPath = CGPath(roundedRect: highlightRect, cornerWidth: cornerRadius/2, cornerHeight: cornerRadius/2, transform: nil)
        context.setFillColor(highlightColor)
        context.addPath(highlightPath)
        context.fillPath()
    }
    
    // Draw L shape centered and slightly rotated
    context.saveGState()
    
    // Center the L shape
    let centerX = CGFloat(width) / 2
    let centerY = CGFloat(height) / 2
    context.translateBy(x: centerX, y: centerY)
    context.rotate(by: 0.26) // ~15 degrees in radians
    
    // L shape pattern:
    // [X][ ][ ]
    // [X][X][X]
    let lWidth = blockSize * 3 + spacing * 2
    let lHeight = blockSize * 2 + spacing
       let offsetX = -lWidth / 2
    let offsetY = -lHeight / 2
    
    // Top block (left position)
    drawBlock(x: offsetX, y: offsetY)
    
    // Bottom row (three blocks)
    for i in 0..<3 {
        drawBlock(x: offsetX + CGFloat(i) * (blockSize + spacing), 
                  y: offsetY + blockSize + spacing)
    }
    
    context.restoreGState()
    
    // Draw "L" text (initial of Lars) in white cursive style
    let textScale = CGFloat(width) / 1024.0
    let fontSize = 300 * textScale
    
    // Draw a stylized "L" that looks like cursive
    context.saveGState()
    context.translateBy(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
    context.rotate(by: -0.17) // ~-10 degrees
    
    // Draw "Lars" text path manually
    let textColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1.0)
    context.setFillColor(textColor)
    context.setShadow(offset: CGSize(width: 3*textScale, height: 3*textScale), 
                      blur: 4*textScale, 
                      color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
    
    // Simplified "L" letter path (cursive style)
    let lPath = CGMutablePath()
    let letterSize = fontSize
    let lx = -letterSize * 0.3
    let ly = letterSize * 0.1
    
    // Draw cursive L
    lPath.move(to: CGPoint(x: lx, y: ly - letterSize * 0.4))
    lPath.addCurve(to: CGPoint(x: lx + letterSize * 0.3, y: ly + letterSize * 0.3),
                   control1: CGPoint(x: lx - letterSize * 0.1, y: ly - letterSize * 0.1),
                   control2: CGPoint(x: lx - letterSize * 0.05, y: ly + letterSize * 0.4))
    lPath.addCurve(to: CGPoint(x: lx + letterSize * 0.5, y: ly - letterSize * 0.1),
                   control1: CGPoint(x: lx + letterSize * 0.4, y: ly + letterSize * 0.35),
                   control2: CGPoint(x: lx + letterSize * 0.55, y: ly + letterSize * 0.15))
    
    context.setLineWidth(letterSize * 0.15)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.addPath(lPath)
    context.strokePath()
    
    // Small loop at bottom (cursive style)
    let loopPath = CGMutablePath()
    loopPath.move(to: CGPoint(x: lx + letterSize * 0.5, y: ly - letterSize * 0.1))
    loopPath.addQuadCurve(to: CGPoint(x: lx + letterSize * 0.65, y: ly + letterSize * 0.05),
                          control: CGPoint(x: lx + letterSize * 0.6, y: ly - letterSize * 0.15))
    context.addPath(loopPath)
    context.strokePath()
    
    context.restoreGState()
    
    return context.makeImage()
}

// Generate icons
let fm = FileManager.default
let assetsPath = "Assets.xcassets/AppIcon.appiconset"

// Create directory if needed
try? fm.createDirectory(atPath: assetsPath, withIntermediateDirectories: true)

// Icon sizes to generate
let sizes: [(name: String, size: Int)] = [
    ("AppIcon-20x20@1x", 20),
    ("AppIcon-20x20@2x", 40),
    ("AppIcon-20x20@3x", 60),
    ("AppIcon-29x29@1x", 29),
    ("AppIcon-29x29@2x", 58),
    ("AppIcon-29x29@3x", 87),
    ("AppIcon-40x40@1x", 40),
    ("AppIcon-40x40@2x", 80),
    ("AppIcon-40x40@3x", 120),
    ("AppIcon-60x60@2x", 120),
    ("AppIcon-60x60@3x", 180),
    ("AppIcon-76x76@1x", 76),
    ("AppIcon-76x76@2x", 152),
    ("AppIcon-83x83@2x", 167),
    ("AppIcon-1024x1024@1x", 1024),
]

print("Generating app icons...")

let pngType = "public.png" as CFString

for (name, size) in sizes {
    let filename = "\(assetsPath)/\(name).png"
    
    guard let image = createAppIcon(size: CGSize(width: size, height: size)) else {
        print("✗ Failed to create image for \(name)")
        continue
    }
    
    guard let destination = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: filename) as CFURL,
        pngType,
        1,
        nil
    ) else {
        print("✗ Failed to create destination for \(name)")
        continue
    }
    
    CGImageDestinationAddImage(destination, image, nil)
    
    if CGImageDestinationFinalize(destination) {
        print("✓ Created \(filename) (\(size)x\(size))")
    } else {
        print("✗ Failed to save \(filename)")
    }
}

print("\nDone! All app icons generated.")