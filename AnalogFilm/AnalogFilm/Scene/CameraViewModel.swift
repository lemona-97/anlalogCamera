//
//  CameraViewModel.swift
//  AnalogFilm
//
//  Created by wooseob on 10/10/25.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//
//

import AVFoundation
import Photos
import RxCocoa
import RxSwift

protocol CameraViewModelType: AnyObject {
   associatedtype Input
   associatedtype Output
   
   var disposeBag: DisposeBag { get }
}

final class CameraViewModel: CameraViewModelType {
   let disposeBag = DisposeBag()
   
   private var session: AVCaptureSession? = nil
   var previewLayer: AVCaptureVideoPreviewLayer? = nil
   private var currentCamera: AVCaptureDevice?
   private var currentCameraPosition: AVCaptureDevice.Position = .front
   
   
   private let openingGalleryRelay = PublishRelay<Void>()
   
   // MARK: - Input
   struct Input {
      let didTapGalleryButton: Signal<Void>
      let didTapTakePhotoButton: Signal<Void>
      let didTapChangeCameraButton: Signal<Void>
   }
   
   // MARK: - Output
   struct Output {
      let openingGallery: Signal<Void>
   }
   
   // MARK: - Initializers
   init() {
   }
   
   func transform(input: Input) -> Output {
      input.didTapGalleryButton
         .emit(with: self) { owner, _ in
            if owner.checkGalleryAuthorization() {
               owner.openGallery()
            }
         }.disposed(by: disposeBag)
      
      
      return Output(
         openingGallery: openingGalleryRelay.asSignal()
      )
   }
}

// MARK: - API Methods
private extension CameraViewModel {
   
}

// MARK: - Private Methods
private extension CameraViewModel {
   func openGallery() {
      openingGalleryRelay.accept(())
   }
   
   func checkGalleryAuthorization() -> Bool {
      // 포토 라이브러리 접근 권한
      let authorizationStatus = PHPhotoLibrary.authorizationStatus()
      
      switch authorizationStatus {
      case .authorized, .limited:
         return true
      case .denied, .restricted:
         return false
      case  .notDetermined:
         PHPhotoLibrary.requestAuthorization({ [weak self] status in
            guard let self else { return }
            print("status: \(status)")
            if status == .authorized || status == .limited {
               openGallery()
            }
         })
         return false
      default:
         return false
      }
   }
   
   func requestCameraAuthorization() {
      
   }
   
   func takePhoto() {
      
   }
   
   func saveImage() {
      
   }
}
