//
//  Chapter9VC.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 24.03.2022.
//

import UIKit
import RxSwift
import RxSwiftExt

class Chapter9VC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // MARK: - startWith
        
        example(of: "startWith") {
            // 1
            let numbers = Observable.of(2, 3, 4)
            // 2
            let observable = numbers.startWith(1)
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        // MARK: - Observable.concat
        
        example(of: "Observable.concat") {
            // 1
            let first = Observable.of(1, 2, 3)
            let second = Observable.of(4, 5, 6)
            // 2
            let observable = Observable.concat([first, second])
            observable
                .subscribe(onNext: { value in
                    print(value)
                })
                .disposed(by: DisposeBag())
        }
        
        // MARK: - concat
        
        example(of: "concat") {
            let germanCities = Observable.of("Berlin", "Münich",
                                             "Frankfurt")
            let spanishCities = Observable.of("Madrid", "Barcelona",
                                              "Valencia")
            let observable = germanCities.concat(spanishCities)
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        // MARK: - concatMap
        
        example(of: "concatMap") {
            // 1
            let sequences = [
                "German cities": Observable.of("Berlin", "Münich",
                                               "Frankfurt"),
                "Spanish cities": Observable.of("Madrid", "Barcelona",
                                                "Valencia")
            ]
            // 2
            let observable = Observable.of("German cities", "Spanish cities")
                .concatMap { country in sequences[country] ?? .empty() }
            // 3
            _ = observable.subscribe(onNext: { string in
                print(string)
            })
        }
        
        // MARK: - merge
        
        example(of: "merge") {
            // 1
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            
            let source = Observable.of(left.asObservable(),
                                       right.asObservable())
            let observable = source.merge()
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            
            // 4
            var leftValues = ["Berlin", "Munich", "Frankfurt"]
            var rightValues = ["Madrid", "Barcelona", "Valencia"]
            repeat {
                switch Bool.random() {
                case true where !leftValues.isEmpty:
                    left.onNext("Left:  " + leftValues.removeFirst())
                case false where !rightValues.isEmpty:
                    right.onNext("Right: " + rightValues.removeFirst())
                default:
                    break
                }
            } while !leftValues.isEmpty || !rightValues.isEmpty
            
            left.onCompleted()
            right.onCompleted()
            
        }
        
        // MARK: - combineLatest
        
        example(of: "combineLatest") {
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            
            //            // 1
            //            let observable = Observable.combineLatest(left, right) {
            //                lastLeft, lastRight in
            //                "\(lastLeft) \(lastRight)"
            //            }
            // 1
            let observable = Observable.combineLatest([left, right]) {
                strings in strings.joined(separator: " ")
            }
            
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            // 2
            print("> Sending a value to Left")
            left.onNext("Hello,")
            print("> Sending a value to Right")
            right.onNext("world")
            print("> Sending another value to Right")
            right.onNext("RxSwift")
            print("> Sending another value to Left")
            left.onNext("Have a good day,")
            left.onCompleted()
            right.onCompleted()
            
        }
        
        // MARK: - "combine user choice and value
        
        example(of: "combine user choice and value") {
            let choice: Observable<DateFormatter.Style> = Observable.of(.short, .long)
            let dates = Observable.of(Date())
            let observable = Observable.combineLatest(choice, dates) {
                format, when -> String in
                let formatter = DateFormatter()
                formatter.dateStyle = format
                return formatter.string(from: when)
            }
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        // MARK: - zip
        
        example(of: "zip") {
            
            enum Weather {
                case cloudy
                case sunny
            }
            let left: Observable<Weather> = Observable.of(.sunny, .cloudy,
                                                          .cloudy, .sunny)
            let right = Observable.of("Lisbon", "Copenhagen", "London",
                                      "Madrid", "Vienna")
            
            let observable = Observable.zip(left, right) {
                weather, city in
                return "It's \(weather) in \(city)"
            }
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            
        }
        
        // MARK: - withLatestFrom
        
        example(of: "withLatestFrom") {
            // 1
            let button = PublishSubject<Void>()
            let textField = PublishSubject<String>()
            // 2
            let observable = button.withLatestFrom(textField)
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            // 3
            textField.onNext("Par")
            textField.onNext("Pari")
            textField.onNext("Paris")
            button.onNext(())
            button.onNext(())
        }
        
        // MARK: - sample
        
        example(of: "sample") {
            // 1
            let button = PublishSubject<Void>()
            let textField = PublishSubject<String>()
            // 2
            let observable = textField.sample(button)
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            // 3
            textField.onNext("Par")
            textField.onNext("Pari")
            textField.onNext("Paris")
            button.onNext(())
            button.onNext(())
        }
        
        // MARK: - amb
        
        example(of: "amb") {
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            // 1
            let observable = left.amb(right)
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
            // 2
            left.onNext("Lisbon")
            right.onNext("Copenhagen")
            left.onNext("London")
            left.onNext("Madrid")
            right.onNext("Vienna")
            left.onCompleted()
            right.onCompleted()
        }
        
        // MARK: - switchLatest
        
        example(of: "switchLatest") {
            // 1
            let one = PublishSubject<String>()
            let two = PublishSubject<String>()
            let three = PublishSubject<String>()
            let source = PublishSubject<Observable<String>>()
            
            // 2
            let observable = source.switchLatest()
            let disposable = observable.subscribe(onNext: { value in
                print(value)
            })
            
            // 3
            source.onNext(one)
            one.onNext("Some text from sequence one")
            two.onNext("Some text from sequence two")
            source.onNext(two)
            two.onNext("More text from sequence two")
            one.onNext("and also from sequence one")
            source.onNext(three)
            two.onNext("Why don't you see me?")
            one.onNext("I'm alone, help me")
            three.onNext("Hey it's three. I win.")
            source.onNext(one)
            one.onNext("Nope. It's me, one!")
            
            disposable.dispose()
        }
        
        // MARK: - reduce
        
        example(of: "reduce") {
            let source = Observable.of(1, 3, 5, 7, 9)
            // 1
            let observable = source.reduce(0) { summary, newValue in
                return summary + newValue
            }
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        // MARK: - scan
        
        example(of: "scan") {
            let source = Observable.of(1, 3, 5, 7, 9)
            let observable = source.scan(0, accumulator: +)
            _ = observable.subscribe(onNext: { value in
                print(value)
            })
        }
        
        // MARK: - chalange1
        
        example(of: "chalange1") {
            let source = Observable.of(1, 3, 5, 7, 9)
            let observable = source.scan(0, accumulator: +)
            
            let zipobservable = Observable.zip(source, observable)
            _ = zipobservable.subscribe(onNext: { tuple in
                print("Value = \(tuple.0)   Running total = \(tuple.1)")
            })
            print("2nd variant -----")
            let observable2 = source.scan((0, 0)) { acc, current in
                return (current, acc.1 + current)
            }

            _ = observable2.subscribe(onNext: { tuple in
                print("Value = \(tuple.0)   Running total = \(tuple.1)")
            })
        }
    }
}
