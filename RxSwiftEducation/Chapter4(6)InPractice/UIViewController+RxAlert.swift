//
//  UIViewController+RxAlert.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 21.03.2022.
//

import UIKit
import RxSwift
import RxRelay

extension UIViewController {
    
    func alert(_ title: String, description: String? = nil) -> Completable {
        Completable.create { [weak self] observer in
            
            let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close",
                                          style: .default,
                                          handler: { _ in observer(.completed) } ))
            self?.present(alert, animated: true, completion: nil)
            
            return Disposables.create {
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
}
