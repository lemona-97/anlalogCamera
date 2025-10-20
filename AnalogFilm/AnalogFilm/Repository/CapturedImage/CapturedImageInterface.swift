//
//  CapturedImageInterface.swift
//  AnalogFilm
//
//  Created by wooseob on 10/20/25.
//

import Foundation

protocol CapturedImageRepository {
   func fetchAllImages() -> [CapturedImage]
   func saveImage(data: Data, type: Int64)
   func deleteImages(_ selectedImageIds: [UUID])
}
