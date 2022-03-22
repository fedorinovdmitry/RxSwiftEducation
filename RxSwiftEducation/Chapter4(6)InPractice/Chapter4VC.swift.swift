//
//  Chapter4VC.swift.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 17.03.2022.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa

class Chapter4VC: UIViewController, UITextFieldDelegate {
    
    private let bag = DisposeBag()
    private let images = BehaviorRelay<[UIImage]>(value: [])
    private var imageCache = [String]()
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindingImages()
        addTextViewWithHtrottlerExample()
        
    }
    
    @IBAction func actionClear() {
        images.accept([])
        imageCache = []
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
        
        let photosViewController = UIStoryboard(name: "Combinestagram",
                                                bundle: nil)
            .instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        
        let newPhotos = photosViewController.selectedPhotos.share()
        newPhotos
            .filter { $0.size.width > $0.size.height }
            .filter { [weak self] newImage in
                let hash = newImage.sha256()
                guard self?.imageCache.contains(hash) == false else { return false }
                self?.imageCache.append(hash)
                return true
            }
            .take(while: { [weak self] _ in self?.imageCache.count ?? Int.max < 6 })
            .subscribe( onNext: { [weak self] newImage in
                guard let images = self?.images else { return }
                images.accept(images.value + [newImage])
            },
                        onDisposed: {
                print("Completed photo selection")
            }
        )
            .disposed(by: bag)
        
        newPhotos
            .ignoreElements()
            .subscribe(onCompleted: { [weak self] in
                self?.updateNavigationIcon()
            })
            .disposed(by: bag)
        
        //example of throttle
        newPhotos
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { print("hash - \($0.sha256())") })
            .disposed(by: bag)

        
        
        navigationController!.pushViewController(photosViewController,
                                                 animated: true)
    }
    
    
    func showMessage(_ title: String, description: String? = nil) {
        alert(title, description: description)
            .subscribe()
            .disposed(by: bag)
    }
    
    private func bindingImages() {
        
        let newImages = images.share()
        newImages
            .throttle(.milliseconds(1000), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak imagePreview] photos in
                print("start collaging")
                guard let preview = imagePreview else { return }
                preview.image = photos.collage(size: preview.frame.size)
            })
            .disposed(by: bag)
        
        newImages
            .subscribe(onNext: { [weak self] photos in
                self?.updateUI(photos: photos)
            })
            .disposed(by: bag)
        
        newImages
            .skip(while: { !$0.isEmpty })
            .subscribe(onNext: { [weak self] _ in
                self?.navigationItem.leftBarButtonItem = nil })
            .disposed(by: bag)
    }
    
    private func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }
    
    private func updateNavigationIcon() {
        let icon = imagePreview.image?
            .scaled(CGSize(width: 22, height: 22))
            .withRenderingMode(.alwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon,
                                                           style: .done,
                                                           target: nil,
                                                           action: nil)
    }
    
    private func addTextViewWithHtrottlerExample() {
        let sampleTextField = UITextField(frame: CGRect(x: 30, y: 140, width: 200, height: 50))
        sampleTextField.placeholder = "Enter text here"
        sampleTextField.font = UIFont.systemFont(ofSize: 15)
        sampleTextField.borderStyle = UITextField.BorderStyle.roundedRect
        sampleTextField.autocorrectionType = UITextAutocorrectionType.no
        sampleTextField.keyboardType = UIKeyboardType.default
        sampleTextField.returnKeyType = UIReturnKeyType.done
        sampleTextField.clearButtonMode = UITextField.ViewMode.whileEditing
        sampleTextField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        sampleTextField.delegate = self
        view.addSubview(sampleTextField)
        sampleTextField.rx.textInput.text
            .throttle(.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(onNext: { print("\($0 ?? "nil")")})
            .disposed(by: bag)
    }
}

