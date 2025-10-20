//
//  CameraViewController.swift
//  AnalogFilm
//
//  Created by wooseob on 10/10/25.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//
//

import AVFoundation
import CoreMotion
import UIKit
import RxCocoa
import RxSwift
import RxRelay
import Photos

final class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   // MARK: - Properties
   private let viewModel = CameraViewModel()
   private let disposeBag = DisposeBag()
   
   private var captureSession: AVCaptureSession?
   private let ciContext = CIContext()
   private var photoOutput = AVCapturePhotoOutput()
   private let motionManager = CMMotionManager()
   
   private let viewDidLoadRelay = PublishRelay<Void>()
   private let galleryButtonRelay = PublishRelay<Void>()
   private let takePhotoButtonRelay = PublishRelay<Void>()
   private let changeCameraButtonRelay = PublishRelay<Void>()
   
   // MARK: - Outlets
   @IBOutlet weak var filteredImageView: UIImageView!
   @IBOutlet weak var galleryBackgroundView: CustomView!
   @IBOutlet weak var galleryImageView: UIImageView!
   @IBAction func galleryButtonAction(_ sender: Any) {
      galleryButtonRelay.accept(())
   }
   @IBOutlet weak var changeCameraImageView: UIImageView!
   @IBAction func changeCameraButtonAction(_ sender: Any) {
      changeCameraButtonRelay.accept(())
   }
   @IBAction func takePhotoButtonAction(_ sender: Any) {
      takePhotoButtonRelay.accept(())
   }
   @IBOutlet weak var cameraMagnificationLabel: UILabel!
      
   // MARK: - Life Cycles
   override func viewDidLoad() {
      super.viewDidLoad()
      bind()
      viewDidLoadRelay.accept(())
      startDeviceMotionUpdates()
   }
}

// MARK: - Private Methods
private extension CameraViewController {
   
   func startCameraSession() {
      let session = AVCaptureSession()
      session.sessionPreset = .photo
      
      guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device) else {
         print("❌ 카메라 디바이스를 가져올 수 없습니다.")
         return
      }
      
      if session.canAddInput(input) {
         session.addInput(input)
      }
      
      let output = AVCaptureVideoDataOutput()
      output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
      output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
      if session.canAddOutput(output) {
         session.addOutput(output)
      }
      
      if session.canAddOutput(photoOutput) {
         session.addOutput(photoOutput)
      }
      
