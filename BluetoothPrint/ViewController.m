//
//  ViewController.m
//  BluetoothPrint
//
//  Created by tuzhengyao 16/3/27.
//  Copyright © 2016年 Tgs. All rights reserved.
//

#import "ViewController.h"
#import "BlueToothManager.h"
#import "SVProgressHUD.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    NSMutableArray * _peripheralList;
    UITableView * _tableView;
    BlueToothManager * _manager;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createTableView];
    
     _manager = [BlueToothManager getInstance];
    [_manager startScan];
    [_manager getBlueListArray:^(NSMutableArray *blueToothArray)
     {
        _peripheralList = blueToothArray;
        [_tableView reloadData];
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(getNameListInfo) userInfo:nil repeats:NO];
}

-(void)didNavBackClicked:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

//扫描设备
-(void)scan{
    [_manager stopScan];
    [_manager startScan];
    [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(getNameListInfo) userInfo:nil repeats:NO];
}

-(void)createTableView
{
    _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}

-(void)getNameListInfo
{
    _peripheralList = [_manager getNameList];
    [_tableView reloadData];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 80;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, _tableView.frame.size.width, 80)];
    backView.backgroundColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0];
    UILabel *labelaa = [[UILabel alloc]initWithFrame:CGRectMake(10, 45, 200, 30)];
    labelaa.backgroundColor = [UIColor clearColor];
    labelaa.text = @"蓝牙设备";
    labelaa.font = [UIFont systemFontOfSize:16];
    labelaa.textColor = [UIColor redColor];
    [backView addSubview:labelaa];
    return backView;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _peripheralList.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [_tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    CBPeripheral * per = _peripheralList[indexPath.row];
    cell.textLabel.text = per.name;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBPeripheral * per = _peripheralList[indexPath.row];
    [_manager connectPeripheralWith:per]; //连接打印机
 
    [_manager connectInfoReturn:^(CBCentralManager *central, CBPeripheral *peripheral, NSString *stateStr)
     {
        if ([stateStr isEqualToString:@"SUCCESS"])
        {
            //连接成功--SUCCESS，连接失败--ERROR，断开连接--DISCONNECT
            
            [SVProgressHUD showSuccessWithStatus:@"连接蓝牙设备成功!" maskType:SVProgressHUDMaskTypeNone];
            
            [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(BlueToothPrint) userInfo:nil repeats:NO];
            
        }else if([stateStr isEqualToString:@"ERROR"])
        {
            [SVProgressHUD showInfoWithStatus:@"蓝牙打印机连接失败，正在重试"];
            [self scan];
        
        }else if([stateStr isEqualToString:@"BLUEDISS"])
        {
            UIAlertView *alertaa = [[UIAlertView alloc]initWithTitle:@"提示" message:@"请连接有效的蓝牙打印设备!" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertaa show];
        }else
        {
            [SVProgressHUD showInfoWithStatus:@"蓝牙打印机断开连接，正在重试"];
            [self scan];
        }
    }];
}

-(void)BlueToothPrint
{
    [_manager getBluetoothPrintWith:nil andPrintType:self.printNum];
    [_manager stopScan];
    [_manager getPrintSuccessReturn:^(BOOL sizeValue)
     {
        if (sizeValue==YES)
        {
            [SVProgressHUD showSuccessWithStatus:@"打印成功!" maskType:SVProgressHUDMaskTypeNone];
            [self.navigationController popViewControllerAnimated:YES];
        }else
        {
            [SVProgressHUD showInfoWithStatus:@"打印失败!"];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
