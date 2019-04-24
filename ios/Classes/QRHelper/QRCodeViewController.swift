//
//  QRCodeViewController.swift
//  Dealers
//
//  Created by 祁志远 on 2017/7/27.
//  Copyright © 2017年 Anji-Allways. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

enum QRCodeSourceType: Int{
    case oneDimension = 0 //一维码
    case twoDimension  // 二维码
}

private let color_string = "0x4FCBFF";
private let kMargin = 60
private let kBorderW = 140
/// 屏幕的宽
private let SCREENW = UIScreen.main.bounds.size.width
/// 屏幕的高
private let SCREENH = UIScreen.main.bounds.size.height
private let scanViewW = SCREENW - CGFloat(kMargin * 2)
private let scanViewH = SCREENW - CGFloat(kMargin * 2)
private let kImageMaxSize = CGSize(width: 1000, height: 1000)


protocol QRCodeViewControllerDelegate : class {
    func qrCodeViewController(_ controller : UIViewController, scanResult: String)
    func qrCodeViewController(_ controller : UIViewController, failErrorCode: String)
    
}

class QRCodeViewController: UIViewController {
    var sourceType: QRCodeSourceType = .oneDimension
    var scanView: UIView? = nil
    var scanImageView: UIView? = nil
    var session = AVCaptureSession()
    weak var delegate : QRCodeViewControllerDelegate?

    
//    fileprivate var qrHelperView: QRHelperView = {
//        let qrHelperView = Bundle.main.loadNibNamed(String(describing: QRHelperView.self), owner: nil, options: nil)?.last as! QRHelperView
//        return qrHelperView
//    }()
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setQRStartAinmation()
    }
    
    @objc func setQRStartAinmation(){
        self.session.startRunning()
        self.scanImageView?.layer.isHidden = false
        self.resetAnimatinon()
    }
    

    @objc func setQRStopAniamtion(){
        session.stopRunning()
        self.scanImageView?.layer.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
        view.backgroundColor = UIColor.black
        setupMaskView()
        setupScanView()
        scaning()
        setupNavUI()
        NotificationCenter.default.addObserver(self, selector: #selector(setQRStopAniamtion), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setQRStartAinmation), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

    }
    
    
    
    
    /// 整体遮罩设置
    fileprivate func setupMaskView (){
        let maskView = UIView(frame: CGRect(x: -(SCREENH - SCREENW)/2, y: 0, width: SCREENH, height: SCREENH))
        maskView.layer.borderWidth = (SCREENH - scanViewW) / 2
//        maskView.backgroundColor = UIColor.clear
        maskView.layer.borderColor = UIColor(r: 0, g: 0, b: 0, 0.6).cgColor
        view.addSubview(maskView)
        
    }
    
    /// 扫描区域设置
    fileprivate func setupScanView(){
        scanView = UIView(frame: CGRect(x: CGFloat(kMargin), y: CGFloat((SCREENH - scanViewW) / 2), width: scanViewW, height: scanViewH))
        scanView?.backgroundColor = UIColor.clear
        scanView?.clipsToBounds = true
        scanView?.isUserInteractionEnabled = false
        view.addSubview(scanView!)
        
        scanImageView = UIView()
        scanImageView?.backgroundColor = UIColor.init(color_string)
        
        let topLline = UIView()
        topLline.frame = CGRect(x: 0, y: 0, width: scanViewW - 0.5 , height: 0.5)
        topLline.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        scanView?.addSubview(topLline)
        let liftLline = UIView()
        liftLline.frame = CGRect(x: 0, y: 0, width: 0.5, height: scanViewH - 0.5)
        liftLline.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        scanView?.addSubview(liftLline)
        let rightLline = UIView()
        rightLline.frame = CGRect(x: scanViewW - 0.5, y: 0, width: 0.5, height: scanViewH - 0.5)

        rightLline.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        scanView?.addSubview(rightLline)
        let bottomLline = UIView()
        bottomLline.frame = CGRect(x: 0, y: scanViewH - 0.5, width: scanViewW - 0.5, height: 0.5)
        bottomLline.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        scanView?.addSubview(bottomLline)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    fileprivate func scaning(){
        //获取摄像设备
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            if device == nil {
                self.pauseLayer(layer: (self.scanImageView?.layer)!)
                QRHelper.confirm(title: nil, message: "无法扫描", controller: UIViewController.currentViewController()!, handler: { (_) in
                    self.navigationBack()
                })
                return
            }
            
            //创建输入流
            let input = try AVCaptureDeviceInput.init(device: device!)
            //创建输出流
            let output = AVCaptureMetadataOutput()
            //设置扫描范围区域 CGRectMake（y的起点/屏幕的高，x的起点/屏幕的宽，扫描的区域的高/屏幕的高，扫描的区域的宽/屏幕的宽）
            output.rectOfInterest = CGRect(x: (scanView?.frame.origin.y)! / self.view.size.height, y: (scanView?.frame.origin.x)! / self.view.size.width, width: (scanView?.frame.size.height)! / self.view.size.height, height: (scanView?.frame.size.width)! / self.view.size.width)
//            output.rectOfInterest = CGRect(x: 0.1, y: 0, width: 0.9, height: 1)
            //设置代理,在主线程刷新
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            //初始化链接对象 / 高质量采集率
            session.canSetSessionPreset(AVCaptureSession.Preset.high)
            session.addInput(input)
            session.addOutput(output)
            
            //设置扫码支持的编码格式
            /*
             [AVMetadataObjectTypeUPCECode,//一种字母和简单的字符共三十九个字符组成的条形码
             AVMetadataObjectTypeCode39Code,
             AVMetadataObjectTypeCode39Mod43Code,//我国商品码主要就是这和 EAN8
             AVMetadataObjectTypeEAN13Code,
             AVMetadataObjectTypeEAN8Code,//Code39升级版
             AVMetadataObjectTypeCode93Code,
             AVMetadataObjectTypeCode128Code,//一个二维码的格式
             AVMetadataObjectTypePDF417Code,//常用的二维码了  开发中主要用的这个
             AVMetadataObjectTypeQRCode,//用于航空
             AVMetadataObjectTypeAztecCode,//款型二进五出码
             AVMetadataObjectTypeInterleaved2of5Code,//全球贸易货号。主要用于运输方面的条形码。iOS8以后才支持
             AVMetadataObjectTypeITF14Code,
             AVMetadataObjectTypeDataMatrixCode
             ]
             */
            output.metadataObjectTypes = [
                AVMetadataObject.ObjectType.qr,
                AVMetadataObject.ObjectType.code39,
                AVMetadataObject.ObjectType.code128,
                AVMetadataObject.ObjectType.code39Mod43,
                AVMetadataObject.ObjectType.ean13,
                AVMetadataObject.ObjectType.ean8,
                AVMetadataObject.ObjectType.code93]
            
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            layer.frame = view.layer.bounds
            view.layer.insertSublayer(layer, at: 0)
            //开始捕捉
            session.startRunning()
            
        } catch let error as NSError {
            QRHelper.confirm(title: "未获得授权使用摄像头", message: "请在iOS\"设置\"-\"隐私\"-\"相机\"中打开", controller: UIViewController.currentViewController()!, handler: { (_) in
                self.navigationBack()
            })
            
        }
        
    }

    
    @objc fileprivate func resetAnimatinon(){
        let anim = scanImageView?.layer.animation(forKey: "translationAnimation")
        if (anim == nil) {
            let scanViewH = view.bounds.width - CGFloat(kMargin) * 2
            let scanImageViewW = scanView?.bounds.width
            scanImageView?.frame = CGRect(x: 0, y: 0, width: scanImageViewW!, height: 0.5)
            let scanAnim = CABasicAnimation()
            scanAnim.keyPath = "transform.translation.y"
            scanAnim.byValue = [scanViewH]
            scanAnim.duration = 3
            scanAnim.repeatCount = MAXFLOAT
            scanImageView?.layer.add(scanAnim, forKey: "translationAnimation")
            scanView?.addSubview(scanImageView!)
        }
    }
    
    
    
    //暂停动画
    fileprivate func pauseLayer(layer: CALayer) {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }

    
    fileprivate func setupNavUI(){
        let isIPhone8X = SCREENH >= 812 ? true : false
        let kStatusBarH : CGFloat = isIPhone8X ? 44 : 20
        
        let bttn = UIButton()
        bttn.frame = CGRect(x: 0, y: 0, width: (scanView?.bounds.width)!, height: (scanView?.bounds.height)!)
        bttn.backgroundColor = UIColor.clear
        scanView?.addSubview(bttn)
        
        
        
        
        let topLabel = UILabel()
        topLabel.frame = CGRect(x: self.view.centerX, y: bttn.frame.midY, width: 200, height: 40)
        topLabel.centerX = self.view.centerX;
        topLabel.text = "请将条形码或二维码放在框内"
        topLabel.textColor = UIColor.white
        topLabel.sizeToFit();
        view.addSubview(topLabel)
        
        let backbtn = UIButton()
        backbtn.frame = CGRect(x: 10, y: kStatusBarH + 10, width: 60, height: 30)
//        backbtn.setImage(UIImage(named: "navigation_back_close")?.withRenderingMode(.alwaysOriginal), for: .normal)
        backbtn.setTitle("╳", for: .normal)
        backbtn.setTitleColor(UIColor.white, for: .normal)
        backbtn.addTarget(self, action: #selector(navigationBack), for: .touchUpInside)
        view.addSubview(backbtn)
        
    }
    @objc fileprivate func navigationBack() {
        self.setQRStopAniamtion()
        self.dismiss(animated: false, completion: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
   
}

//MARK: -
//MARK: AVCaptureMetadataOutputObjects Delegate

//扫描捕捉完成
extension QRCodeViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        //播放声音
        self.setQRStopAniamtion()
        
        if metadataObjects.count > 0 {
            let object = metadataObjects[0]
            let orderNo: String = (object as AnyObject).stringValue
            jumpScanResult(orderNo: orderNo)
        } else {
            failError()
        }
        
    }
    
    

    func failError() {
        if(self.delegate != nil){
            self.setQRStopAniamtion()
            delegate?.qrCodeViewController(self, failErrorCode: "PERMISSION_NOT_GRANTED")
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func jumpScanResult(orderNo : String) {
        if(self.delegate != nil){
            self.setQRStopAniamtion()
            delegate?.qrCodeViewController(self, scanResult: orderNo)
            self.dismiss(animated: false, completion: nil)
        }
    }
}


extension UIViewController {
    class func currentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return currentViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return currentViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return currentViewController(base: presented)
        }
        return base
    }
}


