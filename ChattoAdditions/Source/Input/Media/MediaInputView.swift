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
import Photos
import Chatto
import CoreServices

public struct MediaInputViewAppearance {
    public var liveCameraCellAppearence: LiveCameraCellAppearance
    public init(liveCameraCellAppearence: LiveCameraCellAppearance) {
        self.liveCameraCellAppearence = liveCameraCellAppearence
    }
}

public protocol MediaInputViewProtocol {
    var delegate: MediaInputViewDelegate? { get set }
    var presentingController: UIViewController? { get }
}

public enum MediaInputViewSource {
    case camera
    case gallery
}

public enum InputMediaType {
    case image
    case video

    public var UTI: String {
        switch self {
        case .image:
            return kUTTypeImage as String
        case .video:
            return kUTTypeMovie as String
        }
    }

    public var assetType: PHAssetMediaType {
        switch self {
        case .image:
            return .image
        case .video:
            return .video
        }
    }
}

public protocol MediaInputViewDelegate: AnyObject {
    func inputView(_ inputView: MediaInputViewProtocol,
                   didSelectImage image: UIImage,
                   source: MediaInputViewSource)
    func inputView(_ inputView: MediaInputViewProtocol,
                   didSelectVideo videoURL: URL,
                   source: MediaInputViewSource)
    func inputViewDidRequestCameraPermission(_ inputView: MediaInputViewProtocol)
    func inputViewDidRequestPhotoLibraryPermission(_ inputView: MediaInputViewProtocol)
    func inputViewCanPresentCameraDueToUserInteraction(_ inputView: MediaInputViewProtocol) -> Bool
}

public final class MediaInputView: UIView, MediaInputViewProtocol {

    fileprivate struct Constants {
        static let liveCameraItemIndex = 0
    }

    fileprivate lazy var collectionViewQueue = SerialTaskQueue()
    fileprivate var collectionView: UICollectionView!
    fileprivate var collectionViewLayout: UICollectionViewFlowLayout!
    fileprivate var dataProvider: MediaInputDataProviderProtocol!
    fileprivate var cellProvider: MediaInputCellProviderProtocol!
    fileprivate var permissionsRequester: PhotosInputPermissionsRequesterProtocol!
    fileprivate var itemSizeCalculator: MediaInputViewItemSizeCalculator!

    var cameraAuthorizationStatus: AVAuthorizationStatus {
        return self.permissionsRequester.cameraAuthorizationStatus
    }

    var photoLibraryAuthorizationStatus: PHAuthorizationStatus {
        return self.permissionsRequester.photoLibraryAuthorizationStatus
    }

    public weak var delegate: MediaInputViewDelegate?

    public var presentingControllerProvider: () -> UIViewController? = { nil }

    public var presentingController: UIViewController? {
        return self.presentingControllerProvider()
    }

    var appearance: MediaInputViewAppearance?

    private let liveCameraSettings: LiveCameraSettings?
    private let mediaTypes: [InputMediaType]

    public init(presentingControllerProvider: @escaping () -> UIViewController?,
                appearance: MediaInputViewAppearance,
                liveCameraSettings: LiveCameraSettings?,
                mediaTypes: [InputMediaType]) {
        self.presentingControllerProvider = presentingControllerProvider
        self.liveCameraSettings = liveCameraSettings
        self.mediaTypes = mediaTypes
        super.init(frame: CGRect.zero)
        self.appearance = appearance
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.collectionView.dataSource = nil
        self.collectionView.delegate = nil
    }

    private func commonInit() {
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.configureCollectionView()
        self.configureItemSizeCalculator()
        self.dataProvider = MediaInputPlaceholderDataProvider()
        self.cellProvider = MediaInputPlaceholderCellProvider(collectionView: self.collectionView)
        self.permissionsRequester = PhotosInputPermissionsRequester()
        self.permissionsRequester.delegate = self
        self.collectionViewQueue.start()
        self.requestAccessToPhoto()
        self.requestAccessToVideo()
    }

    private func configureItemSizeCalculator() {
        self.itemSizeCalculator = MediaInputViewItemSizeCalculator()
        self.itemSizeCalculator.itemsPerRow = 3
        self.itemSizeCalculator.interitemSpace = 1
    }

    private func requestAccessToVideo() {
        guard self.cameraAuthorizationStatus != .authorized else { return }
        self.permissionsRequester.requestAccessToCamera()
    }

