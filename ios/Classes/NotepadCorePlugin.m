#import "NotepadCorePlugin.h"

@implementation NotepadCorePlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"notepad_core" binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:[NotepadCorePlugin new] channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    result(FlutterMethodNotImplemented);
}

@end
