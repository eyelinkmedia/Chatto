//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import ChattoAdditions
import UIKit

final class StubCompoundBubbleViewStyle: CompoundBubbleViewStyleProtocol {

    var stubbedSpotlightedBackgroundColor: UIColor?
    func spotlightedBackgroundColor(forViewModel viewModel: ViewModel) -> UIColor? {
        return self.stubbedSpotlightedBackgroundColor
    }

    var stubbedSpotlightDuration: TimeInterval!
    func spotlightDuration(forViewModel viewModel: ViewModel) -> TimeInterval {
        return self.stubbedSpotlightDuration
    }

    var stubbedHideBubbleForSingleContent: Bool! = false
    var hideBubbleForSingleContent: Bool {
        return stubbedHideBubbleForSingleContent
    }
    var stubbedBackgroundColorResult: UIColor!
    func backgroundColor(forViewModel viewModel: ViewModel) -> UIColor? {
        return stubbedBackgroundColorResult
    }
    var stubbedMaskingImageResult: UIImage!
    func maskingImage(forViewModel viewModel: ViewModel) -> UIImage? {
        return stubbedMaskingImageResult
    }
    var stubbedBorderImageResult: UIImage!
    func borderImage(forViewModel viewModel: ViewModel) -> UIImage? {
        return stubbedBorderImageResult
    }
    var stubbedTailWidthResult: CGFloat!
    func tailWidth(forViewModel viewModel: ViewModel) -> CGFloat {
        return stubbedTailWidthResult
    }
}
