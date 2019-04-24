#import "FlutterAjQrscanPlugin.h"
#import <flutter_aj_qrscan/flutter_aj_qrscan-Swift.h>

@implementation FlutterAjQrscanPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterAjQrscanPlugin registerWithRegistrar:registrar];
}
@end
