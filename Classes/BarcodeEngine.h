//
//  BarcodeEngine.h
//  Barcode
//
//  Created by Stefan Hafeneger on 22.09.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	BarcodeTypeDataMatrix,
	BarcodeTypeQRCode
} BarcodeType;

@protocol BarcodeEngineDelegate;

@interface BarcodeEngine : NSObject {
	id<BarcodeEngineDelegate> _delegate;
	BOOL _running, _cancel;
}
#pragma mark Properties
@property(nonatomic, retain) id<BarcodeEngineDelegate> delegate;
@property(nonatomic, getter=isRunning) BOOL running;
@property(nonatomic) BOOL cancel;
#pragma mark Class
+ (BarcodeEngine *)barcodeEngineWithBarcodeType:(BarcodeType)type;
#pragma mark Public
- (void)encodeString:(NSString *)string;
- (void)decodeImage:(UIImage *)image;
- (void)decodeImage:(UIImage *)image withRect:(CGRect)rect;
- (void)cancelOperation;
#pragma mark Protected
- (CGImageRef)grayImageFromImage:(UIImage *)image withRect:(CGRect)rect;
- (CGImageRef)rotatedImage:(CGImageRef)image withOrientation:(UIImageOrientation)orientation;
@end

@protocol BarcodeEngineDelegate <NSObject>
@optional
- (void)barcodeEngine:(BarcodeEngine *)barcodeEngine willEncodeString:(NSString *)string;
- (void)barcodeEngine:(BarcodeEngine *)barcodeEngine willDecodeImage:(UIImage *)image;
- (void)barcodeEngine:(BarcodeEngine *)barcodeEngine didEncodeString:(NSString *)string withImage:(UIImage *)image;
- (void)barcodeEngine:(BarcodeEngine *)barcodeEngine didDecodeImage:(UIImage *)image withString:(NSString *)string;
- (void)barcodeEngine:(BarcodeEngine *)barcodeEngine didNotEncodeString:(NSString *)string;
- (void)barcodeEngine:(BarcodeEngine *)barcodeEngine didNotDecodeImage:(UIImage *)image;
- (void)barcodeEngineDidCancelOperation:(BarcodeEngine *)barcodeEngine;
- (void)barcodeEngineDidStopOperation:(BarcodeEngine *)barcodeEngine;
@end
