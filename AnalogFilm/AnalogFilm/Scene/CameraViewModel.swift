//
//  CameraViewModel.swift
//  AnalogFilm
//
//  Created by wooseob on 10/10/25.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//
//

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
      
   private let startCameraRelay = PublishRelay<Void>()
   private let openingGalleryRelay = PublishRelay<Void>()
   private let openingSettingToTurnOnCameraRelay = PublishRelay<Void>()
   
   // MARK: - Input
   struct Input {
      let viewDidLoad: Signal<Void>
      let didTapGalleryButton: Signal<Void>
   }
   
   // MARK: - Output
   struct Output {
      let startCamera: Signal<Void>
      let openingGallery: Signal<Void>
      let goSettingToTurnOnCamera: Signal<Void>
   }
   
   // MARK: - Initializers
   init() {
   }
   
   func transform(input: Input) -> Output {
      input.viewDidLoad
         .emit(with: self) { owner, _ in
            owner.requestCameraAuthorization()
         }.disposed(by: disposeBag)
      
      input.didTapGalleryButton
         .emit(with: self) { owner, _ in
            if owner.checkGalleryAuthorization() {
               owner.openGallery()
            }
         }.disposed(by: disposeBag)
      
      
      return Output(
         startCamera: startCameraRelay.asSignal(),
         openingGallery: openingGalleryRelay.asSignal(),
         goSettingToTurnOnCamera: openingSettingToTurnOnCameraRelay.asSignal()
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
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
         guard let self else { return }
         if granted {
            print("✅ 카메라 접근 허용됨")
            startCameraSession()
         } else {
            print("❌ 카메라 접근 거부됨")
            DispatchQueue.main.async { [weak self] in
               guard let self else { return }
               self.openingSettingToTurnOnCameraRelay.accept(())
            }
         }
      }
   }
   
   func startCameraSession() {
      startCameraRelay.accept(())
   }
}
