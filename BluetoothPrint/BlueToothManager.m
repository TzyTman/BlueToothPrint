//
//  BlueToothManager.m
//  BluetoothPrint
//
//  Created by tuzhengyao 16/3/27.
//  Copyright © 2016年 Tgs. All rights reserved.
//

#import "BlueToothManager.h"
#import "IGThermalSupport.h"
#import "MMQRCode.h"
#import "MMPrinterManager.h"
#import "MMReceiptManager.h"
@implementation BlueToothManager

//创建单例类
+(instancetype)getInstance
{
    static BlueToothManager * manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BlueToothManager alloc]init];
    });
    return manager;
}

#pragma mark 公开接口方法

//开始扫描
- (void)startScan
{
    //1.初始化Central端管理器对象
    _manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
    
    //创建存储peripheral设备List
    _peripheralList = [[NSMutableArray alloc]initWithCapacity:0];
}

//停止扫描
-(void)stopScan
{
    [_manager stopScan];
}

-(void)getBlueListArray:(void (^)(NSMutableArray *blueToothArray))listBlock
{
    bluetoothListArr = [listBlock copy];
}

//获取扫描到设备的列表
-(NSMutableArray *)getNameList
{
    return _peripheralList;
}

//连接设备
-(void)connectPeripheralWith:(CBPeripheral *)per
{
    if (per!=nil)
    {
        valuePrint = NO;
        _per = nil;
        _char = nil;
        _readChar = nil;
        //5. 连接Peripheral设备
        [_manager connectPeripheral:per options:nil];
    }
}

//成功回调
-(void)connectInfoReturn:(void(^)(CBCentralManager *central ,CBPeripheral *peripheral,NSString *stateStr))myBlock
{
    conReturnBlock = [myBlock copy];
}

//像蓝牙发送信息
- (void)sendDataWithString:(NSString *)str andInfoData:(NSData *)infoData
{
    if (_per==nil||_char==nil)
    {
        valuePrint = NO;
        if (conReturnBlock)
        {
            conReturnBlock(nil ,nil,@"BLUEDISS");
            return;
        }
        
    }else
    {
        valuePrint = YES;
        if (str==nil||str.length==0)
        {
            if (_per && _char)
            {
                switch (_char.properties & 0x04)
                {
                    case CBCharacteristicPropertyWriteWithoutResponse:
                    {
                        [_per writeValue:infoData forCharacteristic:_char type:CBCharacteristicWriteWithoutResponse];
                        break;
                        
                    }
                    default:
                    {
                        [_per writeValue:infoData forCharacteristic:_char type:CBCharacteristicWriteWithoutResponse];
                        break;
                    }
                }
            }
            
        }else
        {
            NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
            if (_per && _char)
            {
                switch (_char.properties & 0x04)
                {
                    case CBCharacteristicPropertyWriteWithoutResponse:
                    {
                        [_per writeValue:data forCharacteristic:_char type:CBCharacteristicWriteWithoutResponse];
                        break;
                        
                    }
                    default:
                    {
                        [_per writeValue:data forCharacteristic:_char type:CBCharacteristicWriteWithoutResponse];
                        break;
                    }
                }
                
            }
        }
    }
}

-(void)getPrintSuccessReturn:(void(^)(BOOL sizeValue))printBlock
{
    printSuccess = [printBlock copy];
}

//展示蓝牙返回的信息
-(void)showResult
{
    if (printSuccess && valuePrint==YES)
    {
        printSuccess(YES);
    }
}

-(void)getBluetoothPrintWith:(NSDictionary *)dictionary andPrintType:(NSInteger)typeNum
{
    MMReceiptManager *manager =[[MMReceiptManager alloc] init];
    [manager clearData];
    [manager basicSetting];
    [manager writeData_title:@"肯德基" Scale:scale_2 Type:MiddleAlignment];
    UIImage *qrImage =[MMQRCode createBarImageWithOrderStr:@"RN3456789012"];
    [manager writeData_image:qrImage alignment:MiddleAlignment maxWidth:300];
    [manager writeData_items:@[@"收银员:001", @"交易时间:2016-03-17", @"交易号:201603170001"]];
    [manager writeData_line];
    [manager writeData_content:@[@{@"key01":@"名称", @"key02":@"单价", @"key03":@"数量", @"key04":@"总价"}]];
    [manager writeData_line];
    [manager writeData_content:@[@{@"key01":@"汉堡", @"key02":@"10.00", @"key03":@"2", @"key04":@"20.00"}, @{@"key01":@"炸鸡", @"key02":@"8.00", @"key03":@"1", @"key04":@"8.00"}]];
    [manager writeData_line];
    [manager writeData_items:@[@"支付方式:现金", @"应收:28.00", @"实际:30.00", @"找零:2.00"]];
    [manager writeData_title:@"谢谢惠顾" Scale:scale_1 Type:MiddleAlignment];
    [manager writeData_line];
    valuePrint = NO;
    [self openNotify];
    [self sendDataWithString:nil andInfoData:[manager.printerManager sendData]];//线条
    [self showResult];
}

