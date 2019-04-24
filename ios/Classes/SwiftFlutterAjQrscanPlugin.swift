import Flutter
import UIKit

public class SwiftFlutterAjQrscanPlugin: NSObject, FlutterPlugin, QRCodeViewControllerDelegate {
    
    var flutter_result : FlutterResult?
    var hostViewController : UIViewController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_aj_qrscan", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterAjQrscanPlugin()
//    instance.hostViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    instance.hostViewController = UIApplication.shared.delegate?.window??.rootViewController

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "aj_qr_scan":
        self.flutter_result = result;
        showBarcodeView()
    default:
        result(FlutterMethodNotImplemented)
    }
    
  }
    private func showBarcodeView(){
        let qrvc = QRCodeViewController()
        qrvc.delegate = self;
        self.hostViewController?.present(qrvc, animated: true, completion: nil)
    }
    
    func qrCodeViewController(_ controller: UIViewController, scanResult: String) {
        if((self.flutter_result) != nil){
            self.flutter_result!(scanResult);
        }
    }
    func qrCodeViewController(_ controller: UIViewController, failErrorCode: String) {
        if((self.flutter_result) != nil){
            //[FlutterError errorWithCode:errorCode message:nil details:nil]
            self.flutter_result!(FlutterError(code: failErrorCode, message: nil, details: nil));
        }
    }
    
}

