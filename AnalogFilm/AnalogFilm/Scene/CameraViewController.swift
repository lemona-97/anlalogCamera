//
//  CameraViewController.swift
//  AnalogFilm
//
//  Created by wooseob on 10/10/25.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//
//

import UIKit
import RxCocoa
import RxSwift
import RxRelay

final class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   // MARK: - Properties
   private let viewModel = CameraViewModel()
   private let disposeBag = DisposeBag()
   private let galleryButtonRelay = PublishRelay<Void>()
   private let takePhotoButtonRelay = PublishRelay<Void>()
   private let changeCameraButtonRelay = PublishRelay<Void>()
   
   // MARK: - Outlets
   @IBOutlet weak var filteredImageView: UIImageView!
   @IBAction func galleryButtonAction(_ sender: Any) {
      galleryButtonRelay.accept(())
   }
   @IBAction func changeCameraButtonAction(_ sender: Any) {
      changeCameraButtonRelay.accept(())
   }
   
   // MARK: - Life Cycles
   override func viewDidLoad() {
      super.viewDidLoad()
      bind()
   }
}

// MARK: - Private Methods
private extension CameraViewController {
   func openGallery() {
      let imagePicker = UIImagePickerController()
      imagePicker.sourceType = .photoLibrary
      imagePicker.delegate = self
      self.present(imagePicker, animated: true, completion: nil)
   }
}

// MARK: - Bind
private extension CameraViewController {
   func bind() {
      let input = CameraViewModel.Input(
         didTapGalleryButton: galleryButtonRelay.asSignal(),
         didTapTakePhotoButton: takePhotoButtonRelay.asSignal(),
         didTapChangeCameraButton: changeCameraButtonRelay.asSignal()
      )
      
      let output = viewModel.transform(input: input)
      bind(for: output)
      viewBind()
   }
   
   func viewBind() {

   }
   
   func bind(for output: CameraViewModel.Output) {
      output.openingGallery
         .emit(with: self) { owner, _ in
            owner.openGallery()
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
