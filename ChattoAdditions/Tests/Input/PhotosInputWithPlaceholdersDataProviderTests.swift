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

import XCTest
@testable import ChattoAdditions

class PhotosInputWithPlaceholderDataProviderTests: XCTestCase {
    var fakePhotosProvider: FakeMediaInputDataProvider!
    var fakePlaceholderProvider: FakeMediaInputDataProvider!
    var sut: MediaInputWithPlaceholdersDataProvider!

    override func setUp() {
        super.setUp()
        self.fakePhotosProvider = FakeMediaInputDataProvider()
        self.fakePlaceholderProvider = FakeMediaInputDataProvider()
        self.sut = MediaInputWithPlaceholdersDataProvider(mediaDataProvider: self.fakePhotosProvider,
                                                          placeholdersDataProvider: self.fakePlaceholderProvider)
    }

    override func tearDown() {
        self.sut = nil
        self.fakePhotosProvider = nil
        self.fakePlaceholderProvider = nil
        super.tearDown()
    }

    func testThat_GivenProviderWithNumberOfPlaceholdersGreaterThenNumberOfPhotos_ThenCountReturnsGreaterNumber() {
        // Given
        let numberOfPlaceholders = 10
        let numberOfPhotos = 1
        self.fakePlaceholderProvider.count = numberOfPlaceholders
        self.fakePhotosProvider.count = numberOfPhotos
        // Then
        XCTAssertEqual(numberOfPlaceholders, sut.count)
    }

    func testThat_GivenProviderWithNumberOfPhotosGreaterThenNumberOfPlaceholders_ThenCountReturnsGreaterNumber() {
        // Given
        let numberOfPlaceholders = 1
        let numberOfPhotos = 10
        self.fakePlaceholderProvider.count = numberOfPlaceholders
        self.fakePhotosProvider.count = numberOfPhotos
        // Then
        XCTAssertEqual(numberOfPhotos, sut.count)
    }

    func testThat_GivenProviderWithNumberOfPlaceholdersGreaterThenNumberOfPhotos_WhenRequestPreviewImageAtIndexLessThenNumberOfPhotos_ThenPhotosProviderReceivesCall() {
        // Given
        let numberOfPlaceholders = 10
        let numberOfPhotos = 1
        let indexToRequest = 0
        self.fakePlaceholderProvider.count = numberOfPlaceholders
        self.fakePhotosProvider.count = numberOfPhotos
        var photoProviderRequested = false
        var placeholderProviderRequested = false
        self.fakePlaceholderProvider.onRequestPreviewImage = { (_, _, _) in
            placeholderProviderRequested = true
            return FakeMediaInputDataProviderImageRequest()
        }
        self.fakePhotosProvider.onRequestPreviewImage = { (index, _, _) in
            photoProviderRequested = true
            XCTAssertTrue(index == indexToRequest)
            return FakeMediaInputDataProviderImageRequest()
        }
        // When
        self.sut.requestPreviewImage(at: indexToRequest, targetSize: .zero) { _,_  in
        }
        // Then
        XCTAssertTrue(photoProviderRequested)
        XCTAssertFalse(placeholderProviderRequested)
    }

    func testThat_GivenProviderWithNumberOfPlaceholdersGreaterThenNumberOfPhotos_WhenRequestPreviewImageAtIndexGreatThenNumberOfPhotos_ThenPlaceholderProviderReceivesCall() {
        // Given
        let numberOfPlaceholders = 10
        let numberOfPhotos = 1
        let indexToRequest = 5
        self.fakePlaceholderProvider.count = numberOfPlaceholders
        self.fakePhotosProvider.count = numberOfPhotos
        var photoProviderRequested = false
        var placeholderProviderRequested = false
        self.fakePlaceholderProvider.onRequestPreviewImage = { (index, _, _) in
            placeholderProviderRequested = true
            XCTAssertTrue(index == indexToRequest)
            return FakeMediaInputDataProviderImageRequest()
        }
        self.fakePhotosProvider.onRequestPreviewImage = { (_, _, _) in
            photoProviderRequested = true
            return FakeMediaInputDataProviderImageRequest()
        }
        // When
        self.sut.requestPreviewImage(at: indexToRequest, targetSize: .zero) { _,_  in
        }
        // Then
        XCTAssertFalse(photoProviderRequested)
        XCTAssertTrue(placeholderProviderRequested)
    }

