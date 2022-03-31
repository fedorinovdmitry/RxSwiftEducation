//
//  WundercastVC.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 29.03.2022.
//

import UIKit
import RxSwift
import RxCocoa

class WundercastVC: UIViewController {
    
    @IBOutlet private var searchCityName: UITextField!
    @IBOutlet private var tempLabel: UILabel!
    @IBOutlet private var humidityLabel: UILabel!
    @IBOutlet private var iconLabel: UILabel!
    @IBOutlet private var cityNameLabel: UILabel!
    
    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
        ApiController.shared.currentWeather(for: "RxSwift")
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { data in
                self.tempLabel.text = "\(data.temperature)° C"
                self.iconLabel.text = data.icon
                self.humidityLabel.text = "\(data.humidity)%"
                self.cityNameLabel.text = data.cityName
            })
            .disposed(by: bag)
        
        let search = searchCityName.rx
            .controlEvent(.editingDidEndOnExit)
            .map { self.searchCityName.text ?? "" }
            .filter { !$0.isEmpty }
            .flatMapLatest { text in
                ApiController.shared
                    .currentWeather(for: text)
                    .catchAndReturn(.empty)
            }
            .asDriver(onErrorJustReturn: .empty)
        
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
        
        let button = UIButton(frame: CGRect(x: 50, y: 150, width: 100, height: 50))
        button.backgroundColor = .yellow
        view.addSubview(button)
        button.isEnabled = true
        let buttonEvent = button.rx.controlEvent(.touchUpInside).map({ "pick" })
            .asDriver(onErrorJustReturn: "")
        buttonEvent.drive(cityNameLabel.rx.text).disposed(by: bag)
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [self] in
//            buttonEvent.drive(self.tempLabel.rx.text).disposed(by: self.bag)
//        }
        
        button.rx.controlEvent(.touchUpInside)
            .map({ () -> String? in
                var new = self.tempLabel.text?.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                new = String((Double(new ?? "0") ?? 0) * 1.8 + 32) + " F"
                print("new - \(new)")
                return new
            })
            .asDriver(onErrorJustReturn: "can convert")
            .drive(tempLabel.rx.text)
            .disposed(by: bag)
        
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


