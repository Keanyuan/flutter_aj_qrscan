//
//  QRHelper.swift
//  Dealers
//
//  Created by 祁志远 on 2017/7/28.
//  Copyright © 2017年 Anji-Allways. All rights reserved.
//

import UIKit
import AudioToolbox
import Photos

class QRHelper: NSObject {
    ///1.单例
    
    static let shareTool = QRHelper()
    private override init() {}
    
    ///3.确认弹出框
    
    class func confirm(title:String?,message:String?,controller:UIViewController,handler: ( (UIAlertAction) -> Swift.Void)? = nil)
    {
        
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let entureAction = UIAlertAction(title: "确定", style: .destructive, handler: handler)
        alertVC.addAction(entureAction)
        controller.present(alertVC, animated: true, completion: nil)
        
    }
    
    ///4.播放声音
    
    class func playAlertSound(sound:String)
    {
        
        guard let soundPath = Bundle.main.path(forResource: sound, ofType: nil)  else { return }
        guard let soundUrl = NSURL(string: soundPath) else { return }
        
        var soundID:SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundUrl, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
    
    //5.0请求相机权限
    class func requestCameraAuthorization(){
        // 尚未请求,立即请求
        PHPhotoLibrary.requestAuthorization({ (status) -> Void in
            if status == .authorized {
                // 用户同意
            } else {
            }
            
        })
        
    }
    //5.1请求相册权限
    class func requestPhotoAuthorization(){
        // 尚未请求,立即请求
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (status) -> Void in
        })
    }
    
    // 6.相机权限
    class func isRightCamera() -> Bool {
        
        var isCanNext = false
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:// 用户已授权
            isCanNext = true
        case .denied://否认
            isCanNext = false
        case .notDetermined:// 尚未请求,立即请求
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (status) -> Void in
                if status {
                    isCanNext = true
                }else {
                    isCanNext = false
                }
            })
        case .restricted://限制
            isCanNext = false
        }
        
        if !isCanNext {
            QRHelper.confirm(title: "未获得授权使用相机", message: "请在iOS\"设置\"-\"隐私\"-\"相机\"中打开", controller: UIViewController.currentViewController()!, handler: { (_) in
            })
        }
        
        return isCanNext
    }
    
    // 7.相册权限
    class func isRightPhoto() -> Bool {
        var isCanNext = false
        switch PHPhotoLibrary.authorizationStatus() {
        case .denied://否认
            isCanNext = false
        // 用户拒绝,提示开启
        case .notDetermined:
            // 尚未请求,立即请求
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                if status == .authorized {
                    // 用户同意
                    isCanNext = true
                } else {
                    isCanNext = false
                }
                
            })
        case .restricted://限制
            isCanNext = false
        // 用户无法解决的无法访问
        case .authorized:
            // 用户已授权
            isCanNext = true
        }
        
        
        if !isCanNext {
            QRHelper.confirm(title: "未获得授权使用相册", message: "请在iOS\"设置\"-\"隐私\"-\"相机\"中打开", controller: UIViewController.currentViewController()!, handler: { (_) in
            })
        }
        
        return isCanNext
    }


}

extension UIColor {

    
    // MARK: - RGB颜色
    public class func rgbColor(r: Float, g: Float, b: Float, a: Float) -> UIColor {
        return UIColor(red: CGFloat(r/255.0), green: CGFloat(g/255.0), blue: CGFloat(b/255.0), alpha: 1.0)
    }
    
    // MARK: - 随机色
    public class func getRandomColor() -> UIColor {
        
        return cl_color(r: arc4random() % UInt32(256.0), g: arc4random() % UInt32(256.0), b: arc4random() % UInt32(256.0))
    }
    
    private class func cl_color(r:UInt32, g:UInt32, b:UInt32) -> UIColor {
        return UIColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1.0)
    }
    
    //MARK: - UIColor转UIImage
    public class func colorToImage(color: UIColor) -> UIImage {
        
        let rect = CGRect(x: 0, y: 0, width: 1.0, height: 1.0)
        
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let Image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Image!
        
    }
    
    //MARK: - UIImage转UIColor
    public class func imageToColor(image: UIImage) -> UIColor {
        return UIColor(patternImage: image)
    }
    
    //MARK: - UIView转UIImage
    public class func convertViewToImage(view: UIView) -> UIImage {
        UIGraphicsBeginImageContext(view.bounds.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
        
    }
    
    
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, _ alpha: CGFloat = 1.0) {
        self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: alpha)
    }
    
    class func randomColor() -> UIColor{
        return UIColor(r: CGFloat(arc4random_uniform(256)), g: CGFloat(arc4random_uniform(256)), b: CGFloat(arc4random_uniform(256)))
    }
    
    convenience init(_ hexString:String, _ alpha: CGFloat = 1.0) {
        let scanner:Scanner = Scanner(string:hexString)
        var valueRGB:UInt32 = 0
        if scanner.scanHexInt32(&valueRGB) == false {
            self.init(red: 0,green: 0,blue: 0,alpha: 0)
        }else{
            self.init(
                red:CGFloat((valueRGB & 0xFF0000)>>16)/255.0,
                green:CGFloat((valueRGB & 0x00FF00)>>8)/255.0,
                blue:CGFloat(valueRGB & 0x0000FF)/255.0,
                alpha:CGFloat(alpha)
            )
        }
    }
    
}




class QRAssetManager {
    static func image(_ named: String) -> UIImage? {
        return UIImage(named: "qr_assets.bundle/\(named)", in: Bundle(for: QRAssetManager.self), compatibleWith: nil)
    }
}
