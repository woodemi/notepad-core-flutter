#import <CoreBluetooth/CoreBluetooth.h>
#import "NotepadCorePlugin.h"

# pragma CBPeripheral+Extensions

@interface CBPeripheral (Extensions)
@end

@implementation CBPeripheral (Extensions)
- (CBCharacteristic *)getCharacteristic:(NSString *)characteristic ofService:(NSString *)service {
    NSUInteger serviceIndex = [self.services indexOfObjectPassingTest:^BOOL(CBService *obj, NSUInteger idx, BOOL *stop) {
        return [obj.UUID.UUIDString isEqualToString:service];
    }];
    NSArray<CBCharacteristic *> *characteristics = self.services[serviceIndex].characteristics;
    NSUInteger characteristicIndex = [characteristics indexOfObjectPassingTest:^BOOL(CBCharacteristic *obj, NSUInteger idx, BOOL *stop) {
        return [obj.UUID.UUIDString isEqualToString:characteristic];
    }];
    return characteristics[characteristicIndex];
}

- (void)setNotifiable:(NSString *)bleInputProperty forCharacteristic:(NSString *)characteristic ofService:(NSString *)service {
    [self setNotifyValue:![bleInputProperty isEqualToString:@"disabled"]
       forCharacteristic:[self getCharacteristic:characteristic ofService:service]];
}
@end

# pragma NotepadCorePlugin

@interface NotepadCorePlugin () <CBCentralManagerDelegate, FlutterStreamHandler, CBPeripheralDelegate>
@property(nonatomic, strong) CBCentralManager *manager;
@property(nonatomic, strong) NSMutableDictionary<NSString *, CBPeripheral *> *discoveredPeripherals;
@property(nonatomic, strong) CBPeripheral *peripheral;

@property(nonatomic, strong) dispatch_group_t serviceConfigGroup;

@property(nonatomic, strong) FlutterBasicMessageChannel *messageChannel;
@property(nonatomic, strong) FlutterBasicMessageChannel *characteristicConfigChannel;
@property(nonatomic, strong) FlutterEventSink scanResultSink;

@end

@implementation NotepadCorePlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    NotepadCorePlugin *notepadCorePlugin = [[NotepadCorePlugin alloc] initWithRegistrar:registrar];
    FlutterMethodChannel *methodChannel = [FlutterMethodChannel methodChannelWithName:@"notepad_core/method" binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:notepadCorePlugin channel:methodChannel];
    [[FlutterEventChannel eventChannelWithName:@"notepad_core/event.scanResult" binaryMessenger:[registrar messenger]] setStreamHandler:notepadCorePlugin];
}

- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    if (self = [super init]) {
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _discoveredPeripherals = [[NSMutableDictionary alloc] init];
        _messageChannel = [FlutterBasicMessageChannel messageChannelWithName:@"notepad_core/message" binaryMessenger:[registrar messenger]];
        _characteristicConfigChannel = [FlutterBasicMessageChannel messageChannelWithName:@"notepad_core/message.characteristicConfig"
                                                                          binaryMessenger:[registrar messenger]];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSLog(@"handleMethodCall %@", call.method);
    if ([call.method isEqualToString:@"startScan"]) {
        [_manager scanForPeripheralsWithServices:nil options:nil];
        result(nil);
    } else if ([call.method isEqualToString:@"stopScan"]) {
        [_manager stopScan];
        result(nil);
    } else if ([call.method isEqualToString:@"connect"]) {
        NSString *deviceId = call.arguments[@"deviceId"];
        _peripheral = _discoveredPeripherals[deviceId];
        _peripheral.delegate = self;
        [_manager connectPeripheral:_peripheral options:nil];
        result(nil);
    } else if ([call.method isEqualToString:@"disconnect"]) {
        [_manager cancelPeripheralConnection:_peripheral];
        _peripheral = nil;
        result(nil);
    } else if ([call.method isEqualToString:@"discoverServices"]) {
        [_peripheral discoverServices:nil];
        result(nil);
    } else if ([call.method isEqualToString:@"setNotifiable"]) {
        NSString *service = call.arguments[@"service"];
        NSString *characteristic = call.arguments[@"characteristic"];
        NSString *bleInputProperty = call.arguments[@"bleInputProperty"];
        [_peripheral setNotifiable:bleInputProperty forCharacteristic:characteristic ofService:service];
        result(nil);
    } else if ([call.method isEqualToString:@"writeValue"]) {
        NSString *service = call.arguments[@"service"];
        NSString *characteristic = call.arguments[@"characteristic"];
        FlutterStandardTypedData *value = call.arguments[@"value"];
        [_peripheral writeValue:[value data]
              forCharacteristic:[_peripheral getCharacteristic:characteristic ofService:service]
                           type:CBCharacteristicWriteWithResponse];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

# pragma CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"centralManagerDidUpdateState %ld", (long) central.state);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"centralManager:didDiscoverPeripheral %@ %@", peripheral.name, peripheral.identifier);
    [_discoveredPeripherals setValue:peripheral forKey:peripheral.identifier.UUIDString];

    NSData *manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    if (_scanResultSink)
        _scanResultSink(@{
                @"name": peripheral.name ? peripheral.name : @"",
                @"deviceId": peripheral.identifier.UUIDString,
                @"manufacturerData": [FlutterStandardTypedData typedDataWithBytes:(manufacturerData ? manufacturerData : [NSData new])],
                @"rssi": RSSI,
        });
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"centralManager:didConnect %@", peripheral.identifier);
    [_messageChannel sendMessage:@{@"ConnectionState": @"Connected"}];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"centralManager:didDisconnectPeripheral: %@ error: %@", peripheral.identifier, error);
    [_messageChannel sendMessage:@{@"ConnectionState": @"Disconnected"}];
}

# pragma FlutterStreamHandler

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    NSString *name = [arguments objectForKey:@"name"];
    NSLog(@"NotepadCorePlugin onListenWithArguments：%@", name);
    if ([name isEqualToString:@"scanResult"]) {
        _scanResultSink = events;
    }
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    NSString *name = [arguments objectForKey:@"name"];
    NSLog(@"NotepadCorePlugin onCancelWithArguments：%@", name);
    if ([name isEqualToString:@"scanResult"]) {
        _scanResultSink = nil;
    }
    return nil;
}

# pragma CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    NSLog(@"peripheral: %@ didDiscoverServices: %@", peripheral.identifier, error);
    _serviceConfigGroup = dispatch_group_create();
    for (CBService *service in peripheral.services) {
        dispatch_group_enter(_serviceConfigGroup);
        [peripheral discoverCharacteristics:nil forService:service];
    }
    dispatch_group_notify(_serviceConfigGroup, dispatch_get_main_queue(), ^{
        self->_serviceConfigGroup = nil;
        [self->_messageChannel sendMessage:@{@"ServiceState": @"Discovered"}];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"peripheral:didDiscoverCharacteristicsForService (%@, %@)", service.UUID.UUIDString, characteristic.UUID.UUIDString);
    }
    dispatch_group_leave(_serviceConfigGroup);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"peripheral:didUpdateNotificationStateFor %@ %d", characteristic.UUID, characteristic.isNotifying);
    [_characteristicConfigChannel sendMessage:characteristic.UUID.UUIDString];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"peripheral:didWriteValueForCharacteristic %@ %@ error: %@", characteristic.UUID.UUIDString, characteristic.value, error);
}

@end