//打开通知
-(void)openNotify
{
    if (_readChar!=nil&&_per!=nil)
    {
        //订阅感兴趣的特性的值
        [_per setNotifyValue:YES forCharacteristic:_readChar];
    }
}

//关闭通知
-(void)cancelNotify
{
    [_per setNotifyValue:NO forCharacteristic:_readChar];
    
}

//断开连接
-(void)cancelPeripheralWith:(CBPeripheral *)per
{
    [_manager cancelPeripheralConnection:_per];
}


#pragma mark  CBCentralManagerDelegate

//2.检查本地设备支持BLE(蓝牙协议)
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        NSLog(@"蓝牙打开，开始扫描");
        // 3.扫描外围设备
        // 查找Peripheral设备
        // 如果第一个参数传递nil，则管理器会返回所有发现的Peripheral设备。
        // 通常我们会指定一个UUID对象的数组，来查找特定的设备
        [central scanForPeripheralsWithServices:nil options:nil];
    }
    else
    {
        NSLog(@"蓝牙不可用");
    }
}

//4. 扫描到的设备
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (_peripheralList.count<8 && peripheral.name.length>1)
    {
         NSLog(@"%@===%@",peripheral.name , RSSI);
        
        [_peripheralList addObject:peripheral];
        
        if (bluetoothListArr)
        {
            bluetoothListArr(_peripheralList);
        }
    }
}

//连接设备失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (conReturnBlock)
    {
        conReturnBlock(central,peripheral,@"ERROR");
    }
   //NSLog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
}

//设备断开连接
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (conReturnBlock)
    {
        conReturnBlock(central,peripheral,@"DISCONNECT");
    }
   //NSLog(@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);
}

//6.连接设备成功
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    _per = peripheral;
    [_per setDelegate:self];
    //7.查找所有的服务
    [_per discoverServices:nil]; //参数传递nil可以查找所有的服务，但一般情况下我们会指定感兴趣的服务
}

#pragma mark CBPeripheralDelegate
//8. 扫描设备的服务
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        //NSLog(@"扫描%@的服务发生的错误是：%@",peripheral.name,[error localizedDescription]);
    }
    else
    {
        for (CBService *service in peripheral.services)
        {
            //9.查找服务中的特性
            [peripheral discoverCharacteristics:nil forService:service];
        }
        
        if (conReturnBlock)
        {
            conReturnBlock(nil,peripheral,@"SUCCESS");
        }
    }
}

//10. 扫描服务的特征值
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    if (error)
    {
        //NSLog(@"扫描服务：------->%@的特征值的错误是：%@",service.UUID,[error localizedDescription]);
    }
    else
    {
        for (CBCharacteristic * cha in service.characteristics)
        {
            CBCharacteristicProperties p = cha.properties;
            if (p & CBCharacteristicPropertyBroadcast)
            {
                
            }
            if (p & CBCharacteristicPropertyRead)
            {
                
            }
            if (p & CBCharacteristicPropertyWriteWithoutResponse)
            {
                _char = cha;
                //NSLog(@"WriteWithoutResponse---扫描服务：%@的特征值为：%@",service.UUID,cha.UUID);
            }
            if (p & CBCharacteristicPropertyWrite)
            {
                //NSLog(@"Write---扫描服务：%@的特征值为：%@",service.UUID,cha.UUID);
            }
            if (p & CBCharacteristicPropertyNotify)
            {
                _readChar = cha;
            }
            //11.获取这个特性值
            [_per readValueForCharacteristic:cha];
            [_per discoverDescriptorsForCharacteristic:cha];
        }
    }
}

//12.获取特征值的信息
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        //NSLog(@"获取特征值%@的错误为%@",characteristic.UUID,error);
    }
    else
    {
        //NSLog(@"------->特征值：%@  value：%@",characteristic.UUID,characteristic.value);
        _responseData = characteristic.value;
    }
}

//扫描特征值的描述
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        //NSLog(@"搜索到%@的Descriptors的错误是：%@",characteristic.UUID,error);
    }
    else
    {
        //        NSLog(@",,,,,,,,,,,characteristic uuid:%@",characteristic.UUID);
        //
        //        for (CBDescriptor * d in characteristic.descriptors)
        //        {
        //            NSLog(@"------->Descriptor uuid:%@",d.UUID);
        //
        //        }
    }
}

//获取描述值的信息
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    //    if (error)
    //    {
    //        NSLog(@"获取%@的描述的错误是：%@",peripheral.name,error);
    //    }
    //    else
    //    {
    //        NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
    //
    //    }
}
@end
