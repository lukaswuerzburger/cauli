//
//  ViewController.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var session: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        URLProtocolAdapter.register(for: sessionConfiguration)
        return URLSession(configuration: sessionConfiguration)
    }()
    
    var cauli: Cauli = {
        let cauli = Cauli()
        cauli.florets = [BlackHoleFloret()]
        return cauli
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        session.dataTask(with: URL(string: "https://facebook.com")!) { (data, response, error) in
            if let response = response {
                
                print("\(response)")
            }
        }.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

