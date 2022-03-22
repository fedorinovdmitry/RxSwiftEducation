//
//  Chapter5VCViewController.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 18.03.2022.
//

import UIKit
import RxSwift

class Chapter5VC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // MARK: - ignoreElements
        
        example(of: "ignoreElements") {
            // 1
            let strikes = PublishSubject<String>()
            let disposeBag = DisposeBag()
            // 2
            strikes
                .ignoreElements()
                .subscribe { _ in
                    print("You're out!")
                }
                .disposed(by: disposeBag)
            
            strikes.onNext("X")
            strikes.onNext("X")
            strikes.onNext("X")
            
            strikes.onCompleted()
        }
        
        // MARK: - elementAt
        
        example(of: "elementAt") {
            // 1
            let strikes = PublishSubject<String>()
            let disposeBag = DisposeBag()
            // 2
            strikes
                .element(at: 2)
                .subscribe(onNext: { str in
                    print("You're out! \(str)")
                })
                .disposed(by: disposeBag)
            
            strikes.onNext("X1")
            strikes.onNext("X2")
            strikes.onNext("X3")
        }
        
        // MARK: - filter
        
        example(of: "filter") {
            let disposeBag = DisposeBag()
            // 1
            Observable.of(1, 2, 3, 4, 5, 6)
            // 2
                .filter { $0.isMultiple(of: 2) }
            // 3
                .subscribe(onNext: { print($0) })
                .disposed(by: disposeBag)
        }
        
        // MARK: - skip
        
        example(of: "skip") {
            let disposeBag = DisposeBag()
            // 1
            Observable.of("A", "B", "C", "D", "E", "F")
            // 2
                .skip(3)
                .subscribe(onNext: { print($0) })
                .disposed(by: disposeBag)
        }
        
        // MARK: - skipWhile
        
        example(of: "skipWhile") {
            let disposeBag = DisposeBag()
            // 1
            Observable.of(2, 2, 3, 4, 4)
            // 2
                .skip { $0.isMultiple(of: 2) }
                .subscribe(onNext: {
                    print($0) })
                .disposed(by: disposeBag)
        }
        
        // MARK: - skipUntil
        
        example(of: "skipUntil") {
            let disposeBag = DisposeBag()
            // 1
            let subject = PublishSubject<String>()
            let trigger = PublishSubject<String>()
            // 2
            subject
                .skip(until: trigger)
                .subscribe(onNext: {
                    print($0) })
                .disposed(by: disposeBag)
            
            subject.onNext("A")
            subject.onNext("B")
            trigger.onNext("X")
            subject.onNext("С")
        }
        
        // MARK: - take
        
        example(of: "take") {
            let disposeBag = DisposeBag()
            // 1
            Observable.of(1, 2, 3, 4, 5, 6)
            // 2
                .take(3)
                .subscribe(onNext: {
                    print($0) })
                .disposed(by: disposeBag)
        }
        
        // MARK: - takeWhile
        
        example(of: "takeWhile") {
            let disposeBag = DisposeBag()
            // 1
            Observable.of(2, 2, 4, 4, 6, 6)
                .enumerated()
            // 3
                .take(while:  { index, integer in
                    // 4
                    integer.isMultiple(of: 2) && index < 3
                })
            // 5
                .map(\.element)
            // 6
                .subscribe(onNext: {
                    print($0)
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - takeWhile
        
        example(of: "takeUntil") {
            let disposeBag = DisposeBag()
            // 1
            Observable.of(1, 2, 3, 4, 5)
            // 2
                .take(until: { $0.isMultiple(of: 4) },
                      behavior: .exclusive)
                .subscribe(onNext: {
                    print($0) })
                .disposed(by: disposeBag)
        }
        
        // MARK: - takeUntil trigger
        
        example(of: "takeUntil trigger") {
            let disposeBag = DisposeBag()
            // 1
            let subject = PublishSubject<String>()
            let trigger = PublishSubject<String>()
            // 2
            subject
                .take(until: trigger)
                .subscribe(onNext: {
                    print($0) })
                .disposed(by: disposeBag)
            // 3
            subject.onNext("1")
            subject.onNext("2")
            trigger.onNext("3")
            subject.onNext("4")
        }
        
        // MARK: - distinctUntilChanged
        
        example(of: "distinctUntilChanged") {
            let disposeBag = DisposeBag()
            // 1
            Observable.of("A", "A", "B", "B", "A")
            // 2
                .distinctUntilChanged()
                .subscribe(onNext: {
                    print($0) })
                .disposed(by: disposeBag)
        }
        
        // MARK: - distinctUntilChanged(_:)
        
        example(of: "distinctUntilChanged(_:)") {
            let disposeBag = DisposeBag()
            // 1
            let formatter = NumberFormatter()
            formatter.numberStyle = .spellOut
            // 2
            Observable<NSNumber>.of(10, 110, 20, 200, 210, 310)
            // 3
                .distinctUntilChanged { a, b in
                    // 4
                    guard
                        let aWords = formatter
                            .string(from: a)?
                            .components(separatedBy: " "),
                        let bWords = formatter
                            .string(from: b)?
                            .components(separatedBy: " ")
                    else {
                        return false
                    }
                    var containsMatch = false
                    // 5
                    for aWord in aWords where bWords.contains(aWord) {
                        containsMatch = true
                        break
                    }
                    return containsMatch
                }
            // 4
                .subscribe(onNext: {
                    print($0)
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - distinctUntilChanged(_:)
        
        example(of: "Challenge 1") {
            let disposeBag = DisposeBag()
            
            let contacts = [
                "603-555-1212": "Florent",
                "212-555-1212": "Shai",
                "408-555-1212": "Marin",
                "617-555-1212": "Scott"
            ]
            
            func phoneNumber(from inputs: [Int]) -> String {
                var phone = inputs.map(String.init).joined()
                
                phone.insert("-", at: phone.index(
                    phone.startIndex,
                    offsetBy: 3)
                )
                
                phone.insert("-", at: phone.index(
                    phone.startIndex,
                    offsetBy: 7)
                )
                
                return phone
            }
            
            let input = PublishSubject<Int>()
            
            input
                .skip(while: { $0 == 0 })
                .filter({ $0 < 10 && $0 >= 0 })
                .take(10)
                .toArray()
                .subscribe(onSuccess: {
                    let phone = phoneNumber(from: $0)
                    print("phone search - \(phone)")
                    if let contact = contacts[phone] {
                        print("Dialing \(contact) (\(phone))...")
                    } else {
                        print("Contact not found")
                    }})
                .disposed(by: disposeBag)
            
            
            input.onNext(0)
            input.onNext(603)
            
            input.onNext(2)
            input.onNext(1)
            
            // Confirm that 7 results in "Contact not found",
            // and then change to 2 and confirm that Shai is found
            input.onNext(2)
            
            "5551212".forEach {
                if let number = (Int("\($0)")) {
                    input.onNext(number)
                }
            }
            
            input.onNext(9)
//            input.onCompleted()
            
            
        }
    }
    
}
