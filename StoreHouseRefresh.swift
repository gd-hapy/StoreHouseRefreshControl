//
//  StoreHouseRefresh.swift
//  StoreHouseRefreshControl
//
//  Created by Apple on 9/2/22.
//

import UIKit
 
class BarItem: UIView {
    
    public var translationX: CGFloat = 0.0
    
    private var middlePoint: CGPoint = CGPoint.zero
    private var lineWidth: CGFloat = 2.0
    private var startPoint: CGPoint = CGPoint.zero
    private var endPoint: CGPoint = CGPoint.zero
    private var color: UIColor = .white
    
    
    public required init?(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    public func initWithFrame(_ frame: CGRect, _ startPoint: CGPoint, _ endPoint: CGPoint, _ color: UIColor, _ lineWidth: CGFloat) -> Self {
        self.frame = frame
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.lineWidth = lineWidth
        self.color = color
        
        let calBolck:(_ s: CGPoint, _ e: CGPoint) -> CGPoint = {s, e in
            let x = (s.x + e.x) * 0.5
            let y = (s.y + e.y) * 0.5
            return CGPoint(x: x, y: y)
        }
        self.middlePoint = calBolck(startPoint, endPoint)
        return self
    }
    
    public func setupWithFrame(_ rect: CGRect) {
        self.layer.anchorPoint = CGPoint(x: self.middlePoint.x/self.frame.size.width, y: self.middlePoint.y/self.frame.self.height)
        self.frame = CGRect(x: self.frame.origin.x + self.middlePoint.x - self.frame.size.width * 0.5, y: self.frame.origin.y + self.middlePoint.y - self.frame.size.height * 0.5, width: self.frame.size.width, height: self.frame.size.height)
    }
    
    public func setHorizontalRandomness(_ horizontalRandomness: Int, _ dropHeight: CGFloat) {
        let randomNumber = -100//-horizontalRandomness + Int(arc4random())%horizontalRandomness * 2
        self.translationX = CGFloat(randomNumber)
        self.transform = CGAffineTransform(translationX: self.translationX, y: -dropHeight)
    }
    
    public override func draw(_ rect: CGRect) {
        let bezierPath = UIBezierPath()
        bezierPath.move(to: self.startPoint)
        bezierPath.addLine(to: self.endPoint)
        self.color.setStroke()
        bezierPath.lineWidth = self.lineWidth
        bezierPath.stroke()
    }
}


public struct StoreHouseRefreshControlConfig {
    public var color: UIColor
    public var lineWidth: CGFloat
    public var dropHeight: CGFloat
    public var scale: CGFloat
    public var horizontalRandomness: Int
    public var reverseLoadingAnimation: Bool
    public var internalAnimationFactor: CGFloat
    
    public var originalTopContentInset: CGFloat
    public var disappearProgress: CGFloat
    
    public init() {
        color = .white
        lineWidth = 2.0
        dropHeight = 80
        scale = 0.7
        horizontalRandomness = 150
        reverseLoadingAnimation = false
        internalAnimationFactor = 0.7
        
        originalTopContentInset = 80.0
        disappearProgress = 0.0
    }
}

open class StoreHouseRefreshControl: UIView, UIScrollViewDelegate {
    
    private let kloadingIndividualAnimationTiming: CGFloat = 0.8
    private let kbarDarkAlpha: CGFloat = 0.4
    private let kloadingTimingOffset: CGFloat = 0.1
    private let kdisappearDuration: CGFloat = 1.2
    private let krelativeHeightFactor: CGFloat = 2.0/5.0
    
    enum StoreHouseRefreshControlState: Int {
    case StoreHouseRefreshControlStateIdle = 0, StoreHouseRefreshControlStateRefreshing, StoreHouseRefreshControlStateDisappearing
    }
    
    public let startPointKey = "startPoints"
    private let endPointKey = "endPoints"
    private let xKey = "x"
    private let yKey = "y"
    