    func testThat_GivenProviderWithNumberOfPlaceholdersGreaterThenNumberOfPhotos_WhenRequestFullImageAtIndexLessThenNumberOfPhotos_ThenPhotosProviderReceivesCall() {
        // Given
        let numberOfPlaceholders = 10
        let numberOfPhotos = 1
        let indexToRequest = 0
        self.fakePlaceholderProvider.count = numberOfPlaceholders
        self.fakePhotosProvider.count = numberOfPhotos
        var photoProviderRequested = false
        var placeholderProviderRequested = false
        self.fakePlaceholderProvider.onRequestResource = { (index, _, _) in
            placeholderProviderRequested = true
            XCTAssertTrue(index == indexToRequest)
            return FakeMediaInputDataProviderImageRequest()
        }
        self.fakePhotosProvider.onRequestResource = { (_, _, _) in
            photoProviderRequested = true
            return FakeMediaInputDataProviderImageRequest()
        }
        // When
        self.sut.requestResource(at: indexToRequest, progressHandler: nil) { _ in
        }
        // Then
        XCTAssertTrue(photoProviderRequested)
        XCTAssertFalse(placeholderProviderRequested)
    }

    func testThat_GivenProviderWithNumberOfPlaceholdersGreaterThenNumberOfPhotos_WhenRequestFullImageAtIndexGreatThenNumberOfPhotos_ThenPlaceholderProviderReceivesCall() {
        // Given
        let numberOfPlaceholders = 10
        let numberOfPhotos = 1
        let indexToRequest = 5
        self.fakePlaceholderProvider.count = numberOfPlaceholders
        self.fakePhotosProvider.count = numberOfPhotos
        var photoProviderRequested = false
        var placeholderProviderRequested = false
        self.fakePlaceholderProvider.onRequestResource = { (index, _, _) in
            placeholderProviderRequested = true
            XCTAssertTrue(index == indexToRequest)
            return FakeMediaInputDataProviderImageRequest()
        }
        self.fakePhotosProvider.onRequestResource = { (_, _, _) in
            photoProviderRequested = true
            return FakeMediaInputDataProviderImageRequest()
        }
        // When
        self.sut.requestResource(at: indexToRequest, progressHandler: nil) { _ in
        }
        // Then
        XCTAssertFalse(photoProviderRequested)
        XCTAssertTrue(placeholderProviderRequested)
    }

    func testThat_GivenProviderWithNumberOfPlaceholdersGreaterThenNumberOfPhotos_WhenRequestExistedFullImageRequestAtIndexGreatThenNumberOfPhotos_ThenPlaceholderProviderReceivesCall() {
        let existedRequest = FakeMediaInputDataProviderImageRequest()
        let numberOfPlaceholders = 10
        let numberOfPhotos = 1
        let indexToRequest = 5
        self.fakePlaceholderProvider.count = numberOfPlaceholders
        self.fakePhotosProvider.count = numberOfPhotos
        var photoProviderRequested = false
        var placeholderProviderRequested = false
        self.fakePhotosProvider.onResourceRequest = { index in
            photoProviderRequested = true
            XCTAssertTrue(index == indexToRequest)
            return nil
        }
        self.fakePlaceholderProvider.onResourceRequest = { _ in
            placeholderProviderRequested = true
            return existedRequest
        }
        // When
        let request = self.sut.resourceRequest(at: indexToRequest)
        // Then
        XCTAssertTrue(request === existedRequest)
        XCTAssertFalse(photoProviderRequested)
        XCTAssertTrue(placeholderProviderRequested)
    }

    func testThat_GivenProviderWithNumberOfPlaceholdersGreaterThenNumberOfPhotos_WhenRequestExistedFullImageRequestAtIndexLessThenNumberOfPhotos_ThenPhotosProviderReceivesCall() {
        let existedRequest = FakeMediaInputDataProviderImageRequest()
        let numberOfPlaceholders = 10
        let numberOfPhotos = 5
        let indexToRequest = 3
        self.fakePlaceholderProvider.count = numberOfPlaceholders
        self.fakePhotosProvider.count = numberOfPhotos
        var photoProviderRequested = false
        var placeholderProviderRequested = false
        self.fakePhotosProvider.onResourceRequest = { index in
            photoProviderRequested = true
            XCTAssertTrue(index == indexToRequest)
            return existedRequest
        }
        self.fakePlaceholderProvider.onResourceRequest = { _ in
            placeholderProviderRequested = true
            return nil
        }
        // When
        let request = self.sut.resourceRequest(at: indexToRequest)
        // Then
        XCTAssertTrue(request === existedRequest)
        XCTAssertTrue(photoProviderRequested)
        XCTAssertFalse(placeholderProviderRequested)
    }
}
