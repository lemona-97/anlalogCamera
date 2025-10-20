//
//  ImageCollectionViewCell.swift
//  AnalogFilm
//
//  Created by wooseob on 10/20/25.
//

import UIKit

/// 1년 지날때마다 조금씩 누렇게 변함
final class ImageCollectionViewCell: UICollectionViewCell {
   static let CELL_ID = "ImageCollectionViewCell"
   static let NIB_NAME = "ImageCollectionViewCell"
   
   // Properties
   var data: CapturedImage?
   
   // Outlets
   @IBOutlet weak var capturedImageView: UIImageView!
   @IBOutlet weak var blockView: UIView!
   @IBOutlet weak var blockLabel: UILabel!
   
   override func awakeFromNib() {
      super.awakeFromNib()
      
   }
   
   override func prepareForReuse() {
      super.prepareForReuse()
      self.capturedImageView.image = nil
      self.data = nil
   }
   
   func configure(with data: CapturedImage) {
      self.data = data
      
      guard
         let capturedDate = data.capturedDate,
         let imageData = data.imageData,
         let image = UIImage(data: imageData)
      else { return }
      
      // 찍은지 하루가 되지 않았다면 볼 수 없음
      let today = Date()
      let printedDate = capturedDate.addingTimeInterval(60 * 60 * 24 * 1)
      if capturedDate >= today.addingTimeInterval(-60 * 60 * 24 * 1) {
         blockView.isHidden = true
      } else {
         blockView.isHidden = false
         let remainTime: TimeInterval = printedDate.timeIntervalSinceNow
         let formattedRemainTime = Date(timeIntervalSinceNow: remainTime)
         let timeFormat = DateFormatter()
         timeFormat.dateFormat = "HH:mm"
         let formattedString = timeFormat.string(from: formattedRemainTime)
         blockLabel.text = "\(formattedString)에 인화됨"
      }
      capturedImageView.image = image
   }
}
