//
//  CapturedImageImpl.swift
//  AnalogFilm
//
//  Created by wooseob on 10/20/25.
//

import CoreData
import UIKit

final class CapturedImageRepositoryImpl: CapturedImageRepository {
   var persistentContainer: NSPersistentContainer? {
      (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
   }
   
   func fetchAllImages() -> [CapturedImage] {
      guard let context = self.persistentContainer?.viewContext else {
         print("데이터 가져오기 실패: 컨텍스트 없음")
         return []
      }
      
      let request = CapturedImage.fetchRequest()
      do {
         let fetchedImages = try context.fetch(request)
         
         print("DB조회 완료: ", fetchedImages.description)
         return fetchedImages
      } catch {
         return []
      }
   }
   
   func saveImage(data: Data, type: Int64) {
      guard let context = self.persistentContainer?.viewContext else {
         print("데이터 저장 실패: 컨텍스트 없음")
         return
      }
      let newImage = CapturedImage(context: context)
      
      newImage.imageData = data
      newImage.id = UUID()
      newImage.imageType = type
      newImage.capturedDate = Date()
      
      try? context.save()
   }
   
   func deleteImages(_ selectedImageIds: [UUID]) {
      guard let context = self.persistentContainer?.viewContext else { return }

      let request = CapturedImage.fetchRequest()

      guard let capturedImages = try? context.fetch(request) else { return }

      let filteredImages = capturedImages.filter({ images in selectedImageIds.contains(images.id!)
      })

      for image in filteredImages {
          context.delete(image)
      }

      try? context.save()
   }
}