      self.captureSession = session
      session.startRunning()
   }
   
   func openGallery() {
      let imagePicker = UIImagePickerController()
      imagePicker.sourceType = .photoLibrary
      imagePicker.delegate = self
      self.present(imagePicker, animated: true, completion: nil)
   }
   
   func showCameraAuthPopup() {
      let title = "카메라 권한이 필요합니다."
      let message = "설정 > 카메라에 대한 권한을 허용해주세요."
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
         if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsURL) {
               UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
         }
      }))
      self.present(alert, animated: true, completion: nil)
   }
   
   func takePhoto() {
      let settings = AVCapturePhotoSettings()
      if photoOutput.supportedFlashModes.contains(.auto) {
         settings.flashMode = .auto
      }
      photoOutput.capturePhoto(with: settings, delegate: self)
   }
   
   /// 전/후면 카메라 전환
   func changeCamera() {
      guard let session = captureSession else {
         print("세션이 없습니다.")
         return
      }
      
      // Find the current camera input
      guard let currentInput = session.inputs.compactMap({ $0 as? AVCaptureDeviceInput }).first else {
         print("현재 카메라 입력을 찾을 수 없습니다.")
         return
      }
      
      // Determine new position
      let currentPosition = currentInput.device.position
      let newPosition: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back
      
      // Find new camera device
      guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
         print("새로운 카메라 디바이스를 찾을 수 없습니다.")
         return
      }
      
      do {
         let newInput = try AVCaptureDeviceInput(device: newDevice)
         
         session.beginConfiguration()
         session.removeInput(currentInput)
         if session.canAddInput(newInput) {
            session.addInput(newInput)
         } else {
            print("새로운 입력을 세션에 추가할 수 없습니다.")
            // Re-add the old input if new one can't be added
            if session.canAddInput(currentInput) {
               session.addInput(currentInput)
            }
         }
         session.commitConfiguration()
      } catch {
         print("새로운 카메라 입력 생성 실패: \(error)")
      }
   }
   
   func savePhotoToLibrary(_ image: UIImage) {
      let imageWithDate = mergeDateLabel(into: image)
      
      PHPhotoLibrary.requestAuthorization { status in
         if status == .authorized || status == .limited {
            PHPhotoLibrary.shared().performChanges({
               PHAssetChangeRequest.creationRequestForAsset(from: imageWithDate)
            }) { success, error in
               if let error = error {
                  print("사진 저장 실패: \(error.localizedDescription)")
               } else if success {
                  print("사진이 저장되었습니다.")
               }
            }
         } else {
            print("사진 라이브러리 접근 권한이 없습니다.")
         }
      }
   }
   
   func mergeDateLabel(into image: UIImage) -> UIImage {
      UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
      
      image.draw(in: CGRect(origin: .zero, size: image.size))
      
      // 현재 날짜를 "yyyy MM dd" 형식으로 표시
      let formatter = DateFormatter()
      formatter.dateFormat = "yyMMdd"
      let dateText = formatter.string(from: Date())
      
      // 이미지뷰 -> 실제 이미지 비율 계산
      let widthRatio = image.size.width / filteredImageView.bounds.width
      let heightRatio = image.size.height / filteredImageView.bounds.height
      
      // 화면에서 15pt로 보이도록 폰트 크기 계산
      let fontSize = 15 * min(widthRatio, heightRatio)
      let font = UIFont(name: "DigitalNumbers-Regular", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
      
      // 색상 #DB7830 적용
      let textColor = UIColor(red: 219/255, green: 120/255, blue: 48/255, alpha: 1.0)
      
      // 우측 정렬
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .right
      
      // 속성 적용
      let attributes: [NSAttributedString.Key: Any] = [
         .font: font,
         .foregroundColor: textColor,
         .paragraphStyle: paragraphStyle,
         .shadow: {
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.black
            shadow.shadowBlurRadius = 2 * min(widthRatio, heightRatio)
            return shadow
         }()
      ]
      
      // 텍스트 크기 계산
      let textSize = dateText.size(withAttributes: attributes)
      
      // 우측 & 하단 16pt 패딩
      let padding: CGFloat = 16 * min(widthRatio, heightRatio)
      let textRect = CGRect(
         x: image.size.width - textSize.width - padding,
         y: image.size.height - textSize.height - padding,
         width: textSize.width,
         height: textSize.height
      )
      
      // 이미지에 그리기
      dateText.draw(in: textRect, withAttributes: attributes)
      
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      
      return newImage ?? image
   }
}

// MARK: - Bind
private extension CameraViewController {
   func bind() {
      let input = CameraViewModel.Input(
         viewDidLoad: viewDidLoadRelay.asSignal(),
         didTapGalleryButton: galleryButtonRelay.asSignal()
      )
      
      let output = viewModel.transform(input: input)
      bind(for: output)
      viewBind()
   }
   
   func viewBind() {
      changeCameraButtonRelay.bind(with: self) { owner, _ in
         owner.changeCamera()
      }.disposed(by: disposeBag)
      
      takePhotoButtonRelay.bind(with: self) { owner, _ in
         owner.takePhoto()
      }.disposed(by: disposeBag)
   }
   
