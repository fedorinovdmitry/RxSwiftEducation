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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            .flatMap { city in
                ApiController.shared
                    .currentWeather(for: city)
                    .catchAndReturn(.empty)
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

