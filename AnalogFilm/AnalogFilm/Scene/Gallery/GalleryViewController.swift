//
//  GalleryViewController.swift
//  AnalogFilm
//
//  Created by wooseob on 10/20/25.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//
//

import UIKit
import RxCocoa
import RxSwift

final class GalleryViewController: UIViewController {
   // MARK: - Properties
   private let viewModel = GalleryViewModel(repository: CapturedImageRepositoryImpl())
   private let viewDidLoadRelay = PublishRelay<Void>()
   private var imageDataSource: [CapturedImage] = []
   // MARK: - Outlets
   @IBOutlet weak var imageCollectionView: UICollectionView!
   
   // MARK: - Life Cycles
   override func viewDidLoad() {
      super.viewDidLoad()
      bind()
      viewDidLoadRelay.accept(())
   }
}

// MARK: - Private Methods
private extension GalleryViewController {
   func setCollectionView() {
      imageCollectionView.delegate = self
      imageCollectionView.dataSource = self
      
      imageCollectionView.register(
         UINib(nibName: ImageCollectionViewCell.NIB_NAME, bundle: nil),
         forCellWithReuseIdentifier: ImageCollectionViewCell.CELL_ID
      )
   }
}

// MARK: - Bind
private extension GalleryViewController {
   func bind() {
      let input = GalleryViewModel.Input(
         viewDidLoad: viewDidLoadRelay.asSignal()
      )
      
      let output = viewModel.transform(input: input)
      bind(for: output)
      viewBind()
   }
   
   func viewBind() {
      
   }
   
   func bind(for output: GalleryViewModel.Output) {
      
   }
}

extension GalleryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      imageDataSource.count
   }
   
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      guard
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.CELL_ID, for: indexPath) as? ImageCollectionViewCell
      else {
         return UICollectionViewCell()
      }
      
      let data = self.imageDataSource[indexPath.row]
      cell.configure(with: data)
      
      return cell
   }
}
