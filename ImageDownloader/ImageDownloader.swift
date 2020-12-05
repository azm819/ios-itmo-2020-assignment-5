import UIKit
import Combine

protocol ImageDataObserver {
    func imageDownloaded(_ image: UIImage)
}

class ImageDataTask: Cancellable, ImageDataObserver {
    var task: ((UIImage) -> Void)?

    init(_ task: ((UIImage) -> Void)? = nil) {
        self.task = task
    }

    func imageDownloaded(_ image: UIImage) {
        if let task = task {
            task(image)
        }
        task = nil
    }

    func cancel() {
        task = nil
    }
}

final class ImageDownloader {
    typealias ImageCompletion = (UIImage) -> Void

    static let sharedInstance = ImageDownloader()

    private struct ImageData {
        public var image: UIImage? {
            didSet {
                if let image = image {
                    observers.forEach {
                        $0.imageDownloaded(image)
                    }
                    observers.removeAll()
                }
            }
        }

        public var observers = [ImageDataObserver]()
    }

    private static var imagesData = [String: ImageData]()
    private static let syncQueue = DispatchQueue(label: "ImageDownloader.syncQueue", attributes: .concurrent)

    private init() { }

    // MARK: - Public

    func image(by url: String, completion: @escaping ImageCompletion) -> Cancellable {
        // получаем изображение, вызываем completion передав в него изображение
        let imageDataTask = ImageDataTask(completion)
        if let image = checkExisting(url, imageDataTask) {
            imageDataTask.imageDownloaded(image)
        }
        else {
            ImageDownloader.syncQueue.async(flags: .barrier) {
                var imageData = ImageData()
                ImageDownloader.imagesData[url] = imageData

                if let url = URL(string: url) {
                    URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                        if error != nil {
                            print("ERROR LOADING IMAGES FROM URL: \(String(describing: error))")
                            return
                        }
                        DispatchQueue.main.async {
                            if let data = data {
                                if let image = UIImage(data: data) {
                                    imageData.image = image
                                    imageDataTask.imageDownloaded(image)
                                }
                            }
                        }
                    }).resume()
                }
            }
        }
        return imageDataTask
    }

    // MARK: - Private

    /*
     Реализация логики
     */

    private func checkExisting(_ url: String, _ observer: ImageDataObserver) -> UIImage? {
        var image: UIImage?
        ImageDownloader.syncQueue.sync {
            if (ImageDownloader.imagesData.keys.contains(url)) {
                image = ImageDownloader.imagesData[url]?.image
                if image == nil {
                    ImageDownloader.imagesData[url]?.observers.append(observer)
                }
            }
        }
        return image
    }
}