    private var state: StoreHouseRefreshControlState = .StoreHouseRefreshControlStateIdle
    private var scrollView: UIScrollView!
    private var barItems: [BarItem] = []
    private var displayLink: CADisplayLink!
    private var target: AnyObject!
    private var action: Selector!
    private var config: StoreHouseRefreshControlConfig!
    

    
    public required init?(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public class func attachToScrollView(_ scrollView: UIScrollView,
                                  _ target: AnyObject,
                                  _ refreshAction: Selector,
                                  _ plist: String,
                                  _ config: StoreHouseRefreshControlConfig) -> StoreHouseRefreshControl
    {
        
        let refreshControl = StoreHouseRefreshControl()
        refreshControl.scrollView = scrollView
        refreshControl.target = target
        refreshControl.action = refreshAction
        refreshControl.config = config
        scrollView.addSubview(refreshControl)
        refreshControl.backgroundColor = .brown
        
        
        var width = 0.0, height = 0.0
        
        guard let path = Bundle.main.url(forResource: plist, withExtension: "plist") else {
            fatalError("read file error!")
        }
        guard let data = try? Data(contentsOf: path) else {
            fatalError("file error")
        }
        let rootDictionary = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! Dictionary<String, Any>
        

        let startPoints = rootDictionary![StoreHouseRefreshControl().startPointKey] as! Array<String>
        let endPoints = rootDictionary![StoreHouseRefreshControl().endPointKey] as! Array<String>
        
        for startPoint in startPoints {
            let sPoint = CGPointFromString(startPoint)
            if sPoint.x > width {
                width = sPoint.x
            }
            if sPoint.y > height {
                height = sPoint.y
            }
        }
        for endPoint in endPoints {
            let ePoint = CGPointFromString(endPoint)
            if ePoint.x > width {
                width = ePoint.x
            }
            if ePoint.y > height {
                height = ePoint.y
            }
        }
        refreshControl.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        
        var barItems = Array<BarItem>()
        for i in 0..<startPoints.count {
            let startPoint = CGPointFromString(startPoints[i])
            let endPoint = CGPointFromString(endPoints[i])
            
            let barItem = BarItem().initWithFrame(refreshControl.frame, startPoint, endPoint, config.color, config.lineWidth)
            barItem.setHorizontalRandomness(config.horizontalRandomness, config.dropHeight)

            barItem.tag = i
            barItem.backgroundColor = UIColor.clear
            if (0 == i) {
                barItem.backgroundColor = .red
            }
            barItem.alpha = 0
            barItems.append(barItem)
            refreshControl.addSubview(barItem)
        }
        refreshControl.barItems = barItems
        refreshControl.frame = CGRect(x: 0, y: 0, width: width, height: height)
        refreshControl.center = CGPoint(x: UIScreen.main.bounds.size.width*0.5, y: 0)
        for barItem in refreshControl.barItems {
            barItem.setupWithFrame(refreshControl.frame)
        }
        
        refreshControl.transform = CGAffineTransform(scaleX: config.scale, y: config.scale)
        
        return refreshControl
    }
    
    // UIScrollViewDelegate
    public func scrollViewDidScroll() {
        if config.originalTopContentInset == 0 {
            config.originalTopContentInset = self.scrollView.contentInset.top
        }
        self.center = CGPoint(x: UIScreen.main.bounds.size.width*0.5, y: realContentOffsetY()*krelativeHeightFactor)
        if self.state == .StoreHouseRefreshControlStateIdle {
            updateBarItemsWithProgres(animationProgress())
        }
    }
    
    public func scrollViewDidEndDragging() {
        if self.state == .StoreHouseRefreshControlStateIdle && realContentOffsetY() < -config.dropHeight {
            
            if animationProgress() == 1 {
                self.state = .StoreHouseRefreshControlStateRefreshing
            }
            
            if self.state == .StoreHouseRefreshControlStateRefreshing {
                var newInsets = self.scrollView.contentInset
                newInsets.top = self.config.originalTopContentInset + config.dropHeight
                let contentOffset = self.scrollView.contentOffset
                
                UIView.animate(withDuration: 0) {
                    self.scrollView.contentInset = newInsets
                    self.scrollView.contentOffset = contentOffset
                } completion: { finished in
                    
                }
                
                
                if self.target.responds(to: self.action) {
                    self.target.perform(self.action, with: self)
                }
                
                startLoadingAnimation()
            }
        } else {
            finishingLoading()
        }
    }
  
    
    // private Methods
    private func animationProgress() -> CGFloat {
        return min(1.0, max(0, fabs(realContentOffsetY()/config.dropHeight)))
    }
    
    private func realContentOffsetY() -> CGFloat {
        return self.scrollView.contentOffset.y + config.originalTopContentInset
    }
    
    private func updateBarItemsWithProgres(_ progress: CGFloat) {
        for barItem in self.barItems {
            guard let index = self.barItems.firstIndex(of: barItem) else { return }
            let startPadding = (1.0 - config.internalAnimationFactor)/(CGFloat)(self.barItems.count) * (CGFloat)(index)
            let endPadding = 1 - config.internalAnimationFactor - startPadding
            
            if (progress == 1) || (progress >= 1-endPadding) {
                barItem.transform = CGAffineTransform.identity
                barItem.alpha = kbarDarkAlpha
            } else if progress == 0 {
                barItem.setHorizontalRandomness(config.horizontalRandomness, config.dropHeight)
            } else {
                var realProgress: CGFloat
                if progress <= startPadding {
                    realProgress = 0
                } else {
                    realProgress = min(1, (progress - startPadding)/config.internalAnimationFactor)
                }
                
                barItem.transform = CGAffineTransform(translationX: barItem.translationX*(1-realProgress), y: -config.dropHeight*(1-realProgress))
                barItem.transform = CGAffineTransform(rotationAngle: Double.pi*(realProgress))
                barItem.transform = CGAffineTransform(scaleX: realProgress, y: realProgress)
                barItem.alpha = realProgress * kbarDarkAlpha
            }
        }
    }
    
    private func startLoadingAnimation() {
        if self.config.reverseLoadingAnimation == true {
            let count = self.barItems.count
            for i in count-1...0 {
                let barItem = barItems[i]
                self.perform(#selector(barItemAnimation(_:)), with: barItem, afterDelay: (CGFloat)(self.barItems.count - i - 1) * kloadingTimingOffset, inModes: [RunLoopMode.commonModes])
            }
        } else {
            for i in 0..<self.barItems.count {
                let barItem = self.barItems[i]
                self.perform(#selector(barItemAnimation(_:)), with: barItem, afterDelay: (CGFloat)(i) * kloadingTimingOffset, inModes: [RunLoopMode.commonModes])
            }
        }
    }
    
    @objc private func barItemAnimation(_ barItem: BarItem) {
        if self.state == .StoreHouseRefreshControlStateRefreshing {
            barItem.alpha = 1
            barItem.layer.removeAllAnimations()
            UIView.animate(withDuration: kloadingIndividualAnimationTiming) { [self] in
                barItem.alpha = self.kbarDarkAlpha
            }
            
            var isLastOne = false
            if config.reverseLoadingAnimation {
                isLastOne = barItem.tag == 0
            } else {
                isLastOne = barItem.tag == self.barItems.count - 1
            }
            
            if isLastOne == true && self.state == .StoreHouseRefreshControlStateRefreshing {
                startLoadingAnimation()
            }
        }
    }
    
    @objc private func updateDisappearAniation() {
        if config.disappearProgress >= 0.0 && config.disappearProgress <= 1 {
            config.disappearProgress -= 1.0/60.0/kdisappearDuration
            updateBarItemsWithProgres(config.disappearProgress)
        }
    }
    
    // public Methods
   
    @objc public func finishingLoading() {
        
        self.state = .StoreHouseRefreshControlStateDisappearing
        var newInsets = self.scrollView.contentInset
        newInsets.top = self.config.originalTopContentInset
        UIView.animate(withDuration: kdisappearDuration) { [self] in
            self.scrollView.contentInset = newInsets
            self.scrollView.contentOffset = CGPoint(x: 0, y: -config.originalTopContentInset)
        } completion: { [self] finished in
            self.state = .StoreHouseRefreshControlStateIdle
            self.displayLink.invalidate()
            config.disappearProgress = 1
        }
        
        for barItem in self.barItems {
            barItem.layer.removeAllAnimations()
            barItem.alpha = kbarDarkAlpha
        }
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(updateDisappearAniation))
        self.displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        config.disappearProgress = 1
    }
}


extension UIColor {
    static func randomColor() -> UIColor {
        let red = arc4random()%UInt32(255.0), green = arc4random()%UInt32(255.0), blue = arc4random()%UInt32(255.0)
        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
    }
}
