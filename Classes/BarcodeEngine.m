//
//  BarcodeEngine.m
//  Barcode
//
//  Created by Stefan Hafeneger on 22.09.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BarcodeEngine.h"

#import "DataMatrixEngine.h"
#import "QRCodeEngine.h"

@interface BarcodeEngine ()
#pragma mark Private
- (void)encode:(NSDictionary *)dictionary;
- (void)decode:(NSDictionary *)dictionary;
- (void)didEncode:(NSDictionary *)dictionary;
- (void)didDecode:(NSDictionary *)dictionary;
- (void)didNotEncode:(NSDictionary *)dictionary;
- (void)didNotDecode:(NSDictionary *)dictionary;
- (void)didStopOperation;
@end

@implementation BarcodeEngine

#pragma mark Class

+ (BarcodeEngine *)barcodeEngineWithBarcodeType:(BarcodeType)type {
	switch(type) {
		case BarcodeTypeDataMatrix:
			return [[[DataMatrixEngine alloc] init] autorelease];
			break;
		case BarcodeTypeQRCode:
			return [[[QRCodeEngine alloc] init] autorelease];
			break;
	}
	return nil;
}

#pragma mark Allocation

- (id)init {
	self = [super init];
	if(self != nil) {
		self.delegate = nil;
		self.running = NO;
		self.cancel = NO;
	}
	return self;
}

- (void)dealloc {
	self.delegate = nil;
	[super dealloc];
}

#pragma mark Properties

@synthesize delegate = _delegate;
@synthesize running = _running;
@synthesize cancel = _cancel;

#pragma mark Public

- (void)encodeString:(NSString *)string {
	if(!self.isRunning) {
		if(self.delegate != nil && [self.delegate respondsToSelector:@selector(barcodeEngine:willEncodeString:)])
			[self.delegate barcodeEngine:self willEncodeString:string];
		self.running = YES;
		self.cancel = NO;
		[NSThread detachNewThreadSelector:@selector(encode:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:string, @"string", nil]];
	}
}

- (void)decodeImage:(UIImage *)image {
	if(!self.isRunning) {
		if(self.delegate != nil && [self.delegate respondsToSelector:@selector(barcodeEngine:willDecodeImage:)])
			[self.delegate barcodeEngine:self willDecodeImage:image];
		self.running = YES;
		self.cancel = NO;
		[NSThread detachNewThreadSelector:@selector(decode:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:image, @"image", [NSValue valueWithCGRect:CGRectZero], @"rect", nil]];
	}
}

- (void)decodeImage:(UIImage *)image withRect:(CGRect)rect {
	if(!self.isRunning) {
		if(self.delegate != nil && [self.delegate respondsToSelector:@selector(barcodeEngine:willDecodeImage:)])
			[self.delegate barcodeEngine:self willDecodeImage:image];
		self.running = YES;
		self.cancel = NO;
		[NSThread detachNewThreadSelector:@selector(decode:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:image, @"image", [NSValue valueWithCGRect:rect], @"rect", nil]];
	}
}

- (void)cancelOperation {
	if(self.isRunning) {
		self.cancel = YES;
		if(self.delegate != nil && [self.delegate respondsToSelector:@selector(barcodeEngineDidCancelOperation:)])
			[self.delegate barcodeEngineDidCancelOperation:self];
	}
}

#pragma mark Private

- (void)encode:(NSDictionary *)dictionary {
	NSLog(@"encode:");
}

- (void)decode:(NSDictionary *)dictionary {
	NSLog(@"decode:");
}

- (void)didEncode:(NSDictionary *)dictionary {
	if(self.delegate != nil && [self.delegate respondsToSelector:@selector(barcodeEngine:didEncodeString:withImage:)])
		[self.delegate barcodeEngine:self didEncodeString:(NSString *)[dictionary objectForKey:@"string"] withImage:(UIImage *)[dictionary objectForKey:@"image"]];
}

- (void)didDecode:(NSDictionary *)dictionary {
	if(self.delegate != nil && [self.delegate respondsToSelector:@selector(barcodeEngine:didDecodeImage:withString:)])
		[self.delegate barcodeEngine:self didDecodeImage:(UIImage *)[dictionary objectForKey:@"image"] withString:(NSString *)[dictionary objectForKey:@"string"]];
}

- (void)didNotEncode:(NSDictionary *)dictionary {
	if(self.delegate != nil && [self.delegate respondsToSelector:@selector(barcodeEngine:didNotEncodeString:)])
		[self.delegate barcodeEngine:self didNotEncodeString:(NSString *)[dictionary objectForKey:@"string"]];
}

- (void)didNotDecode:(NSDictionary *)dictionary {
	if(self.delegate != nil && [self.delegate respondsToSelector:@selector(barcodeEngine:didNotDecodeImage:)])
		[self.delegate barcodeEngine:self didNotDecodeImage:(UIImage *)[dictionary objectForKey:@"image"]];
}

