//
//  FilterManager.swift
//  AnalogFilm
//
//  Created by wooseob on 10/14/25.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct FilteredInfoWithKoreanWithCIFilter {
    let resultFilterInfo : String
    let resultFilterKoreanName : String
    let resultCIFilteredCIImage : CIImage?
    init(resultFilterInfo: String, resultFilterKoreanName: String, resultCIFilteredCIImage: CIImage?) {
        self.resultFilterInfo = resultFilterInfo
        self.resultFilterKoreanName = resultFilterKoreanName
        self.resultCIFilteredCIImage = resultCIFilteredCIImage
    }
}

enum FilterList {
   case film
}

final class FilterManager {
    static func returnAboutFilter(_ image : CIImage, _ filter: FilterList) -> FilteredInfoWithKoreanWithCIFilter {
        switch filter {
        case .film:
            let filterInfo = "CIColorClamp"
            let filterKorean = "필름"
            let filter = CIFilter(name: filterInfo)
            
            filter?.setValue(image, forKey: kCIInputImageKey)
            filter?.setValue(CIVector(x: 0.3, y: 0.1, z: 0.1, w: 0), forKey: "inputMinComponents")
            filter?.setValue(CIVector(x: 1.0, y: 1.0, z: 1.0, w: 1.0), forKey: "inputMaxComponents")
            let filteredCIImage = filter?.outputImage
            return FilteredInfoWithKoreanWithCIFilter(resultFilterInfo: filterInfo, resultFilterKoreanName: filterKorean, resultCIFilteredCIImage: filteredCIImage)
        }
    }
}
