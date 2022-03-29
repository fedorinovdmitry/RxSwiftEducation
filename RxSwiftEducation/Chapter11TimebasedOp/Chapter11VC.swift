//
//  Chapter11VC.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 28.03.2022.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx

// Support code -- DO NOT REMOVE
class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible {
    
    static func make() -> TimelineView<E> {
        let view = TimelineView(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
        view.setup()
        return view
    }
    public func on(_ event: RxSwift.Event<E>) {
        switch event {
        case .next(let value):
            add(.next(String(describing: value)))
        case .completed:
            add(.completed())
        case .error(_):
            add(.error())
        }
    }
}

final class Chapter11VC: UIViewController {
    
    let scrollView = UIScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupViews()
    }
    
    func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    func setupViews(){
        let relay = relay()
        let buffer = buffer(after: relay)
        let window = window(after: buffer)
        let delay = delay(after: window)
        let timeout = timeout(after: delay)
        scrollView.addSubview(relay)
        scrollView.addSubview(buffer)
        scrollView.addSubview(window)
        scrollView.addSubview(delay)
        scrollView.addSubview(timeout)
        
        
        let contentRect: CGRect = scrollView.subviews.reduce(into: .zero) { rect, view in
            rect = rect.union(view.frame)
        }
        scrollView.contentSize = contentRect.size
    }
    
    
    // MARK: - Relay
    
    func relay() -> UIView {
        let elementsPerSecond = 1
        let maxElements = 58
        let replayedElements = 3
        let replayDelay: TimeInterval = 10
        
        
        let sourceObservable = Observable<Int>
          .interval(.milliseconds(Int(1000.0 / Double(elementsPerSecond))), scheduler: MainScheduler.instance)
          .replay(replayedElements)
        
//        let sourceObservable = Observable<Int>.create { observer in
//            var value = 1
//            let timer = DispatchSource.timer(interval: 1.0 /
//                                             Double(elementsPerSecond), queue: .main) {
//                if value <= maxElements {
//                    observer.onNext(value)
//                    value += 1
//                }
//            }
//            return Disposables.create {
//                timer.suspend()
//            }
//        }
//            .replay(replayedElements)
        
        //            .replayAll()
        
        let sourceTimeline = TimelineView<Int>.make()
        let replayedTimeline = TimelineView<Int>.make()
        let stack = UIStackView.makeVertical([UILabel.makeTitle("replay"),
                                              UILabel.make("Emit \(elementsPerSecond) per second:"),
                                              sourceTimeline,
                                              UILabel.make("Replay \(replayedElements) after \(replayDelay)sec:"),
                                              replayedTimeline])
        
        _ = sourceObservable.subscribe(sourceTimeline).disposed(by: rx.disposeBag)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + replayDelay) {
            _ = sourceObservable.subscribe(replayedTimeline)
        }
        
        _ = sourceObservable.connect()
        
        let hostView = UIView(frame: CGRect(x: 0, y: 20, width: view.frame.width, height: 350))
        hostView.backgroundColor = .systemGray5
        hostView.addSubview(stack)
        return hostView
    }
    
    
    // MARK: - Buffer
    
    func buffer(after view: UIView) -> UIView {
        
        let bufferTimeSpan: RxTimeInterval = .seconds(4)
        let bufferMaxCount = 2
        
        let sourceObservable = PublishSubject<String>()
        
        let sourceTimeline = TimelineView<String>.make()
        let bufferedTimeline = TimelineView<Int>.make()
        
        let stack = UIStackView.makeVertical([UILabel.makeTitle("buffer"),
                                              UILabel.make("Emitted elements:"),
                                              sourceTimeline,
                                              UILabel.make("Buffered elements (at most \(bufferMaxCount) every \(bufferTimeSpan) seconds):"),
                                              bufferedTimeline])
        
        
        _ = sourceObservable.subscribe(sourceTimeline)
        
        sourceObservable
            .buffer(timeSpan: bufferTimeSpan,
                    count: bufferMaxCount,
                    scheduler: MainScheduler.instance)
            .map({ $0.count })
            .subscribe(bufferedTimeline)
            .disposed(by: rx.disposeBag)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            sourceObservable.onNext("😠")
            sourceObservable.onNext("😽")
            sourceObservable.onNext("😾")
        }
        
        let hostView = UIView(frame: CGRect(x: 0, y: view.frame.maxY + 20, width: view.frame.width, height: 350))
        hostView.backgroundColor = .green.withAlphaComponent(0.3)
        hostView.addSubview(stack)
        return hostView
    }
    
    // MARK: - Window
    
    func window(after view: UIView) -> UIView {
        
        let elementsPerSecond = 2
        let windowTimeSpan: RxTimeInterval = .seconds(4)
        let windowMaxCount = 10
        let sourceObservable = PublishSubject<String>()
        
        let sourceTimeline = TimelineView<String>.make()
        
        let stack = UIStackView.makeVertical([UILabel.makeTitle("window"),
                                              UILabel.make("Emitted elements (\(elementsPerSecond) per sec.):"),
                                              sourceTimeline,
                                              UILabel.make("Windowed observables (at most \(windowMaxCount) every \(windowTimeSpan) sec):")])
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(elementsPerSecond),
                                         repeats: true,
                                         block: { (_) in
            sourceObservable.onNext("🐱")
        })
        
        
        _ = sourceObservable.subscribe(sourceTimeline).disposed(by: rx.disposeBag)
        
        // —————————————————————————————————————————————————————————
        // CHALLENGE SOLUTION: move side effect out of flatMap
        // —————————————————————————————————————————————————————————

        // extract the windowed observable itself
        let windowedObservable = sourceObservable
          .window(timeSpan: windowTimeSpan, count: windowMaxCount, scheduler: MainScheduler.instance)

        // the timeline observable produces a new timeline every time
        // windowObservable produces a new observable
        let timelineObservable = windowedObservable
          .do(onNext: { _ in
            let timeline = TimelineView<Int>.make()
            stack.insert(timeline, at: 4)
            stack.keep(atMost: 8)
          })
          .map { _ in
            stack.arrangedSubviews[4] as! TimelineView<Int>
        }

        // take one of each, guaranteeing that we get the observable
        // produced by window AND the latest timeline view creating
        _ = Observable
          .zip(windowedObservable, timelineObservable) { obs, timeline in
            (obs, timeline)
          }
          .flatMap { tuple -> Observable<(TimelineView<Int>, String?)> in
            let obs = tuple.0
            let timeline = tuple.1
            return obs
              .map { value in (timeline, value) }
              .concat(Observable.just((timeline, nil)))
          }
          .subscribe(onNext: { tuple in
            let (timeline, value) = tuple
            if let value = value {
              timeline.add(.next(value))
            } else {
              timeline.add(.completed(true))
            }
          })
        
