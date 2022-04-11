
import XCTest
import RxSwift
import RxCocoa
import RxTest
@testable import RxSwiftEducation

class TestTestingViewModel: XCTestCase {
    
    var viewModel: TestingViewModel!
    var scheduler: ConcurrentDispatchQueueScheduler!
    
    override func setUp() {
        super.setUp()
        
        viewModel = TestingViewModel()
        scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
    }
    
    func testColorIsRedWhenHexStringIsFF0000_async() {
        let disposeBag = DisposeBag()
        // 1
        let expect = expectation(description: #function)
        // 2
        let expectedColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        // 3
        var result: UIColor!
        
        // 1
        viewModel.color.asObservable()
            .skip(1)
            .subscribe(onNext: {
                // 2
                result = $0
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        // 3
        viewModel.hexString.accept("#ff0000")
        // 4
        waitForExpectations(timeout: 1.0) { error in
            guard error == nil else {
                XCTFail(error!.localizedDescription)
                return
            }
            // 5
            XCTAssertEqual(expectedColor, result)
        }
    }
    
    func testColorIsRedWhenHexStringIsFF0000() throws {
        // 1
        let colorObservable = viewModel.color.asObservable().subscribe(on: scheduler)
        // 2
        viewModel.hexString.accept("#ff0000")
        // 3
        XCTAssertEqual(try colorObservable.toBlocking(timeout: 1.0).first(), .red)
    }
    
    func testRgbIs010WhenHexStringIs00FF00() throws {
        // 1
        let rgbObservable = viewModel.rgb.asObservable().subscribe(on: scheduler)
        // 2
        viewModel.hexString.accept("#00ff00")
        // 3
        let result = try rgbObservable.toBlocking().first()!
        XCTAssertEqual(0 * 255, result.0)
        XCTAssertEqual(1 * 255, result.1)
        XCTAssertEqual(0 * 255, result.2)
    }
    
    func testColorNameIsRayWenderlichGreenWhenHexStringIs006636()
    throws {
        // 1
        let colorNameObservable = viewModel.colorName.asObservable().subscribe(on: scheduler)
        // 2
        viewModel.hexString.accept("#006636")
        // 3
        XCTAssertEqual("rayWenderlichGreen", try colorNameObservable.toBlocking().first()!)
    }
}