    private func reloadVideoItem() {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            guard let sSelf = self else { return }

            sSelf.collectionView.performBatchUpdates({
                sSelf.collectionView.reloadItems(at: [IndexPath(item: Constants.liveCameraItemIndex, section: 0)])
            }, completion: { (_) in
                DispatchQueue.main.async(execute: completion)
            })
        }
    }

    private func requestAccessToPhoto() {
        guard self.photoLibraryAuthorizationStatus != .authorized else {
            self.replacePlaceholderItemsWithPhotoItems()
            return
        }
        self.permissionsRequester.requestAccessToPhotos()
    }

    private func replacePlaceholderItemsWithPhotoItems() {
        let mediaDataProvider = MediaInputDataProvider(mediaTypes: self.mediaTypes.map({ $0.assetType }))
        mediaDataProvider.prepare { [weak self] in
            guard let sSelf = self else { return }

            sSelf.collectionViewQueue.addTask { [weak self] (completion) in
                guard let sSelf = self else { return }

                let newDataProvider = MediaInputWithPlaceholdersDataProvider(mediaDataProvider: mediaDataProvider,
                                                                             placeholdersDataProvider: MediaInputPlaceholderDataProvider())
                newDataProvider.delegate = sSelf
                sSelf.dataProvider = newDataProvider
                sSelf.cellProvider = MediaInputCellProvider(collectionView: sSelf.collectionView, dataProvider: newDataProvider)
                sSelf.collectionView.reloadData()
                DispatchQueue.main.async(execute: completion)
            }
        }
    }

    func reload() {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            self?.collectionView.reloadData()
            DispatchQueue.main.async(execute: completion)
        }
    }

    fileprivate lazy var cameraPicker: MediaInputCameraPicker = self.makeCameraPicker()

    fileprivate lazy var liveCameraPresenter: LiveCameraCellPresenter = {
        return LiveCameraCellPresenter(
            cameraSettings: self.liveCameraSettings ?? LiveCameraSettings.makeDefaultSettings(),
            cellAppearance: self.appearance?.liveCameraCellAppearence ?? LiveCameraCellAppearance.createDefaultAppearance()
        )
    }()

    private func makeCameraPicker() -> MediaInputCameraPicker {
        return MediaInputCameraPicker(mediaPickerFactory: DeviceMediaPickerFactory(mediaTypes: self.mediaTypes.map({ $0.UTI })),
                                      presentingControllerProvider: self.presentingControllerProvider)
    }
}

extension MediaInputView: UICollectionViewDataSource {

    func configureCollectionView() {
        self.collectionViewLayout = PhotosInputCollectionViewLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.collectionViewLayout)
        self.collectionView.backgroundColor = UIColor.white
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        LiveCameraCellPresenter.registerCells(collectionView: self.collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        self.addSubview(self.collectionView)
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataProvider.count + 1
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell
        if indexPath.item == Constants.liveCameraItemIndex {
            cell = self.liveCameraPresenter.dequeueCell(collectionView: collectionView, indexPath: indexPath)
        } else {
            cell = self.cellProvider.cellForItem(at: indexPath)
        }
        return cell
    }
}

extension MediaInputView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == Constants.liveCameraItemIndex {
            guard self.delegate?.inputViewCanPresentCameraDueToUserInteraction(self) ?? true else {
                return
            }

            if self.cameraAuthorizationStatus != .authorized {
                self.delegate?.inputViewDidRequestCameraPermission(self)
            } else {
                self.liveCameraPresenter.cameraPickerWillAppear()

                let onImageTaken = { [weak self] (image: UIImage?) in
                    guard let sSelf = self else { return }
                    guard let image = image else { return }

                    sSelf.delegate?.inputView(sSelf, didSelectImage: image, source: .camera)
                }

                let onVideoTaken = { [weak self] (videoURL: URL?) in
                    guard let self = self else { return }
                    guard let url = videoURL else { return }

                    self.delegate?.inputView(self, didSelectVideo: url, source: .camera)
                }

                self.cameraPicker.presentCameraPicker(onImageTaken: onImageTaken,
                                                      onVideoTaken: onVideoTaken,
                                                      onCameraPickerDismissed: { [weak self] in
                                                        self?.liveCameraPresenter.cameraPickerDidDisappear()
                })
            }
        } else {
            if self.photoLibraryAuthorizationStatus != .authorized {
                self.delegate?.inputViewDidRequestPhotoLibraryPermission(self)
            } else {
                let request = self.dataProvider.requestResource(at: indexPath.item - 1, progressHandler: nil, completion: { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .successImage(let image):
                        self.delegate?.inputView(self, didSelectImage: image, source: .gallery)
                    case .successVideo(let url):
                        self.delegate?.inputView(self, didSelectVideo: url, source: .gallery)
                    default:
                        break
                    }
                })
                self.cellProvider.configureFullImageLoadingIndicator(at: indexPath, request: request)
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSizeCalculator.itemSizeForWidth(collectionView.bounds.width, atIndex: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.itemSizeCalculator.interitemSpace
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.itemSizeCalculator.interitemSpace
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == Constants.liveCameraItemIndex {
            self.liveCameraPresenter.cellWillBeShown(cell)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == Constants.liveCameraItemIndex {
            self.liveCameraPresenter.cellWasHidden(cell)
        }
    }
}

extension MediaInputView: MediaInputDataProviderDelegate {
    func handleMediaInputDataProviderUpdate(_ dataProvider: MediaInputDataProviderProtocol, updateBlock: @escaping () -> Void) {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            guard let sSelf = self else { return }

            updateBlock()
            sSelf.collectionView.reloadData()
            DispatchQueue.main.async(execute: completion)
        }
    }
}

extension MediaInputView: PhotosInputPermissionsRequesterDelegate {
    public func requester(_ requester: PhotosInputPermissionsRequesterProtocol, didReceiveUpdatedCameraPermissionStatus status: AVAuthorizationStatus) {
        self.reloadVideoItem()
    }

    public func requester(_ requester: PhotosInputPermissionsRequesterProtocol, didReceiveUpdatedPhotosPermissionStatus status: PHAuthorizationStatus) {
        guard status == .authorized else { return }
        self.replacePlaceholderItemsWithPhotoItems()
    }
}

private class PhotosInputCollectionViewLayout: UICollectionViewFlowLayout {
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.width != self.collectionView?.bounds.width
    }
}
