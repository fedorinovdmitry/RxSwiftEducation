//
//  Chapter4VC.swift.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 17.03.2022.
//

import UIKit
import RxSwift
import RxRelay

class Chapter4VC: UIViewController {
    
    private let bag = DisposeBag()
    private let images = BehaviorRelay<[UIImage]>(value: [])
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        images
            .subscribe(onNext: { [weak imagePreview] photos in
                guard let preview = imagePreview else { return }
                preview.image = photos.collage(size: preview.frame.size)
            })
            .disposed(by: bag)
        
        images
          .subscribe(onNext: { [weak self] photos in
              self?.updateUI(photos: photos)
          })
          .disposed(by: bag)
    }
    
    @IBAction func actionClear() {
        images.accept([])
    }
    
    @IBAction func actionSave() {
        guard let image = imagePreview.image else { return }
        PhotoWriter.save(image)
            .subscribe(
                onSuccess: { [weak self] id in
                    self?.showMessage("Saved with id: \(id)")
                    self?.actionClear()
                },
                onFailure: { [weak self] error in
                    self?.showMessage("Error", description:
                                        error.localizedDescription)
                } )
            .disposed(by: bag)
    }
    
    @IBAction func actionAdd() {
//        let newImages = images.value + [UIImage(named: "IMG_1907.jpg")!]
//        images.accept(newImages)
        
        let photosViewController = UIStoryboard(name: "Combinestagram", bundle: nil).instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        
        photosViewController.selectedPhotos
            .subscribe(
                onNext: { [weak self] newImage in
                    guard let images = self?.images else { return }
                    images.accept(images.value + [newImage])
                },
                onDisposed: {
                    print("Completed photo selection")
                }
            )
            .disposed(by: bag)
        
        navigationController!.pushViewController(photosViewController,
                                                 animated: true)
    }
    
    private func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }
    
    func showMessage(_ title: String, description: String? = nil) {
        alert(title, description: description)
            .subscribe()
            .disposed(by: bag)
    }
    
    
}

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

