/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import UIKit

open class MediaChatInputItem: ChatInputItemProtocol {
    public private(set) var supportsExpandableState: Bool = false
    public private(set) var expandedStateTopMargin: CGFloat = 0.0

    typealias Class = MediaChatInputItem

    public var photoInputHandler: ((UIImage, MediaInputViewSource) -> Void)?
    public var videoInputHandler: ((URL, MediaInputViewSource) -> Void)?
    public var cameraPermissionHandler: (() -> Void)?
    public var photosPermissionHandler: (() -> Void)?
    public weak var presentingController: UIViewController?

    let buttonAppearance: TabInputButtonAppearance
    let inputViewAppearance: MediaInputViewAppearance

    public init(presentingController: UIViewController?,
                tabInputButtonAppearance: TabInputButtonAppearance = MediaChatInputItem.createDefaultButtonAppearance(),
                inputViewAppearance: MediaInputViewAppearance = MediaChatInputItem.createDefaultInputViewAppearance()) {
        self.presentingController = presentingController
        self.buttonAppearance = tabInputButtonAppearance
        self.inputViewAppearance = inputViewAppearance
    }

    public static func createDefaultButtonAppearance() -> TabInputButtonAppearance {
        let images: [UIControlStateWrapper: UIImage] = [
            UIControlStateWrapper(state: .normal): UIImage(named: "camera-icon-unselected", in: Bundle(for: Class.self), compatibleWith: nil)!,
            UIControlStateWrapper(state: .selected): UIImage(named: "camera-icon-selected", in: Bundle(for: Class.self), compatibleWith: nil)!,
            UIControlStateWrapper(state: .highlighted): UIImage(named: "camera-icon-selected", in: Bundle(for: Class.self), compatibleWith: nil)!
        ]
        return TabInputButtonAppearance(images: images, size: nil)
    }

    public static func createDefaultInputViewAppearance() -> MediaInputViewAppearance {
        return MediaInputViewAppearance(liveCameraCellAppearence: LiveCameraCellAppearance.createDefaultAppearance())
    }

    lazy private var internalTabView: UIButton = {
        return TabInputButton.makeInputButton(withAppearance: self.buttonAppearance, accessibilityID: "photos.chat.input.view")
    }()

    lazy var mediaInputView: MediaInputViewProtocol = {
        let photosInputView = MediaInputView(presentingControllerProvider: { [weak presentingController] in presentingController },
                                             appearance: self.inputViewAppearance,
                                             liveCameraSettings: nil,
                                             mediaTypes: [.image])
        photosInputView.delegate = self
        return photosInputView
    }()

    open var selected = false {
        didSet {
            self.internalTabView.isSelected = self.selected
        }
    }

    // MARK: - ChatInputItemProtocol

    open var presentationMode: ChatInputItemPresentationMode {
        return .customView
    }

    open var showsSendButton: Bool {
        return false
    }

    open var inputView: UIView? {
        return self.mediaInputView as? UIView
    }

    open var tabView: UIView {
        return self.internalTabView
    }

    open func handleInput(_ input: AnyObject) {}

    open var shouldSaveDraftMessage: Bool {
        return false
    }
}

// MARK: - MediaInputViewDelegate
extension MediaChatInputItem: MediaInputViewDelegate {
    public func inputView(_ inputView: MediaInputViewProtocol,
                          didSelectImage image: UIImage,
                          source: MediaInputViewSource) {
        self.photoInputHandler?(image, source)
    }

    public func inputView(_ inputView: MediaInputViewProtocol,
                          didSelectVideo videoURL: URL,
                          source: MediaInputViewSource) {
        self.videoInputHandler?(videoURL, source)
    }

    public func inputViewDidRequestCameraPermission(_ inputView: MediaInputViewProtocol) {
        self.cameraPermissionHandler?()
    }

    public func inputViewDidRequestPhotoLibraryPermission(_ inputView: MediaInputViewProtocol) {
        self.photosPermissionHandler?()
    }

    public func inputViewCanPresentCameraDueToUserInteraction(_ inputView: MediaInputViewProtocol) -> Bool {
        return true
    }
}
