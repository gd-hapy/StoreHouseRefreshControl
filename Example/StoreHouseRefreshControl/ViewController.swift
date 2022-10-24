//
//  ViewController.swift
//  StoreHouseRefreshControl
//
//  Created by 效桂成 on 09/02/2022.
//  Copyright (c) 2022 效桂成. All rights reserved.
//

import UIKit
import StoreHouseRefreshControl

class ViewController: UIViewController {

    var refreshControl: StoreHouseRefreshControl!
    var testView: UIView!
    var realProgress: CGFloat = 0.0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        let ss = BarItem().initWithFrame(CGRect.zero, CGPoint.zero, CGPoint.zero, .red, 1)
    
        view.backgroundColor = .white
//        setupView()
        
        testView = UIView(frame: CGRect(x: 100, y: 100, width: view.bounds.size.width-200, height: 50));
        testView?.backgroundColor = .red
        view.addSubview(testView)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let homeVC = homeViewController()
        let nav = UINavigationController(rootViewController: homeVC)
        nav.modalPresentationStyle = .overFullScreen
        self.present(nav, animated: true)
        
//        testView?.transform = CGAffineTransform(translationX: 100*(1-realProgress), y: -100*(1-realProgress))
//        realProgress += 0.01;
    }
    
    func setupView() {
        
        let tableView = UITableView(frame: self.view.frame, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.backgroundColor = .black
        
//        let config = StoreHouseRefreshControlConfig(color: .red, lineWidth: 10, dropHeight: 80, scale: 0.7, horizontalRandomness: 60, reverseLoadingAnimation: false, internalAnimationFactor: 10, originalTopContentInset: 10, disappearProgress: 10)
        let config = StoreHouseRefreshControlConfig.init()
        refreshControl = StoreHouseRefreshControl.attachToScrollView(tableView, self, #selector(refreshTriggered), "AKTA", config)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func refreshTriggered() {
        self.perform(#selector(refreshControl.finishingLoading), with: nil, afterDelay: 3, inModes: [RunLoopMode.commonModes])
    }
    
    

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = String(repeating: "%d", count: indexPath.row)
        cell?.backgroundColor = indexPath.row % 2 == 0 ? .red: .yellow
        return cell!
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        refreshControl.scrollViewDidScroll()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        refreshControl.scrollViewDidEndDragging()
    }
}

