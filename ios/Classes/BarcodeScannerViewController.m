//
// Created by Matthew Smith on 11/7/17.
//

#import "BarcodeScannerViewController.h"
#import <MTBBarcodeScanner/MTBBarcodeScanner.h>
#import "ScannerOverlay.h"


@implementation BarcodeScannerViewController {
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.previewView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_previewView];
    [self.view addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"V:[previewView]"
                                options:NSLayoutFormatAlignAllBottom
                                metrics:nil
                                  views:@{@"previewView": _previewView}]];
    [self.view addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"H:[previewView]"
                                options:NSLayoutFormatAlignAllBottom
                                metrics:nil
                                  views:@{@"previewView": _previewView}]];
  self.scanRect = [[ScannerOverlay alloc] initWithFrame:self.view.bounds];
  self.scanRect.translatesAutoresizingMaskIntoConstraints = NO;
  self.scanRect.backgroundColor = UIColor.clearColor;
  [self.view addSubview:_scanRect];
  [self.view addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"V:[scanRect]"
                             options:NSLayoutFormatAlignAllBottom
                             metrics:nil
                             views:@{@"scanRect": _scanRect}]];
  [self.view addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:[scanRect]"
                             options:NSLayoutFormatAlignAllBottom
                             metrics:nil
                             views:@{@"scanRect": _scanRect}]];
  [_scanRect startAnimating];
    self.scanner = [[MTBBarcodeScanner alloc] initWithPreviewView:_previewView];
    [self setNav];
  [self updateFlashButton];
}


- (void)setNav {
    BOOL isIPhone8X = [UIScreen mainScreen].bounds.size.height >= 812 ? YES : NO;
    CGFloat kStatusBarH = isIPhone8X ? 44.0 : 20.0;
    
    self.backLabelButton = [[UIButton alloc]init];
    self.backLabelButton.frame = CGRectMake(10, kStatusBarH+5, 60, 30);
    [self.backLabelButton setTitle:@"X" forState:UIControlStateNormal];
    [self.backLabelButton  setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.backLabelButton.layer setBorderColor:[UIColor whiteColor].CGColor];
    self.backLabelButton.layer.cornerRadius = 15;
    self.backLabelButton.layer.masksToBounds = YES;
    self.backLabelButton.layer.borderWidth = 0.5;
    
    [self.backLabelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backLabelButton];
    
    self.flashButton = [[UIButton alloc]init];
    self.flashButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 100, kStatusBarH, 90, 30);
    [self.flashButton setTitle:@"闪光灯" forState:UIControlStateNormal];
    [self.flashButton  setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.flashButton.layer setBorderColor:[UIColor whiteColor].CGColor];
    self.flashButton.layer.cornerRadius = 15;
    self.flashButton.layer.masksToBounds = YES;
    self.flashButton.layer.borderWidth = 0.5;
    self.backLabelButton.titleLabel.font = [UIFont systemFontOfSize:24];
    [self.flashButton addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.scanner.isScanning) {
        [self.scanner stopScanning];
    }
    [MTBBarcodeScanner requestCameraPermissionWithSuccess:^(BOOL success) {
        if (success) {
            [self startScan];
        } else {
          [self.delegate barcodeScannerViewController:self didFailWithErrorCode:@"PERMISSION_NOT_GRANTED"];
          [self dismissViewControllerAnimated:NO completion:nil];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.scanner stopScanning];
    [super viewWillDisappear:animated];
    if ([self isFlashOn]) {
        [self toggleFlash:NO];
    }
}

- (void)startScan {
    NSError *error;
    [self.scanner startScanningWithResultBlock:^(NSArray<AVMetadataMachineReadableCodeObject *> *codes) {
        [self.scanner stopScanning];
         AVMetadataMachineReadableCodeObject *code = codes.firstObject;
        if (code) {
            [self.delegate barcodeScannerViewController:self didScanBarcodeWithResult:code.stringValue];
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    } error:&error];
}

- (void)cancel {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)updateFlashButton {
    if (!self.hasTorch) {
        return;
    }
    if (self.isFlashOn) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Flash Off"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self action:@selector(toggle)];
        [self.flashButton setTitle:@"闪光灯开" forState:UIControlStateNormal];

    } else {
        [self.flashButton setTitle:@"闪光灯关" forState:UIControlStateNormal];
    }
}

- (void)toggle {
    [self toggleFlash:!self.isFlashOn];
    [self updateFlashButton];
}

- (BOOL)isFlashOn {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        return device.torchMode == AVCaptureFlashModeOn || device.torchMode == AVCaptureTorchModeOn;
    }
    return NO;
}

- (BOOL)hasTorch {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        return device.hasTorch;
    }
    return false;
}

- (void)toggleFlash:(BOOL)on {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) return;

    NSError *err;
    if (device.hasFlash && device.hasTorch) {
        [device lockForConfiguration:&err];
        if (err != nil) return;
        if (on) {
            device.flashMode = AVCaptureFlashModeOn;
            device.torchMode = AVCaptureTorchModeOn;
        } else {
            device.flashMode = AVCaptureFlashModeOff;
            device.torchMode = AVCaptureTorchModeOff;
        }
        [device unlockForConfiguration];
    }
}


@end
