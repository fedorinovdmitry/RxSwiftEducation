//
//  Chapter15VC.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 06.04.2022.
//

import UIKit
import RxSwift

final class Chapter15VC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\n\n\n===== Schedulers =====\n")

        let globalScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
        let bag = DisposeBag()
        let animal = BehaviorSubject(value: "[dog]")

        animal
//          .subscribe(on: MainScheduler.instance)
          .dump()
          .observe(on: globalScheduler)
          .dumpingSubscription()
          .disposed(by: bag)
        
        animal
//          .subscribe(on: MainScheduler.instance)
          .dump()
          .observe(on: globalScheduler)
          .dumpingSubscription()
          .disposed(by: bag)
        
        let fruit = Observable<String>.create { observer in
          observer.onNext("[apple]")
          sleep(2)
          observer.onNext("[pineapple]")
          sleep(2)
          observer.onNext("[strawberry]")
          return Disposables.create()
        }

        fruit
          .subscribe(on: globalScheduler)
          .dump()
          .observe(on: MainScheduler.instance)
          .dumpingSubscription()
          .disposed(by: bag)
        
        let animalsThread = Thread() {
          sleep(3)
          animal.onNext("[cat]")
          sleep(3)
          animal.onNext("[tiger]")
          sleep(3)
          animal.onNext("[fox]")
          sleep(3)
          animal.onNext("[leopard]")
        }
        animalsThread.name = "Animals Thread"
        animalsThread.start()

        // Start coding here


        RunLoop.main.run(until: Date(timeIntervalSinceNow: 13))
    }
}

fileprivate let start = Date()

private func getThreadName() -> String {
    if Thread.current.isMainThread {
        return "Main Thread"
    } else if let name = Thread.current.name {
        if name == "" {
            return "Anonymous Thread"
        }
        return name
    } else {
        return "Unknown Thread"
    }
}

private func secondsElapsed() -> String {
    String(format: "%02i", Int(Date().timeIntervalSince(start).rounded()))
}

extension ObservableType {
    
    func dump() -> Observable<Element> {
        return self.do(onNext: { element in
            let threadName = getThreadName()
            print("\(secondsElapsed())s | [E] \(element) emitted on \(threadName)")
        })
            }
    
    func dumpingSubscription() -> Disposable {
        return self.subscribe(onNext: { element in
            let threadName = getThreadName()
            print("\(secondsElapsed())s | [S] \(element) received on \(threadName)")
        })
    }
}
