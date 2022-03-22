//
//  PHPhotoLibrary+Rx.swift.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 21.03.2022.
//

import Foundation
import Photos
import RxSwift

extension PHPhotoLibrary {
    static var authorized: Observable<Bool> {
        return Observable.create { observer in
            DispatchQueue.main.async {
              if authorizationStatus() == .authorized {
                observer.onNext(true)
                observer.onCompleted()
              } else {
                observer.onNext(false)
                requestAuthorization { newStatus in
                  observer.onNext(newStatus == .authorized)
                  observer.onCompleted()
                }
            } }
            return Disposables.create()
        }
    }
}
