//
//  GlobalRouter.swift
//  AnalogFilm
//
//  Created by wooseob on 10/20/25.
//

import UIKit

final class ControllerFactory {
    class func createVC(withBoardName boardName: String!, vcName: String!) -> UIViewController {
        return UIStoryboard.init(name: boardName, bundle: nil).instantiateViewController(withIdentifier: vcName)
    }
}

final class GlobalRouter {
   func routeToGallery(senderVC: UIViewController) {
      let destinationVC = ControllerFactory.createVC(
         withBoardName: StoryboardNames.Main.Board,
         vcName: StoryboardNames.Main.Gallery
      ) as! GalleryViewController
      
      senderVC.present(destinationVC, animated: true)
   }
}
