//
//  CustomWindow.m
//  ScreenshotWatermark
//
//  Created by Alix on 2018/5/21.
//  Copyright © 2018 Guanglu. All rights reserved.
//

#import "CustomWindow.h"
#if DEBUG
#import "User.h"
#endif

@interface UIColor (random)
+ (nonnull instancetype)randomDarkColor:(CGFloat)alpha;
@end
@implementation UIColor (random)
+ (instancetype)randomDarkColor:(CGFloat)alpha {
    CGFloat r = (random() % 255) / 255.0;
    CGFloat g = (random() % 255) / 255.0;
    CGFloat b = (random() % 255) / 255.0;
    
    while (r > 0.9 && g > 0.9 & b > 0.9) {
        r = (random() % 255) / 255.0;
        g = (random() % 255) / 255.0;
        b = (random() % 255) / 255.0;
    }
    return [UIColor colorWithRed:r green:g blue:b alpha:MIN(1, MAX(0, alpha))];
}
@end

@interface CustomWindow ()
@property(nonatomic, strong, nullable)  CALayer  *watermarkLayer;

@end

@implementation CustomWindow

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"frame"];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (_watermarkText.length && [keyPath isEqualToString:@"frame"] && [object isEqual:self]) {
        [self bringWatermarkLayerToFront];
    }
}

- (void)addSubview:(UIView *)view {
    [super addSubview:view];
    [self bringWatermarkLayerToFront];
}

- (void)willRemoveSubview:(UIView *)subview {
    [super willRemoveSubview:subview];
    [self bringWatermarkLayerToFront];
}
- (void)bringWatermarkLayerToFront {
#if DEBUG
    User *user = [(NSObject*)(UIApplication.sharedApplication.delegate) valueForKey:@"user"];
    if ([_watermarkText isEqualToString:user.userName]) {
        [self privateSetWatermarkText:user.userID];
    } else {
        [self privateSetWatermarkText:user.userName];
    }
#endif
    
    if (_watermarkText.length < 1) {
        [_watermarkLayer removeFromSuperlayer];
        _watermarkLayer = nil;
        return;
    }
    UIImage *img = [self watermarkWithText:_watermarkText
                                    colors:@[[UIColor randomDarkColor:0.003],
                                             [UIColor randomDarkColor:0.003],
                                             [UIColor randomDarkColor:0.003]]
                                  fontSize:42];
    
    if (img == nil) {
        [_watermarkLayer removeFromSuperlayer];
        _watermarkLayer = nil;
        return;

    }

    if (nil == _watermarkLayer) {
        _watermarkLayer = [CALayer layer];
    }
    _watermarkLayer.contents = (__bridge id _Nullable)(img.CGImage);
    _watermarkLayer.frame = self.bounds;
    [_watermarkLayer removeFromSuperlayer];

    [self.layer insertSublayer:_watermarkLayer atIndex:(unsigned) self.layer.sublayers.count];
    
}

- (void)setWatermarkText:(NSString *)watermarkText {
    [self privateSetWatermarkText:watermarkText];
    [self bringWatermarkLayerToFront];
    
}
- (void)privateSetWatermarkText:(NSString*)watermarkText {
    NSString *text = [watermarkText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (nil == text || text.length < 1) {
        [_watermarkLayer removeFromSuperlayer];
        _watermarkLayer = nil;
        return;
    }
    
    NSString *num = [text stringByTrimmingCharactersInSet:NSCharacterSet.decimalDigitCharacterSet];
    if (num.length < 1) {
        NSInteger intValue = [text integerValue];
        // POSIX SHELL
        // data="88888"
        // printf '%#d\n' "$((( ((${data} ^ 147369) - 1026) / 3) - 2018))"
        intValue = ((intValue + 2018) * 3 + 1026) ^ 147369;
        _watermarkText = [NSString stringWithFormat:@"%ld", intValue];
    } else {
        _watermarkText = text;
    }
}

- (nullable UIImage*)watermarkWithText:(nonnull NSString*)text colors:(nonnull NSArray<UIColor*>*)colors fontSize:(CGFloat)fontSize {
    const NSInteger colorsCount = colors.count;
    if (colorsCount < 1) {
        return nil;
    }
    
    // 太小没啥用, 尤其是微信分享压缩后
    // 太大也不太好, 如果字符数过多, 或截图后再截出一小部分，有可能显示不全
    if (fontSize < 20) {
        fontSize = 20;
    }
    
    CGRect rect = self.bounds;
    CGSize size = rect.size;
    UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx) {
        [UIColor.clearColor set];
        CGContextFillRect(ctx, rect);
        NSInteger hypotenuse = (NSInteger)sqrt(size.width * size.width + size.height * size.height);
        
        NSString *targetString = text;
        NSDictionary *attr = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]};
        while (true) {
            NSInteger width = ((NSInteger)[targetString sizeWithAttributes:attr].width) >> 1;
            if (width > hypotenuse) {
                break;
            }
            targetString = [targetString stringByAppendingFormat:@"%@ ", text];
        }
        
        const CGFloat oneWidth = [text sizeWithAttributes:attr].width;
        
        const int rowCount = 20;
        const CGFloat startY = 20;
        const CGFloat startX = -(hypotenuse * 0.8);
        const CGFloat oneHeight = hypotenuse / rowCount;
        CGFloat angle =  -1 / ((CGFloat)(rand() % 3 + 2)) * M_PI;
        CGContextRotateCTM(ctx, angle);

        
        for (NSInteger idx=0; idx<rowCount; idx++) {
            attr =  @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize], NSForegroundColorAttributeName: colors[idx % colorsCount]};
            [targetString drawAtPoint:CGPointMake(startX - oneWidth * (idx % colorsCount / (CGFloat)(colorsCount)), startY + idx * oneHeight) withAttributes:attr];
        }
        CGContextRotateCTM(ctx, -angle);
        
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return img;
    }
    return nil;
}


@end