//        _ = sourceObservable
//            .do(onDispose: {timer.invalidate()})
//            .window(timeSpan: windowTimeSpan, count: windowMaxCount, scheduler: MainScheduler.instance)
//                .flatMap { windowedObservable -> Observable<(TimelineView<Int>, String?)> in
//                    let timeline = TimelineView<Int>.make()
//                    stack.insert(timeline, at: 4)
//                    stack.keep(atMost: 8)
//                    return windowedObservable
//                        .map { value in (timeline, value) }
//                        .concat(Observable.just((timeline, nil)))
//                }
//                .subscribe(onNext: { tuple in
//                    let (timeline, value) = tuple
//                    if let value = value {
//                        timeline.add(.next(value))
//                    } else {
//                        timeline.add(.completed(true))
//                    }
//                }).disposed(by: rx.disposeBag)
        
        let hostView = UIView(frame: CGRect(x: 0, y: view.frame.maxY + 20, width: view.frame.width, height: 750))
        hostView.backgroundColor = .blue.withAlphaComponent(0.1)
        hostView.addSubview(stack)
        return hostView
    }
    
    
    // MARK: - Delay
    
    func delay(after view: UIView) -> UIView {
        
        let elementsPerSecond = 1
        let delay: RxTimeInterval = .milliseconds(2000)
        
        let sourceObservable = PublishSubject<Int>()
        
        let sourceTimeline = TimelineView<Int>.make()
        let delayedTimeline = TimelineView<Int>.make()
        
        let stack = UIStackView.makeVertical([
            UILabel.makeTitle("delay"),
            UILabel.make("Emitted elements (\(elementsPerSecond) per sec.):"),
            sourceTimeline,
            UILabel.make("Delayed elements (with a \(delay)s delay):"),
            delayedTimeline])
        
        var current = 1
        //        let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
        //          sourceObservable.onNext(current)
        //          current = current + 1
        //        }
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(elementsPerSecond),
                                         repeats: true,
                                         block: { (_) in
            sourceObservable.onNext(current)
            current = current + 1
        })
        
        _ = sourceObservable
            .do(onDispose: {timer.invalidate()})
            .subscribe(sourceTimeline)
                
//        _ = sourceObservable
//            .do(onDispose: {timer.invalidate()})
//            .delaySubscription(delay, scheduler: MainScheduler.instance)
//            .subscribe(delayedTimeline)
        
//        _ = sourceObservable
//            .delay(delay, scheduler: MainScheduler.instance)
//            .subscribe(delayedTimeline)
 

        // Setup the delayed subscription
        _ = Observable<Int>
            .timer(.seconds(3), scheduler: MainScheduler.instance)
            .flatMap { _ in
                sourceObservable.delay(delay, scheduler: MainScheduler.instance)
            }
            .subscribe(delayedTimeline)
        
        let hostView = UIView(frame: CGRect(x: 0, y: view.frame.maxY + 20, width: view.frame.width, height: 400))
        hostView.backgroundColor = .red.withAlphaComponent(0.2)
        hostView.addSubview(stack)
        return hostView
    }
    
    
    // MARK: - Timeout

    func timeout(after view: UIView) -> UIView {
        
        let button = UIButton(type: .system)
        button.setTitle("Press me now!", for: .normal)
        button.sizeToFit()

        let tapsTimeline = TimelineView<String>.make()

        let stack = UIStackView.makeVertical([
            UILabel.makeTitle("Timeout"),
          button,
          UILabel.make("Taps on button above"),
          tapsTimeline])

//        let _ = button
//            .rx.tap
//            .map { _ in "•" }
//            .timeout(5, scheduler: MainScheduler.instance)
//            .subscribe(tapsTimeline)
        
        let _ = button
          .rx.tap
          .map { _ in "•" }
          .timeout(.seconds(10), other: Observable.just("X"), scheduler: MainScheduler.instance)
          .subscribe(tapsTimeline)

        let hostView = UIView(frame: CGRect(x: 0, y: view.frame.maxY + 20, width: view.frame.width, height: 600))
        hostView.backgroundColor = .yellow.withAlphaComponent(0.2)
        hostView.addSubview(stack)
        return hostView
    }
    
}
