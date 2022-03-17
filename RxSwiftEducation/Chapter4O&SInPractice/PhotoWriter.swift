
import Foundation
import UIKit
import Photos
import RxSwift

class PhotoWriter {
    
    static func save(_ image: UIImage) -> Single<String> {
        Single<String>.create { single in
            var savedAssetId: String?
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                savedAssetId = request.placeholderForCreatedAsset?.localIdentifier
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success, let id = savedAssetId {
                        single(.success(id))
                    } else {
                        single(.failure(Errors.couldNotSavePhoto))
                    }
                }
            })
            
            return Disposables.create()
        }
    }
    
    enum Errors: Error {
        case couldNotSavePhoto
    }
}
