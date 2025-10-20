//
//  FilterManager.swift
//  AnalogFilm
//
//  Created by wooseob on 10/20/25.
//

import CoreImage

final class FilterManager {
   class func applyAnalogFilter(to image: CIImage) -> CIImage {
      guard let colorControls = CIFilter(name: "CIColorControls"),
            let curve = CIFilter(name: "CIToneCurve"),
            let vignette = CIFilter(name: "CIVignette"),
            let sepia = CIFilter(name: "CISepiaTone"),
            let grain = CIFilter(name: "CIRandomGenerator") else { return image }
      
      // 대비, 채도, 밝기 조절
      colorControls.setValue(image, forKey: kCIInputImageKey)
      colorControls.setValue(1.15, forKey: kCIInputContrastKey)
      colorControls.setValue(0.9, forKey: kCIInputSaturationKey)
      colorControls.setValue(0.05, forKey: kCIInputBrightnessKey)
      
      // 톤 커브
      curve.setValue(colorControls.outputImage, forKey: kCIInputImageKey)
      curve.setValue(CIVector(x: 0.0, y: 0.05), forKey: "inputPoint0")
      curve.setValue(CIVector(x: 0.25, y: 0.15), forKey: "inputPoint1")
      curve.setValue(CIVector(x: 0.5, y: 0.55), forKey: "inputPoint2")
      curve.setValue(CIVector(x: 0.75, y: 0.85), forKey: "inputPoint3")
      curve.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")
      
      // 세피아
      sepia.setValue(curve.outputImage, forKey: kCIInputImageKey)
      sepia.setValue(0.25, forKey: kCIInputIntensityKey)
      
      // 비네팅
      vignette.setValue(sepia.outputImage, forKey: kCIInputImageKey)
      vignette.setValue(2.0, forKey: kCIInputIntensityKey)
      vignette.setValue(30.0, forKey: kCIInputRadiusKey)
      
      // 랜덤 노이즈 그레인
      let noiseImage = grain.outputImage!
         .cropped(to: image.extent)
         .applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0.05),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0.05),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0.05),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.05)
         ])
      
      let finalImage = vignette.outputImage?
         .applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: noiseImage
         ])
      
      return finalImage ?? image
   }
   
   class func applyPhotoAging(to image: CIImage, capturedDate: Date) -> CIImage {
      let tenYear: Double = 60.0 * 60.0 * 24.0 * 365.0 * 10.0
      let passedDate = Date().timeIntervalSince(capturedDate)
      let timeFactorStandard = passedDate / tenYear
      
      let timeFactor = max(0.0, min(timeFactorStandard, 1.0)) // 0~1로 클램프
      
      // 세피아톤 (기본 노랗게)
      guard let sepia = CIFilter(name: "CISepiaTone") else { return image }
      sepia.setValue(image, forKey: kCIInputImageKey)
      sepia.setValue(0.1 + 0.4 * timeFactor, forKey: kCIInputIntensityKey) // 시간에 따라 강도 증가 (0.1~0.5)
      
      // 색상 매트릭스로 약간 붉은기 + 노란기 강조
      let yellowMatrix = CIFilter(name: "CIColorMatrix", parameters: [
         kCIInputImageKey: sepia.outputImage ?? image,
         "inputRVector": CIVector(x: 1.0, y: 0.1 * timeFactor, z: 0, w: 0),
         "inputGVector": CIVector(x: 0, y: 1.0, z: 0, w: 0),
         "inputBVector": CIVector(x: 0, y: 0, z: 0.8 + 0.2 * (1 - timeFactor), w: 0), // 파란색 살짝 줄이기
         "inputBiasVector": CIVector(x: 0.02 * timeFactor, y: 0.015 * timeFactor, z: 0, w: 0)
      ])
      
      // 약간의 대비 낮추기 (시간이 오래될수록 바랜 느낌)
      let faded = CIFilter(name: "CIColorControls", parameters: [
         kCIInputImageKey: yellowMatrix?.outputImage ?? image,
         kCIInputContrastKey: 1.0 - 0.2 * timeFactor,
         kCIInputSaturationKey: 1.0 - 0.3 * timeFactor,
         kCIInputBrightnessKey: 0.05 * timeFactor
      ])
      
      return faded?.outputImage ?? image
   }
}
