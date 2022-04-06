//
//  WundercastVC.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 29.03.2022.
//

import UIKit
import RxSwift
import RxCocoa
import MapKit
import CoreLocation

class WundercastVC: UIViewController {
    
    private var cache = [String: ApiController.Weather]()
    
    @IBOutlet private var mapView: MKMapView!
    @IBOutlet private var mapButton: UIButton!
    @IBOutlet private var geoLocationButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var searchCityName: UITextField!
    @IBOutlet private var tempLabel: UILabel!
    @IBOutlet private var humidityLabel: UILabel!
    @IBOutlet private var iconLabel: UILabel!
    @IBOutlet private var cityNameLabel: UILabel!
    
    private let bag = DisposeBag()
    
    private let locationManager = CLLocationManager()
    
    private static let maxAttempts = 4
    
    var keyTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = RxReachability.shared.startMonitor("openweathermap.org")
        
        let button = UIButton(frame: CGRect(x: 50, y: 150, width: 100, height: 50))
        button.backgroundColor = .yellow
        view.addSubview(button)
        
        button.rx.tap
          .subscribe(onNext: { [weak self] _ in
            self?.requestKey()
          })
          .disposed(by:bag)
        
        mapButton.rx.tap
            .subscribe(onNext: {
                self.mapView.isHidden.toggle()
            })
            .disposed(by: bag)
        
        mapView.rx
         .setDelegate(self)
         .disposed(by: bag)
        
        
        
//        ApiController.shared.currentWeather(for: "RxSwift")
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { data in
//                self.tempLabel.text = "\(data.temperature)° C"
//                self.iconLabel.text = data.icon
//                self.humidityLabel.text = "\(data.humidity)%"
//                self.cityNameLabel.text = data.cityName
//            })
//            .disposed(by: bag)
        
        //12 chalenge
//        let textSearch = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
//        let temperature = tempSwitch.rx.controlEvent(.valueChanged).asObservable()
//
//        let search = Observable
//          .merge(textSearch, temperature)
//          .map { self.searchCityName.text ?? "" }
//          .filter { !$0.isEmpty }
//          .flatMapLatest { text in
//            ApiController.shared
//              .currentWeather(for: text)
//              .catchErrorJustReturn(.empty)
//          }
//        .asDriver(onErrorJustReturn: .empty)
//
//        search
//          .map { w in
//            if self.tempSwitch.isOn {
//              return "\(Int(Double(w.temperature) * 1.8 + 32))° F"
//            } else {
//              return "\(w.temperature)° C"
//            }
//          }
//          .drive(tempLabel.rx.text)
//          .disposed(by: bag)
        
        
        style()
        
        let mapInput = mapView.rx.regionDidChangeAnimated
            .skip(1)
            .map { _ in
                CLLocation(latitude: self.mapView.centerCoordinate.latitude,
                           longitude: self.mapView.centerCoordinate.longitude)
            }
        
        let geoInput = geoLocationButton.rx.tap
            .flatMapLatest { _ in self.locationManager.rx.getCurrentLocation() }
        
        let geoSearch = Observable
            .merge(mapInput, geoInput)
            .flatMapLatest { location in
                ApiController.shared
                    .currentWeather(at: location.coordinate)
                    .catchAndReturn(.empty)
            }
        
        let searchInput = searchCityName.rx
            .controlEvent(.editingDidEndOnExit)
            .map { self.searchCityName.text ?? "" }
            .filter { !$0.isEmpty }
        
        let textSearch = searchInput
            .flatMap { text in
                ApiController.shared
                    .currentWeather(for: text)
                    .do(
                        onNext: { [weak self] data in
                            self?.cache[text] = data
                        },
                        onError: { error in
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                self.showError(error: error)
                            }
                        }
                    )
                    .retry(when: self.retryHandler)
                    .catch({ [weak self] _ in
                        Observable.just(self?.cache[text] ?? .empty)
                    })
                }
        
        
        let search = Observable
            .merge(geoSearch, textSearch)
            .asDriver(onErrorJustReturn: .empty)
        
        let running = Observable.merge(
            geoInput.map({ _ in true }),
            searchInput.map { _ in true },
            geoLocationButton.rx.tap.map { _ in true },
            search.map { _ in false }.asObservable()
          )
          .startWith(true)
          .asDriver(onErrorJustReturn: false)
        
        search
          .map { $0.overlay() }
          .drive(mapView.rx.overlay)
          .disposed(by: bag)
        