   func bind(for output: CameraViewModel.Output) {
      output.startCamera
         .emit(with: self) { owner, _ in
            owner.startCameraSession()
         }
         .disposed(by: disposeBag)
      
      output.openingGallery
         .emit(with: self) { owner, _ in
            owner.openGallery()
         }.disposed(by: disposeBag)
      
      output.goSettingToTurnOnCamera
         .emit(with: self) { owner, _ in
            owner.showCameraAuthPopup()
         }.disposed(by: disposeBag)
   }
}

// MARK: - UIImagePickerControllerDelegate
extension CameraViewController {
   func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      // 선택된 이미지를 사용하려면 여기에 구현
      picker.dismiss(animated: true, completion: nil)
   }
   func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true, completion: nil)
   }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
   func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
      // ✅ 영상 방향을 항상 세로(Portrait)로 고정
      if #available(iOS 17.0, *) {
         // 0 degrees keeps the buffer in portrait
         connection.videoRotationAngle = 90
      } else {
         connection.videoOrientation = .portrait
      }
      
      guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
      var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
      
      // Check if current camera input is front, then mirror horizontally
      if let session = captureSession,
         let currentInput = session.inputs.compactMap({ $0 as? AVCaptureDeviceInput }).first,
         currentInput.device.position == .front {
         ciImage = ciImage.oriented(.upMirrored)
      }
      
      // 해상도 낮추기: scale 0.5
      let scale: CGFloat = 0.5
      let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
      
      let filtered = FilterManager.applyAnalogFilter(to: scaledImage)
      
      guard let cgImage = ciContext.createCGImage(filtered, from: filtered.extent) else { return }
      let uiImage = UIImage(cgImage: cgImage)
      
      DispatchQueue.main.async { [weak self] in
         self?.filteredImageView.image = uiImage
      }
   }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
   func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
      if let error = error {
         print("Error capturing photo: \(error.localizedDescription)")
         return
      }
      
      guard let imageData = photo.fileDataRepresentation(),
            let image = UIImage(data: imageData),
            let ciImage = CIImage(data: imageData) else {
         print("Failed to get image from photo data")
         return
      }
      
      let filteredCIImage = FilterManager.applyAnalogFilter(to: ciImage)
      guard let cgImage = ciContext.createCGImage(filteredCIImage, from: filteredCIImage.extent) else {
         print("필터 적용 이미지 변환 실패")
         return
      }
      
      let filteredUIImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
      
      DispatchQueue.main.async { [weak self] in
         self?.galleryImageView.image = filteredUIImage
         self?.galleryBackgroundView.isHidden = false
         self?.savePhotoToLibrary(filteredUIImage) // ✅ 필터 적용된 사진 저장
      }
   }
}

// Core Motion
private extension CameraViewController {
   func startDeviceMotionUpdates() {
      guard motionManager.isDeviceMotionAvailable else { return }
      
      motionManager.deviceMotionUpdateInterval = 0.02 // 50fps 정도
      motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
         guard let motion = motion else { return }
         self?.updateButtonRotation(with: motion)
      }
   }
   
   func updateButtonRotation(with motion: CMDeviceMotion) {
      let roll = motion.attitude.roll
      
      // roll 값을 degree로 변환
      // roll 값을 degree로 변환
      let degrees = roll * 180 / .pi
      let pitch = motion.attitude.pitch  * 180 / .pi
      var rotationAngle: CGFloat = 0
      
      // ±45도 기준으로 세 구간만 처리
      if degrees > 50 && pitch < 30 {
         rotationAngle = -.pi / 2  // 왼쪽으로
      } else if degrees < -50 && pitch < 30 {
         rotationAngle = .pi / 2   // 오른쪽으로
      } else {
         rotationAngle = 0         // 가운데(수평)
      }
      
      UIView.animate(withDuration: 0.1) { [weak self] in
         guard let self else { return }
         self.cameraMagnificationLabel.transform = CGAffineTransform(rotationAngle: rotationAngle)
         self.changeCameraImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
         self.galleryImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
      }
   }
}
