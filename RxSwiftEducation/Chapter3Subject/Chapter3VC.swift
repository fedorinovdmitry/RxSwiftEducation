//
//  Chapter3VC.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 15.03.2022.
//

import UIKit
import RxSwift
import RxRelay

fileprivate func print<T: CustomStringConvertible>(label: String, event: RxSwift.Event<T>) {
    Swift.print(label, (event.element ?? event.error) ?? event)
}

class Chapter3VC: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - PublishSubject
        
        example(of: "PublishSubject") {
            let subject = PublishSubject<String>()
            subject.on(.next("Is anyone listening?"))
            
            let subscriptionOne = subject
                .subscribe(onNext: { string in
                    Swift.print(string)
                })
            
            subject.on(.next("1"))
            subject.onNext("2")
            
            let subscriptionTwo = subject
                .subscribe { event in
                    Swift.print("2)", event.element ?? event)
                }
            subject.onNext("3")
            
            subscriptionOne.dispose()
            subject.onNext("4")
            
            subject.onCompleted()
            
            subject.onNext("5")
            
            subscriptionTwo.dispose()
            let disposeBag = DisposeBag()
            
            subject
                .subscribe {
                    Swift.print("3)", $0.element ?? $0)
                }
                .disposed(by: disposeBag)
            subject.onNext("?")
        }
        
        // MARK: - BehaviorSubject

        example(of: "BehaviorSubject") {
            
            enum MyError: Error {
                case anError
            }
            let subject = BehaviorSubject(value: "Initial value")
            let disposeBag = DisposeBag()
            
            subject.onNext("X")
            
            subject
                .subscribe {
                    print(label: "1)", event: $0)
                }
                .disposed(by: disposeBag)
            
            // 1
            subject.onError(MyError.anError)
            // 2
            subject
              .subscribe {
                print(label: "2)", event: $0)
              }
              .disposed(by: disposeBag)
            
        }
        
        // MARK: - ReplaySubject
        
        example(of: "ReplaySubject") {
            
            enum MyError: Error {
                case anError
            }
            // 1
            let subject = ReplaySubject<String>.create(bufferSize: 2)
            let disposeBag = DisposeBag()
            // 2
            subject.onNext("1")
            subject.onNext("2")
            subject.onNext("3")
            // 3
            subject
                .subscribe {
                    print(label: "1)", event: $0)
                }
                .disposed(by: disposeBag)
            
            subject
                .subscribe {
                    print(label: "2)", event: $0)
                }
                .disposed(by: disposeBag)
            
            subject.onNext("4")
            subject.onError(MyError.anError)
            subject.dispose()
            subject
              .subscribe {
                print(label: "3)", event: $0)
              }
              .disposed(by: disposeBag)
        }
        
        // MARK: - PublishRelay
        
        example(of: "PublishRelay") {
            let relay = PublishRelay<String>()
            let disposeBag = DisposeBag()
            
            relay.accept("Knock knock, anyone home?")
            
            relay
                .subscribe(onNext: { print($0) })
                .disposed(by: disposeBag)
            
            relay.accept("1")

        }
        
        // MARK: - BehaviorRelay
        
        example(of: "BehaviorRelay") {
            // 1
            let relay = BehaviorRelay(value: "Initial value")
            let disposeBag = DisposeBag()
            // 2
            relay.accept("New initial value")
            // 3
            relay
                .subscribe {
                    print(label: "1)", event: $0)
                }
                .disposed(by: disposeBag)
            
            // 1
            relay.accept("1")
            // 2
            relay
              .subscribe {
                print(label: "2)", event: $0)
              }
              .disposed(by: disposeBag)
            // 3
            relay.accept("2")
            
            print(relay.value)
        }
        
        // MARK: - Chalange1
        
        example(of: "Chalange1") {
            
            let cards = [
                ("🂡", 11), ("🂢", 2), ("🂣", 3), ("🂤", 4), ("🂥", 5), ("🂦", 6), ("🂧", 7), ("🂨", 8), ("🂩", 9), ("🂪", 10), ("🂫", 10), ("🂭", 10), ("🂮", 10),
                ("🂱", 11), ("🂲", 2), ("🂳", 3), ("🂴", 4), ("🂵", 5), ("🂶", 6), ("🂷", 7), ("🂸", 8), ("🂹", 9), ("🂺", 10), ("🂻", 10), ("🂽", 10), ("🂾", 10),
                ("🃁", 11), ("🃂", 2), ("🃃", 3), ("🃄", 4), ("🃅", 5), ("🃆", 6), ("🃇", 7), ("🃈", 8), ("🃉", 9), ("🃊", 10), ("🃋", 10), ("🃍", 10), ("🃎", 10),
                ("🃑", 11), ("🃒", 2), ("🃓", 3), ("🃔", 4), ("🃕", 5), ("🃖", 6), ("🃗", 7), ("🃘", 8), ("🃙", 9), ("🃚", 10), ("🃛", 10), ("🃝", 10), ("🃞", 10)
            ]
            
            func cardString(for hand: [(String, Int)]) -> String {
                return hand.map { $0.0 }.joined(separator: "")
            }
            
            func points(for hand: [(String, Int)]) -> Int {
                return hand.map { $0.1 }.reduce(0, +)
            }
            
            enum HandError: Error {
                case busted(points: Int)
            }
            
            let disposeBag = DisposeBag()
            
            let dealtHand = PublishSubject<[(String, Int)]>()
            
            func deal(_ cardCount: UInt) {
                var deck = cards
                var cardsRemaining = deck.count
                var hand = [(String, Int)]()
                
                for _ in 0..<cardCount {
                    let randomIndex = Int.random(in: 0..<cardsRemaining)
                    hand.append(deck[randomIndex])
                    deck.remove(at: randomIndex)
                    cardsRemaining -= 1
                }
                
                let points = points(for: hand)
                if points > 21 {
                    dealtHand.onError(HandError.busted(points: points))
                }else {
                    dealtHand.onNext(hand)
                }
            }
            
            dealtHand
                .subscribe(onNext: { print("hand -", cardString(for: $0), "with", points(for: $0), "points") },
                           onError: { print(String(describing: $0).capitalized) })
                .disposed(by: disposeBag)
            
            
            deal(3)
        }
        
        // MARK: - Chalange2

        example(of: "Chalange2") {
            
            enum UserSession {
                case loggedIn, loggedOut
            }
            
            enum LoginError: Error {
                case invalidCredentials
            }
            
            let disposeBag = DisposeBag()
            
            // Create userSession BehaviorRelay of type UserSession with initial value of .loggedOut
            let userSession = BehaviorRelay<UserSession>(value: .loggedOut)
            
            // Subscribe to receive next events from userSession
            userSession
                .subscribe { print("user session status is \($0.event)") }
                .disposed(by: disposeBag)
            
            func logInWith(username: String, password: String, completion: (Error?) -> Void) {
                guard username == "johnny@appleseed.com",
                      password == "appleseed" else {
                          completion(LoginError.invalidCredentials)
                          return
                      }
                
                // Update userSession
                userSession.accept(.loggedIn)
            }
            
            func logOut() {
                // Update userSession
                userSession.accept(.loggedOut)
            }
            
            func performActionRequiringLoggedInUser(_ action: () -> Void) {
                // Ensure that userSession is loggedIn and then execute action()
                if userSession.value == .loggedIn {
                    action()
                }
            }
            
            for i in 1...2 {
                let password = i % 2 == 0 ? "appleseed" : "password"
                
                logInWith(username: "johnny@appleseed.com", password: password) { error in
                    guard error == nil else {
                        print(error!)
                        return
                    }
                    
                    print("User logged in.")
                }
                
                performActionRequiringLoggedInUser {
                    print("Successfully did something only a logged in user can do.")
                }
            }
        }
    }


}

