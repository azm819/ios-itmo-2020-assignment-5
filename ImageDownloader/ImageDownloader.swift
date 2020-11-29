import UIKit
import Combine

final class ImageDownloader {
    typealias ImageCompletion = (UIImage) -> Void
    
    static let sharedInstance = ImageDownloader()
    
    private init(){}
    
    // MARK: - Public
    
    func image(by url: String, completion: ImageCompletion) -> Cancellable {
        // получаем изображение, вызываем completion передав в него изображение
        fatalError("unimplemented")
    }
    
    // MARK: - Private
    
    /*
     Реализация логики
     */
}