- (void)didStopOperation {
	self.running = NO;
	if(self.delegate != nil && [self.delegate respondsToSelector:@selector(barcodeEngineDidStopOperation:)])
		[self.delegate barcodeEngineDidStopOperation:self];
}

#pragma mark Protected

- (CGImageRef)grayImageFromImage:(UIImage *)image withRect:(CGRect)rect {
	
	// We have to deal with a CGImage.
	CGImageRef rotatedImage = [self rotatedImage:image.CGImage withOrientation:image.imageOrientation];
	if(rotatedImage == NULL)
		return NULL;
	CGImageRef croppedImage = CGImageCreateWithImageInRect(rotatedImage, rect);
	CGImageRelease(rotatedImage);
	if(croppedImage == NULL)
		return NULL;
	
	// Calculate image dimensions (500 pixel should be enough for decoding).
	CGFloat scale = fminf(1.0f, fmaxf(250.0f / CGImageGetWidth(croppedImage), 250.0f / CGImageGetWidth(croppedImage)));
	NSUInteger width = (NSUInteger)ceilf(CGImageGetWidth(croppedImage) * scale);
	NSUInteger height = (NSUInteger)ceilf(CGImageGetHeight(croppedImage) * scale);
	NSUInteger bytesPerRow = width;
	
	// Create color space object.
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
	if(colorSpaceRef == NULL)
		return NULL;
	
	// Create bitmap context.
	CGContextRef contextRef = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, colorSpaceRef, kCGImageAlphaNone);
	if(contextRef == NULL) {
		CGColorSpaceRelease(colorSpaceRef);
		return NULL;
	}
	
	// Release color space object.
	CGColorSpaceRelease(colorSpaceRef);
	
	CGContextSetAllowsAntialiasing(contextRef, false);
	CGContextSetInterpolationQuality(contextRef, kCGInterpolationNone);
	
	// Scale image to desired size.
	CGContextDrawImage(contextRef, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), croppedImage);
	
	// Get gray image.
	CGImageRef grayImage = CGBitmapContextCreateImage(contextRef);
	
	// Release bitmap context.
	CGContextRelease(contextRef);
	
	// Release CGImage.
	CGImageRelease(croppedImage);
	
	return grayImage;
	
}

- (CGImageRef)rotatedImage:(CGImageRef)image withOrientation:(UIImageOrientation)orientation {
	
	// If up, return image.
	if(orientation == UIImageOrientationUp)
		return image;
	
	size_t width;
	size_t height;
	
	switch(orientation) {
		case UIImageOrientationLeft:
		case UIImageOrientationRight:
			width = CGImageGetHeight(image);
			height = CGImageGetWidth(image);
			break;
		case UIImageOrientationDown:
			width = CGImageGetWidth(image);
			height = CGImageGetHeight(image);
			break;
		default:
			width = CGImageGetWidth(image);
			height = CGImageGetHeight(image);
			break;
	}
	
	// Create bitmap context.
	CGContextRef contextRef = CGBitmapContextCreate(NULL, width, height, CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image), CGImageGetColorSpace(image), CGImageGetBitmapInfo(image));
	if(contextRef == NULL)
		return NULL;
	
	CGContextSetAllowsAntialiasing(contextRef, false);
	CGContextSetInterpolationQuality(contextRef, kCGInterpolationNone);
	
	// Save graphics state.
	CGContextSaveGState(contextRef);
	
	CGRect rect;
	
	switch(orientation) {
		case UIImageOrientationLeft:
			CGContextTranslateCTM(contextRef, (CGFloat)width, 0.0f);
			CGContextRotateCTM(contextRef, M_PI / 2.0f);
			rect = CGRectMake(0.0f, 0.0f, (CGFloat)height, (CGFloat)width);
			break;
		case UIImageOrientationRight:
			CGContextTranslateCTM(contextRef, 0.0f, (CGFloat)height);
			CGContextRotateCTM(contextRef, M_PI / -2.0f);
			rect = CGRectMake(0.0f, 0.0f, (CGFloat)height, (CGFloat)width);
			break;
		case UIImageOrientationDown:
			CGContextTranslateCTM(contextRef, (CGFloat)width, (CGFloat)height);
			CGContextScaleCTM(contextRef, -1.0f, -1.0f);
			rect = CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height);
			break;
		default:
			rect = CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height);
			break;
	}
	
	// Scale image to desired size.
	CGContextDrawImage(contextRef, rect, image);
	
	// Restore graphics state.
	CGContextRestoreGState(contextRef);
	
	// Get image.
	CGImageRef rotatedImage = CGBitmapContextCreateImage(contextRef);
	
	// Release bitmap context.
	CGContextRelease(contextRef);
	
	return rotatedImage;
	
}

@end
