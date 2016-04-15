//
//  MMQRCode.m
//  RevoSysAuto
//
//  Created by Zhaomike on 16/1/20.
//  Copyright © 2016年 leyutech. All rights reserved.
//

#import "MMQRCode.h"

@implementation MMQRCode

+ (UIImage *)qrCodeWithString:(NSString *)string logoName:(NSString *)name size:(CGFloat)width {
    if (string) {
        NSData *strData = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        //创建二维码滤镜
        CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
        [qrFilter setValue:strData forKey:@"inputMessage"];
        [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
        CIImage *qrImage = qrFilter.outputImage;
        //颜色滤镜
        CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
        [colorFilter setDefaults];
        [colorFilter setValue:qrImage forKey:kCIInputImageKey];
        [colorFilter setValue:[CIColor colorWithRed:0 green:0 blue:0] forKey:@"inputColor0"];
        [colorFilter setValue:[CIColor colorWithRed:0.3 green:0.8 blue:0.2] forKey:@"inputColor1"];
        CIImage *colorImage = colorFilter.outputImage;
        //返回二维码
        CGFloat scale = width/31;
        UIImage *codeImage = [UIImage imageWithCIImage:[colorImage imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)]];
        //定制logo
        if (name) {
            UIImage *logo = [UIImage imageNamed:name];
            //二维码rect
            CGRect rect = CGRectMake(0, 0, codeImage.size.width, codeImage.size.height);
            UIGraphicsBeginImageContext(rect.size);
            [codeImage drawInRect:rect];
            //icon尺寸,UIBezierPath
            CGSize logoSize = CGSizeMake(rect.size.width*0.2, rect.size.height*0.2);
            CGFloat x = CGRectGetMidX(rect) - logoSize.width*0.5;
            CGFloat y = CGRectGetMidY(rect) - logoSize.height*0.5;
            CGRect logoFrame = CGRectMake(x, y, logoSize.width, logoSize.height);
            [[UIBezierPath bezierPathWithRoundedRect:logoFrame cornerRadius:10] addClip];
            
            [logo drawInRect:logoFrame];
            UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return resultImage;
        }
        return codeImage;
    }
    return nil;
}

#pragma mark - 创建条形码
+(UIImage*)createBarImageWithOrderStr:(NSString*)str
{
    // 创建条形码
    CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    // 恢复滤镜的默认属性
    [filter setDefaults];
    // 将字符串转换成NSData
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    // 通过KVO设置滤镜inputMessage数据
    [filter setValue:data forKey:@"inputMessage"];
    // 获得滤镜输出的图像
    CIImage *outputImage = [filter outputImage];
    // 将CIImage转换成UIImage，并放大显示
    UIImage *image =[self createNonInterpolatedUIImageFormCIImage:outputImage withSize:300];
    return image;
}

+(UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

@end
