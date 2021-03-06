import UIKit

@objc(WMFFontFamily) public enum FontFamily: Int {
    case system
    case georgia
}

@objc (WMFDynamicTextStyle) public class DynamicTextStyle: NSObject {
    @objc public static let subheadline = DynamicTextStyle(.system, .subheadline)
    @objc public static let semiboldSubheadline = DynamicTextStyle(.system, .subheadline, .semibold)
    public static let mediumSubheadline = DynamicTextStyle(.system, .subheadline, .medium)
    
    public static let headline = DynamicTextStyle(.system, .headline)
    public static let heavyHeadline = DynamicTextStyle(.system, .headline, .heavy)

    public static let footnote = DynamicTextStyle(.system, .footnote)
    @objc public static let semiboldFootnote = DynamicTextStyle(.system, .footnote, .semibold)

    public static let boldTitle1 = DynamicTextStyle(.system, .title1, .bold)
    public static let heavyTitle1 = DynamicTextStyle(.system, .title1, .heavy)

    public static let title3 = DynamicTextStyle(.system, .title3)
    
    public static let body = DynamicTextStyle(.system, .body)
    public static let semiboldBody = DynamicTextStyle(.system, .body, .semibold)
    
    public static let caption1 = DynamicTextStyle(.system, .caption1)
    public static let caption2 = DynamicTextStyle(.system, .caption2)
    public static let semiboldCaption2 = DynamicTextStyle(.system, .caption2, .semibold)
    public static let italicCaption2 = DynamicTextStyle(.system, .caption2, .regular, [.traitItalic])

    @objc public static let georgiaTitle1 = DynamicTextStyle(.georgia, .title1)
    public static let georgiaTitle3 = DynamicTextStyle(.georgia, .title3)

    let family: FontFamily
    let style: UIFontTextStyle
    let weight: UIFont.Weight
    let traits: UIFontDescriptorSymbolicTraits
    
    init(_ family: FontFamily = .system, _ style: UIFontTextStyle, _ weight: UIFont.Weight = .regular, _ traits: UIFontDescriptorSymbolicTraits = []) {
        self.family = family
        self.weight = weight
        self.traits = traits
        self.style = style
    }
    
    func with(weight: UIFont.Weight) -> DynamicTextStyle {
        return DynamicTextStyle(family, style, weight, traits)
    }
    
    func with(traits: UIFontDescriptorSymbolicTraits) -> DynamicTextStyle {
        return DynamicTextStyle(family, style, weight, traits)
    }
    
    func with(weight: UIFont.Weight, traits: UIFontDescriptorSymbolicTraits) -> DynamicTextStyle {
        return DynamicTextStyle(family, style, weight, traits)
    }
}

let fontSizeTable: [FontFamily:[UIFontTextStyle:[UIContentSizeCategory:CGFloat]]] = {
    return [
        .georgia:[
            UIFontTextStyle.title1: [
                .accessibilityExtraExtraExtraLarge: 28,
                .accessibilityExtraExtraLarge: 28,
                .accessibilityExtraLarge: 28,
                .accessibilityLarge: 28,
                .accessibilityMedium: 28,
                .extraExtraExtraLarge: 26,
                .extraExtraLarge: 24,
                .extraLarge: 22,
                .large: 21,
                .medium: 20,
                .small: 19,
                .extraSmall: 18
            ],
            UIFontTextStyle.title2: [
                .accessibilityExtraExtraExtraLarge: 24,
                .accessibilityExtraExtraLarge: 24,
                .accessibilityExtraLarge: 24,
                .accessibilityLarge: 24,
                .accessibilityMedium: 24,
                .extraExtraExtraLarge: 22,
                .extraExtraLarge: 20,
                .extraLarge: 19,
                .large: 18,
                .medium: 17,
                .small: 16,
                .extraSmall: 15
            ],
            UIFontTextStyle.title3: [
                .accessibilityExtraExtraExtraLarge: 23,
                .accessibilityExtraExtraLarge: 23,
                .accessibilityExtraLarge: 23,
                .accessibilityLarge: 23,
                .accessibilityMedium: 23,
                .extraExtraExtraLarge: 21,
                .extraExtraLarge: 19,
                .extraLarge: 18,
                .large: 17,
                .medium: 16,
                .small: 15,
                .extraSmall: 14
            ]
        ],
    ]
}()


public extension UITraitCollection {
    var wmf_preferredContentSizeCategory: UIContentSizeCategory {
         return preferredContentSizeCategory
    }
}

fileprivate var fontCache: [String: UIFont] = [:]

public extension UIFont {

    @objc(wmf_fontForDynamicTextStyle:) public class func wmf_font(_ dynamicTextStyle: DynamicTextStyle) -> UIFont {
        return UIFont.wmf_font(dynamicTextStyle, compatibleWithTraitCollection: UIScreen.main.traitCollection)
    }
    
    @objc(wmf_fontForDynamicTextStyle:compatibleWithTraitCollection:) public class func wmf_font(_ dynamicTextStyle: DynamicTextStyle, compatibleWithTraitCollection traitCollection: UITraitCollection) -> UIFont {
        let fontFamily = dynamicTextStyle.family
        let weight = dynamicTextStyle.weight
        let traits = dynamicTextStyle.traits
        let style = dynamicTextStyle.style
        guard fontFamily != .system || weight != .regular || traits != [] else {
            return UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection)
        }
        
        let preferredContentSizeCategory = traitCollection.wmf_preferredContentSizeCategory
        
        let familyTable: [UIFontTextStyle:[UIContentSizeCategory:CGFloat]]? = fontSizeTable[fontFamily]
        let styleTable: [UIContentSizeCategory:CGFloat]? = familyTable?[style]
        let size: CGFloat = styleTable?[preferredContentSizeCategory] ?? UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection).pointSize

        let cacheKey = "\(fontFamily.rawValue)-\(weight.rawValue)-\(traits.rawValue)-\(size)"
        if let font = fontCache[cacheKey] {
            return font
        }
        
        
        var font: UIFont
        switch fontFamily {
        case .georgia:
            // using the standard .with(traits: doesn't seem to work for georgia
            let isBold = weight > UIFont.Weight.regular
            let isItalic = traits.contains(.traitItalic)
            if isBold && isItalic {
                font = UIFont(descriptor: UIFontDescriptor(name: "Georgia-BoldItalic", size: size), size: 0)
            } else if isBold {
                font = UIFont(descriptor: UIFontDescriptor(name: "Georgia-Bold", size: size), size: 0)
            } else if isItalic {
                font = UIFont(descriptor: UIFontDescriptor(name: "Georgia-Italic", size: size), size: 0)
            } else {
                font = UIFont(descriptor: UIFontDescriptor(name: "Georgia", size: size), size: 0)
            }
        case .system:
            font = weight != .regular ? UIFont.systemFont(ofSize: size, weight: weight) : UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection)
            if traits != [] {
                font = font.with(traits: traits)
            }
        }
        fontCache[cacheKey] = font
        return font
    }
    
    func with(traits: UIFontDescriptorSymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        
        return UIFont(descriptor: descriptor, size: 0)
    }
}
