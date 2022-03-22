//
//  MenuViewController.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 15.03.2022.
//

import UIKit
import RxSwift

func print<T: CustomStringConvertible>(label: String, event: Event<T>) {
    Swift.print(label, (event.element ?? event.error) ?? event)
}

public func example(of description: String,
                    action: () -> Void) {
    print("\n--- Example of:", description, "---")
    action()
}

class MenuViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

}
