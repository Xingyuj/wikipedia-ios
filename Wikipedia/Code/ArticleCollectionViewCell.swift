import UIKit

open class ArticleCollectionViewCell: CollectionViewCell, SwipeableCell, BatchEditableCell {
    public let titleLabel = UILabel()
    public let descriptionLabel = UILabel()
    public let imageView = UIImageView()
    public let saveButton = SaveButton()
    public var extractLabel: UILabel?
    public let actionsView = ActionsView()
    public var alertIcon = UIImageView()
    public var alertLabel = UILabel()
    open var alertType: ReadingListAlertType?
    public var statusView = UIImageView() // the circle that appears next to the article name to indicate the article's status

    private var _titleHTML: String? = nil
    private var _titleBoldedString: String? = nil
    
    private func updateTitleLabel() {
        if let titleHTML = _titleHTML {
            titleLabel.attributedText = titleHTML.byAttributingHTML(with: titleTextStyle, matching: traitCollection, withBoldedString: _titleBoldedString)
        } else {
            let titleFont = UIFont.wmf_font(titleTextStyle, compatibleWithTraitCollection: traitCollection)
            titleLabel.font = titleFont
        }
    }
    
    public var titleHTML: String? {
        set {
            _titleHTML = newValue
            updateTitleLabel()
        }
        get {
            return _titleHTML
        }
    }
    
    public func setTitleHTML(_ titleHTML: String?, boldedString: String?) {
        _titleHTML = titleHTML
        _titleBoldedString = boldedString
        updateTitleLabel()
    }
    
    public var actions: [Action] {
        set {
            actionsView.actions = newValue
            updateAccessibilityElements()
        }
        get {
            return actionsView.actions
        }
    }

    private var kvoButtonTitleContext = 0
    
    open override func setup() {
        titleTextStyle = .georgiaTitle1
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        statusView.clipsToBounds = true
        
        if #available(iOSApplicationExtension 11.0, *) {
            imageView.accessibilityIgnoresInvertColors = true
        }
        
        titleLabel.isOpaque = true
        descriptionLabel.isOpaque = true
        imageView.isOpaque = true
        saveButton.isOpaque = true
        
