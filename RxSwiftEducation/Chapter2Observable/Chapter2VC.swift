//
//  ViewController.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 14.03.2022.
//

import UIKit
import RxSwift

class Chapter2VC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - just, of, from
        
        example(of: "just, of, from") {
            // 1
            let one = 1
            let two = 2
            let three = 3
            // 2
            let observable = Observable<Int>.just(one)
            let observable2 = Observable.of(one, two, three)
            let observable3 = Observable.of([one, two, three])
            let observable4 = Observable.from([one, two, three])
        }
        
        // MARK: - subscribe
        
        example(of: "subscribe") {
            let one = 1
            let two = 2
            let three = 3
            let observable = Observable.of(one, two, three)
            
            observable.subscribe(onNext: { print($0) })
        }
        
        // MARK: - empty
        
        example(of: "empty") {
            let observable = Observable<Void>.empty()
            
            observable.subscribe(
                // 1
                onNext: { element in
                    print(element)
                },
                // 2
                onCompleted: {
                    print("Completed")
                }
            )
        }
        
        // MARK: - never
        
        example(of: "never") {
            let observable = Observable<Void>.never()
            
            observable.subscribe(
                onNext: { element in
                    print(element)
                },
                onCompleted: {
                    print("Completed")
                }
            )
        }
        
        // MARK: - range
        
        example(of: "range") {
            // 1
            let observable = Observable<Int>.range(start: 1, count: 10)
            observable
                .subscribe(onNext: { i in
                    // 2
                    let n = Double(i)
                    let fibonacci = Int(
                        ((pow(1.61803, n) - pow(0.61803, n)) /
                         2.23606).rounded()
                    )
                    print(fibonacci)
                })
        }
        
        // MARK: - dispose
        
        example(of: "dispose") {
            // 1
            let observable = Observable.of("A", "B", "C")
            // 2
            
            let subscription = observable.subscribe { event in
                // 3
                
                print(event)
            }
            subscription.dispose()
        }
        example(of: "DisposeBag") {
            // 1
            let disposeBag = DisposeBag()
            // 2
            Observable.of("A", "B", "C")
                .subscribe { // 3
                    print($0) }
                .disposed(by: disposeBag) // 4
        }
        
        // MARK: - create
        
        example(of: "create") {
            enum MyError: Error {
                case anError
            }
            let disposeBag = DisposeBag()
            Observable<String>.create { observer in
                // 1
                observer.onNext("1")
                
                //                observer.onError(MyError.anError)
                //                // 2
                //                observer.onCompleted()
                // 3
                observer.onNext("?")
                // 4
                return Disposables.create()
            }.subscribe(
                onNext: { print($0) },
                onError: { print($0) },
                onCompleted: { print("Completed") },
                onDisposed: { print("Disposed") }
            )
                .disposed(by: disposeBag)
            
        }
        
        // MARK: - deferred
        
        example(of: "deferred") {
            let disposeBag = DisposeBag()
            // 1
            var flip = false
            // 2
            let factory: Observable<Int> = Observable.deferred {
                // 3
                flip.toggle()
                // 4
                if flip {
                    return Observable.of(1, 2, 3)
                } else {
                    return Observable.of(4, 5, 6)
                }
            }
            for _ in 0...3 {
                factory.subscribe(onNext: {
                    print($0, terminator: "")
                })
                    .disposed(by: disposeBag)
                print()
            }
        }
        
        // MARK: - Single
        
        example(of: "Single") {
            // 1
            let disposeBag = DisposeBag()
            // 2
            enum FileReadError: Error {
                case fileNotFound, unreadable, encodingFailed
            }
            // 3
            func loadText(from name: String) -> Single<String> {
                // 4
                return Single.create { single in
                    // 1
                    let disposable = Disposables.create()
                    
                    // 2
                    guard let path = Bundle.main.path(forResource: name, ofType: "txt") else {
                        single(.failure(FileReadError.fileNotFound))
                        return disposable
                    }
                    
                    // 3
                    guard let data = FileManager.default.contents(atPath: path) else {
                        single(.failure(FileReadError.unreadable))
                        return disposable
                    }
                    
                    // 4
                    guard let contents = String(data: data, encoding: .utf8) else {
                        single(.failure(FileReadError.encodingFailed))
                        return disposable
                    }
                    
                    // 5
                    single(.success(contents))
                    return disposable
                }
            }
            // 1
            loadText(from: "Copyright")
            // 2
                .subscribe {
                    // 3
                    switch $0 {
                    case .success(let string):
                        print(string)
                    case .failure(let error):
                        print(error)
                    }
                }
                .disposed(by: disposeBag)
            
        }
        
        // MARK: - Chalange1
        
        example(of: "Chalange1") {
            let observable = Observable.of(1, 2, 3)
            let disposedBag = DisposeBag()
            
            
            observable.do(onNext: { print("onNext + \($0)") },
                          onError: { error in print("onError"); print(error) },
                          onCompleted: { print("oncompleted") },
                          onSubscribe: { print("onsubscribe") },
                          onDispose: { print("ondispose") })
                .subscribe(onNext: { print($0) },
                           onError: { print($0) },
                           onCompleted: { print("completed") },
                           onDisposed: { print("disposed") })
                .disposed(by: disposedBag)
            
        }
        
        // MARK: - Chalange2
        
        example(of: "Chalange2") {
            let observable = Observable<String>.create { observer in
                observer.onNext("1")
                
                observer.onCompleted()
                return Disposables.create()
            }
            let disposedBag = DisposeBag()
            
            
            observable
                .debug("Chalange2")
                .subscribe(onNext: { print($0) },
                           onError: { print($0) },
                           onCompleted: { print("completed") },
                           onDisposed: { print("disposed") })
                .disposed(by: disposedBag)
            
            observable
                .debug("Chalange22")
                .subscribe(onNext: { print($0 + "is Chalange22") },
                           onError: { print($0) },
                           onCompleted: { print("completed") },
                           onDisposed: { print("disposed") })
                .disposed(by: disposedBag)
        }
    }
    
    
}
