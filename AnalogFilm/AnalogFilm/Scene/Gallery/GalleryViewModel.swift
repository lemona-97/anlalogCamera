//
//  GalleryViewModel.swift
//  AnalogFilm
//
//  Created by wooseob on 10/20/25.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//
//

import RxCocoa
import RxSwift

protocol GalleryViewModelType: AnyObject {
   associatedtype Input
   associatedtype Output
   
   var disposeBag: DisposeBag { get }
}

final class GalleryViewModel: GalleryViewModelType {
   let disposeBag = DisposeBag()
   
   let repository: CapturedImageRepository
   private let imagesRelay = PublishRelay<[CapturedImage]>()
   // MARK: - Input
   struct Input {
      let viewDidLoad: Signal<Void>
   }
   
   // MARK: - Output
   struct Output {
      let images: Driver<[CapturedImage]>
   }
   
   // MARK: - Initializers
   init(repository: CapturedImageRepository) {
      self.repository = repository
   }
   
   func transform(input: Input) -> Output {
      input.viewDidLoad
         .emit(with: self) { owner, _ in
            owner.fetchImages()
         }.disposed(by: disposeBag)
      
      return Output(
         images: imagesRelay.asDriver(onErrorJustReturn: [])
      )
   }
}

// MARK: - API Methods
private extension GalleryViewModel {
   
}

// MARK: - Private Methods
private extension GalleryViewModel {
   func fetchImages() {
      let images = repository.fetchAllImages()
      imagesRelay.accept(images)
   }
}
