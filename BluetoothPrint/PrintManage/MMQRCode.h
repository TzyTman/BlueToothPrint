//
//  MMQRCode.h
//  RevoSysAuto
//
//  Created by Zhaomike on 16/1/20.
//  Copyright © 2016年 leyutech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MMQRCode : NSObject
/**
 *  创建二维码
 *
 *  @param string
 *  @param name  logo图片名
 *  @param width 宽度
 *
 *  @return image
 */
+ (UIImage *)qrCodeWithString:(NSString *)string logoName:(NSString *)name size:(CGFloat)width;

/**
 *  创建条形码
 *
 *  @param str 条形码字符串
 *
 *  @return image
 */
+ (UIImage*)createBarImageWithOrderStr:(NSString*)str;

@end