        search.map { "\($0.temperature)° C" }
            .drive(tempLabel.rx.text)
            .disposed(by: bag)
        
        search.map(\.icon)
            .drive(iconLabel.rx.text)
            .disposed(by: bag)
        
        search.map { "\($0.humidity)%" }
            .drive(humidityLabel.rx.text)
            .disposed(by: bag)
        
        search.map(\.cityName)
            .drive(cityNameLabel.rx.text)
            .disposed(by: bag)
        
        running
          .skip(1)
          .drive(activityIndicator.rx.isAnimating)
          .disposed(by: bag)
        
        running
          .drive(tempLabel.rx.isHidden)
          .disposed(by: bag)
        running
          .drive(iconLabel.rx.isHidden)
          .disposed(by: bag)
        running
          .drive(humidityLabel.rx.isHidden)
          .disposed(by: bag)
        running
          .drive(cityNameLabel.rx.isHidden)
          .disposed(by: bag)
        
//        let button = UIButton(frame: CGRect(x: 50, y: 150, width: 100, height: 50))
//        button.backgroundColor = .yellow
//        view.addSubview(button)
//        button.isEnabled = true
//        let buttonEvent = button.rx.controlEvent(.touchUpInside).map({ "pick" })
//            .asDriver(onErrorJustReturn: "")
//        buttonEvent.drive(cityNameLabel.rx.text).disposed(by: bag)
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [self] in
//            buttonEvent.drive(self.tempLabel.rx.text).disposed(by: self.bag)
//        }
        
//        button.rx.controlEvent(.touchUpInside)
//            .map({ () -> String? in
//                var new = self.tempLabel.text?.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
//                new = String((Double(new ?? "0") ?? 0) * 1.8 + 32) + " F"
//                return new
//            })
//            .asDriver(onErrorJustReturn: "can convert")
//            .drive(tempLabel.rx.text)
//            .disposed(by: bag)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Appearance.applyBottomLine(to: searchCityName)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Style
    
    private func style() {
        view.backgroundColor = UIColor.aztec
        searchCityName.attributedPlaceholder = NSAttributedString(string: "City's Name",
                                                                  attributes: [.foregroundColor: UIColor.textGrey])
        searchCityName.textColor = UIColor.ufoGreen
        tempLabel.textColor = UIColor.cream
        humidityLabel.textColor = UIColor.cream
        iconLabel.textColor = UIColor.cream
        cityNameLabel.textColor = UIColor.cream
    }
    
    func requestKey() {
        func configurationTextField(textField: UITextField!) {
            self.keyTextField = textField
        }
        
        let alert = UIAlertController(title: "Api Key",
                                      message: "Add the api key:",
                                      preferredStyle: UIAlertController.Style.alert)
        
        alert.addTextField(configurationHandler: configurationTextField)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
            ApiController.shared.apiKey.onNext(self?.keyTextField?.text ?? "")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.destructive))
        
        self.present(alert, animated: true)
    }
    
    // MARK: - Error handling
    
    private let retryHandler: (Observable<Error>) -> Observable<Int> = { e in
        return e.enumerated().flatMap { attempt, error -> Observable<Int> in
            
            if attempt >= WundercastVC.maxAttempts - 1 {
                return Observable.error(error)
            } else if let casted = error as? ApiController.ApiError,
                      casted == .invalidKey {
                
                return ApiController.shared.apiKey
                    .filter { !$0.isEmpty }
                    .map { _ in 1 }
                
            }else if (error as NSError).code == -1009 {
                
                return RxReachability.shared.status
                    .filter({ $0 == .online })
                    .map( { _ in 1} )
            }
            print("== retrying after \(attempt + 1) seconds ==")
            return Observable<Int>.timer(.seconds(attempt + 1),
                                         scheduler: MainScheduler.instance)
                .take(1)
        }
    }
    
    
    
    private func showError(error e: Error) {
        guard let e = e as? ApiController.ApiError else {
            InfoView.showIn(viewController: self, message: "An error occurred")
            return
        }
        switch e {
        case .cityNotFound:
            InfoView.showIn(viewController: self, message: "City Name is invalid")
        case .serverFailure:
            InfoView.showIn(viewController: self, message: "Server error")
        case .invalidKey:
            InfoView.showIn(viewController: self, message: "Key is invalid")
        }
    }
    
}

extension WundercastVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let overlay = overlay as?
                ApiController.Weather.Overlay else {
                    return MKOverlayRenderer()
                }
        return ApiController.Weather.OverlayView(overlay: overlay,
                                                 overlayIcon: overlay.icon)
    }
}

