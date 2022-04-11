
import XCTest
import RxSwift
import RxTest
import RxBlocking

class TestingOperators : XCTestCase {
    var scheduler: TestScheduler!
    var subscription: Disposable!
    
    override func setUp() {
        super.setUp()
        
        scheduler = TestScheduler(initialClock: 0)
    }
    
    override func tearDown() {
        scheduler.scheduleAt(1000) {
            self.subscription.dispose()
        }
        scheduler = nil
        super.tearDown()
    }
    
    func testAmb() {
        // 2
        let observer = scheduler.createObserver(String.self)
        
        // 1
        let observableA = scheduler.createHotObservable([
            // 2
            .next(100, "a"),
            .next(200, "b"),
            .next(300, "c")
        ])
        // 3
        let observableB = scheduler.createHotObservable([
            // 4
            .next(90, "1"),
            .next(200, "2"),
            .next(300, "3")
        ])
        
        let ambObservable = observableA.amb(observableB)
        
        self.subscription = ambObservable.subscribe(observer)
        scheduler.start()
        
        let results = observer.events.compactMap {
         $0.value.element
       }
        
        XCTAssertEqual(results, ["1", "2", "3"])
    }
    
    func testFilter() {
        // 1
        let observer = scheduler.createObserver(Int.self)
        // 2
        let observable = scheduler.createHotObservable([
            .next(100, 1),
            .next(200, 2),
            .next(300, 3),
            .next(400, 2),
            .next(500, 1)
        ])
        // 3
        let filterObservable = observable.filter { $0 < 3 }
        // 4
        scheduler.scheduleAt(0) {
            self.subscription = filterObservable.subscribe(observer)
        }
        // 5
        scheduler.start()
        // 6
        let results = observer.events.compactMap {
            $0.value.element
        }
        // 7
        XCTAssertEqual(results, [1, 2, 2, 1])
    }
    
    func testToArray() throws {
        // 1
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
        // 2
        let toArrayObservable = Observable.of(1,2).subscribe(on: scheduler)
        // 3
        XCTAssertEqual(try toArrayObservable.toBlocking().toArray(), [1, 2])
   }
    
    func testToArrayMaterialized() {
        // 1
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
        let toArrayObservable = Observable.of(1,
                                              2).subscribe(on: scheduler)
        // 2
        let result = toArrayObservable
            .toBlocking()
            .materialize()
        // 3
        switch result {
        case .completed(let elements):
            XCTAssertEqual(elements,  [1, 2])
        case .failed(_, let error):
            XCTFail(error.localizedDescription)
        }
    }
}