        contentView.addSubview(alertIcon)
        contentView.addSubview(alertLabel)
        contentView.addSubview(statusView)
        contentView.addSubview(saveButton)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)

        saveButton.verticalPadding = 16
        saveButton.rightPadding = 16
        saveButton.leftPadding = 12
        saveButton.saveButtonState = .longSave
        saveButton.addObserver(self, forKeyPath: "titleLabel.text", options: .new, context: &kvoButtonTitleContext)
        
        super.setup()
    }
    
    
    // This method is called to reset the cell to the default configuration. It is called on initial setup and prepareForReuse. Subclassers should call super.
    override open func reset() {
        super.reset()
        _titleHTML = nil
        _titleBoldedString = nil
        titleTextStyle = .georgiaTitle1
        descriptionTextStyle  = .subheadline
        extractTextStyle  = .subheadline
        saveButtonTextStyle  = .mediumSubheadline
        spacing = 5
        imageViewDimension = 70
        statusViewDimension = 6
        alertIconDimension = 12
        imageView.wmf_reset()
        resetSwipeable()
        isBatchEditing = false
        isBatchEditable = false
        actions = []
        isAlertLabelHidden = true
        isAlertIconHidden = true
        isStatusViewHidden = true
        updateFonts(with: traitCollection)
    }

    override open func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        titleLabel.backgroundColor = labelBackgroundColor
        descriptionLabel.backgroundColor = labelBackgroundColor
        extractLabel?.backgroundColor = labelBackgroundColor
        saveButton.backgroundColor = labelBackgroundColor
        saveButton.titleLabel?.backgroundColor = labelBackgroundColor
        alertIcon.backgroundColor = labelBackgroundColor
        alertLabel.backgroundColor = labelBackgroundColor
    }
    
    deinit {
        saveButton.removeObserver(self, forKeyPath: "titleLabel.text", context: &kvoButtonTitleContext)
    }

    open override func safeAreaInsetsDidChange() {
        if #available(iOSApplicationExtension 11.0, *) {
            super.safeAreaInsetsDidChange()
        }
        if swipeState == .open {
            swipeTranslation = swipeTranslationWhenOpen
        }
        setNeedsLayout()
    }

    var actionsViewInsets: UIEdgeInsets {
        if #available(iOSApplicationExtension 11.0, *) {
            return safeAreaInsets
        } else {
            return UIEdgeInsets.zero
        }
    }
    
    public final var statusViewDimension: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public final var alertIconDimension: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var isStatusViewHidden: Bool = true {
        didSet {
            statusView.isHidden = isStatusViewHidden
            setNeedsLayout()
        }
    }
    
    public var isAlertLabelHidden: Bool = true {
        didSet {
            alertLabel.isHidden = isAlertLabelHidden
            setNeedsLayout()
        }
    }
    
    public var isAlertIconHidden: Bool = true {
        didSet {
            alertIcon.isHidden = isAlertIconHidden
            setNeedsLayout()
        }
    }
    
    public var isDeviceRTL: Bool {
        return effectiveUserInterfaceLayoutDirection == .rightToLeft
    }
    
    public var isArticleRTL: Bool {
        return articleSemanticContentAttribute == .forceRightToLeft
    }
    
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        if apply {
            let layoutMargins = calculatedLayoutMargins
            let isBatchEditOnRight = isDeviceRTL
            var batchEditSelectViewWidth: CGFloat = 0
            var batchEditX: CGFloat = 0

            if isBatchEditingPaneOpen {
                if isArticleRTL {
                    batchEditSelectViewWidth = isBatchEditOnRight ? layoutMargins.left : layoutMargins.right // left and and right here are really leading and trailing, should change to UIDirectionalEdgeInsets when available
                } else {
                    batchEditSelectViewWidth = isBatchEditOnRight ? layoutMargins.right : layoutMargins.left
                }
                if isBatchEditOnRight {
                    batchEditX = size.width - batchEditSelectViewWidth
                } else {
                    batchEditX = 0
                }
            } else {
                if isBatchEditOnRight {
                    batchEditX = size.width
                } else {
                    batchEditX = 0 - batchEditSelectViewWidth
                }
            }
            
            if #available(iOSApplicationExtension 11.0, *) {
                let safeX = isBatchEditOnRight ? safeAreaInsets.right : safeAreaInsets.left
                batchEditSelectViewWidth -= safeX
                if !isBatchEditOnRight && isBatchEditingPaneOpen {
                    batchEditX += safeX
                }
                if isBatchEditOnRight && !isBatchEditingPaneOpen {
                    batchEditX -= batchEditSelectViewWidth
                }
            }
            
            batchEditSelectView?.frame = CGRect(x: batchEditX, y: 0, width: batchEditSelectViewWidth, height: size.height)
            batchEditSelectView?.layoutIfNeeded()
            
            let actionsViewWidth = isDeviceRTL ? max(0, swipeTranslation) : -1 * min(0, swipeTranslation)
            let x = isDeviceRTL ? 0 : size.width - actionsViewWidth
            actionsView.frame = CGRect(x: x, y: 0, width: actionsViewWidth, height: size.height)
            actionsView.layoutIfNeeded()
        }
        return size
    }
    
    // MARK - View configuration
    // These properties can mutate with each use of the cell. They should be reset by the `reset` function. Call setsNeedLayout after adjusting any of these properties
    
    public var titleTextStyle: DynamicTextStyle!
    public var descriptionTextStyle: DynamicTextStyle!
    public var extractTextStyle: DynamicTextStyle!
    public var saveButtonTextStyle: DynamicTextStyle!
    
    public var imageViewDimension: CGFloat! //used as height on full width cell, width & height on right aligned
    public var spacing: CGFloat!
    
    public var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            setNeedsLayout()
        }
    }
    
    public var isSaveButtonHidden = false {
        didSet {
            saveButton.isHidden = isSaveButtonHidden
            setNeedsLayout()
        }
    }

    open override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)

        updateTitleLabel()
        
        descriptionLabel.font = UIFont.wmf_font(descriptionTextStyle, compatibleWithTraitCollection: traitCollection)
        extractLabel?.font = UIFont.wmf_font(extractTextStyle, compatibleWithTraitCollection: traitCollection)
        saveButton.titleLabel?.font = UIFont.wmf_font(saveButtonTextStyle, compatibleWithTraitCollection: traitCollection)
        alertLabel.font = UIFont.wmf_font(.semiboldCaption2, compatibleWithTraitCollection: traitCollection)
    }
    
    // MARK - Semantic content
    
    fileprivate var _articleSemanticContentAttribute: UISemanticContentAttribute = .unspecified
    fileprivate var _effectiveArticleSemanticContentAttribute: UISemanticContentAttribute = .unspecified
    open var articleSemanticContentAttribute: UISemanticContentAttribute {
        set {
            _articleSemanticContentAttribute = newValue
            updateEffectiveArticleSemanticContentAttribute()
            setNeedsLayout()
        }
        get {
            return _effectiveArticleSemanticContentAttribute
        }
    }

    // for items like the Save Button that are localized and should match the UI direction
    public var userInterfaceSemanticContentAttribute: UISemanticContentAttribute {
        return traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
    }
    
    fileprivate func updateEffectiveArticleSemanticContentAttribute() {
        if _articleSemanticContentAttribute == .unspecified {
            let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
            _effectiveArticleSemanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        } else {
            _effectiveArticleSemanticContentAttribute = _articleSemanticContentAttribute
        }
        let alignment = _effectiveArticleSemanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        titleLabel.textAlignment = alignment
        titleLabel.semanticContentAttribute = _effectiveArticleSemanticContentAttribute
        descriptionLabel.semanticContentAttribute = _effectiveArticleSemanticContentAttribute
        descriptionLabel.textAlignment = alignment
        extractLabel?.semanticContentAttribute = _effectiveArticleSemanticContentAttribute
        extractLabel?.textAlignment = alignment
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateEffectiveArticleSemanticContentAttribute()
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    // MARK - Accessibility
    
    open override func updateAccessibilityElements() {
        var updatedAccessibilityElements: [Any] = []
        var groupedLabels = [titleLabel, descriptionLabel]
        if let extract = extractLabel {
            groupedLabels.append(extract)
        }

        updatedAccessibilityElements.append(LabelGroupAccessibilityElement(view: self, labels: groupedLabels, actions: actions))
        
        if !isSaveButtonHidden {
            updatedAccessibilityElements.append(saveButton)
        }
        
        accessibilityElements = updatedAccessibilityElements
    }
    
    // MARK - KVO
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &kvoButtonTitleContext {
            setNeedsLayout()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - Swipeable
    var swipeState: SwipeState = .closed {
        didSet {
            if swipeState != .closed && actionsView.superview == nil {
                contentView.addSubview(actionsView)
                contentView.backgroundColor = backgroundView?.backgroundColor
                clipsToBounds = true
            } else if swipeState == .closed && actionsView.superview != nil {
                actionsView.removeFromSuperview()
                contentView.backgroundColor = .clear
                clipsToBounds = false
            }
        }
    }
    
    public var swipeTranslation: CGFloat = 0 {
        didSet {
            assert(!swipeTranslation.isNaN && swipeTranslation.isFinite)
            let isArticleRTL = articleSemanticContentAttribute == .forceRightToLeft
            if isArticleRTL {
                layoutMarginsInteractiveAdditions.left = 0 - swipeTranslation
                layoutMarginsInteractiveAdditions.right = swipeTranslation
            } else {
                layoutMarginsInteractiveAdditions.right = 0 - swipeTranslation
                layoutMarginsInteractiveAdditions.left = swipeTranslation
            }
            setNeedsLayout()
        }
    }
    
    private var isBatchEditingPaneOpen: Bool {
        return batchEditingTranslation > 0
    }

    private var batchEditingTranslation: CGFloat = 0 {
        didSet {
            let marginAddition = batchEditingTranslation / 1.5

            if isArticleRTL {
                if isDeviceRTL {
                    layoutMarginsInteractiveAdditions.left = marginAddition
                } else {
                    layoutMarginsInteractiveAdditions.right = marginAddition
                }
            } else {
                if isDeviceRTL {
                    layoutMarginsInteractiveAdditions.right = marginAddition
                } else {
                    layoutMarginsInteractiveAdditions.left = marginAddition
                }
            }
            
            if isBatchEditingPaneOpen, let batchEditSelectView = batchEditSelectView {
                contentView.addSubview(batchEditSelectView)
                batchEditSelectView.clipsToBounds = true
            }
            setNeedsLayout()
        }
    }

    public var swipeTranslationWhenOpen: CGFloat {
        let maxWidth = actionsView.maximumWidth
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        return isRTL ? actionsViewInsets.left + maxWidth : 0 - maxWidth - actionsViewInsets.right
    }

    // MARK: Prepare for reuse
    
    func resetSwipeable() {
        swipeTranslation = 0
        swipeState = .closed
    }
    
    // MARK: - BatchEditableCell
    
    public var batchEditSelectView: BatchEditSelectView?

    public var isBatchEditable: Bool = false {
        didSet {
            if isBatchEditable && batchEditSelectView == nil {
                batchEditSelectView = BatchEditSelectView()
                batchEditSelectView?.isSelected = isSelected
            } else if !isBatchEditable && batchEditSelectView != nil {
                batchEditSelectView?.removeFromSuperview()
                batchEditSelectView = nil
            }
        }
    }
    
    public var isBatchEditing: Bool = false {
        didSet {
            if isBatchEditing {
                isBatchEditable = true
                batchEditingTranslation = BatchEditSelectView.fixedWidth
                batchEditSelectView?.isSelected = isSelected
            } else {
                batchEditingTranslation = 0
            }
        }
    }
    
    override open var isSelected: Bool {
        didSet {
            batchEditSelectView?.isSelected = isSelected
        }
    }
}
