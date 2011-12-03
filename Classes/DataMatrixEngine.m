//
//  DataMatrixEngine.m
//  Barcode
//
//  Created by Stefan Hafeneger on 28.05.08.
//  Copyright 2008 CocoaHeads Aachen. All rights reserved.
//

#import "DataMatrixEngine.h"

#import "dmtx.h"

@interface DataMatrixEngine ()
#pragma mark Private
- (UIImage *)imageForDmtxImage:(DmtxImage *)dmtxImage;
- (DmtxImage *)dmtxImageFromImage:(UIImage *)image withRect:(CGRect)rect;
@end

@implementation DataMatrixEngine

#pragma mark Private

- (void)encode:(NSDictionary *)dictionary {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	/*
	UIImage *image = nil;
	
	// Create dmtx string.
	unsigned char *dmtxString = (unsigned char *)[string cStringUsingEncoding:[NSString defaultCStringEncoding]];
	NSUInteger stringLength = [string lengthOfBytesUsingEncoding:[NSString defaultCStringEncoding]];
	
	// Initialize dmtx encode struct.
	DmtxEncode dmtxEncode = dmtxEncodeStructInit();
	
	// Encode region based on requested scan mode.
	NSInteger result;
//	if(mosaic) {
//		result = dmtxEncodeDataMosaic(&dmtxEncode, (int)stringLength, dmtxString, DMTX_SYMBOL_SQUARE_AUTO);
//	} else {
	result = dmtxEncodeDataMatrix(&dmtxEncode, (int)stringLength, dmtxString, DMTX_SYMBOL_SQUARE_AUTO);
//	}
	if(result == DMTX_SUCCESS)
		image = [self imageForDmtxImage:dmtxEncode.image];
	
	// Free dmtx encode memory.
	dmtxEncodeStructDeInit(&dmtxEncode);
	*/
	[self performSelectorOnMainThread:@selector(didNotEncode:) withObject:dictionary waitUntilDone:NO];
	
	[pool release];
	
}

- (void)decode:(NSDictionary *)dictionary {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	UIImage *image = (UIImage *)[dictionary objectForKey:@"image"];
	
	NSMutableArray *messages = [NSMutableArray array];
	
	// Define timeout in milliseconds.
	long msec = 10000;
	
	// Create dmtx image.
	DmtxImage *dmtxImage = [self dmtxImageFromImage:image withRect:(CGRect)[(NSValue *)[dictionary objectForKey:@"rect"] CGRectValue]];
	if(dmtxImage == NULL) {
		if(!self.cancel)
			[self performSelectorOnMainThread:@selector(didNotDecode:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:image, @"image", nil] waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(didStopOperation) withObject:nil waitUntilDone:NO];
		[pool release];
		return;
	}
	
	if(self.cancel) {
		dmtxImageFree(&dmtxImage);
		[self performSelectorOnMainThread:@selector(didStopOperation) withObject:nil waitUntilDone:NO];
		[pool release];
		return;
	}
	
	// Define dmtx active search area.
	DmtxPixelLoc dmtxPixelLoc0, dmtxPixelLoc1;
	dmtxPixelLoc0.X = dmtxPixelLoc0.Y = 0;
	dmtxPixelLoc1.X = dmtxImage->width - 1;
	dmtxPixelLoc1.Y = dmtxImage->height - 1;
	
	// Initialize dmtx decode struct for image.
	DmtxDecode dmtxDecode = dmtxDecodeStructInit(dmtxImage, dmtxPixelLoc0, dmtxPixelLoc1, 2);
	
	DmtxTime timeout = dmtxTimeAdd(dmtxTimeNow(), msec);
	
	DmtxRegion dmtxRegion;
	DmtxMessage *dmtxMessage;
	
	// Loop once for each detected barcode region.
//	NSUInteger count;
//	for(count = 0; count < 1; count++) {
	for(;;) {
		
		if(self.cancel)
			break;
		
		// Find next barcode region within image.
		dmtxRegion = dmtxDecodeFindNextRegion(&dmtxDecode, &timeout);
		if(dmtxRegion.found != DMTX_REGION_FOUND)
			break;
		
		// Decode region based on requested scan mode.
//		if(mosaic) {
//			dmtxMessage = dmtxDecodeMosaicRegion(&dmtxDecode, &dmtxRegion, -1);
//		} else {
			dmtxMessage = dmtxDecodeMatrixRegion(&dmtxDecode, &dmtxRegion, -1);
//		}
		if(dmtxMessage == NULL)
			continue;
		
		// Convert C string to NSString.
//		NSString *message = [NSString stringWithCString:(const char *)dmtxMessage->output length:(NSUInteger)dmtxMessage->outputIdx];
		NSString *message = [NSString stringWithCString:(const char *)dmtxMessage->output encoding:NSUTF8StringEncoding];
		[messages addObject:message];
		
		// Free dmtx message memory.
		dmtxMessageFree(&dmtxMessage);
		break;
		
	}
	
	// Free dmtx decode memory.
	dmtxDecodeStructDeInit(&dmtxDecode);
	
	// Free dmtx image memory.
	dmtxImageFree(&dmtxImage);
	
	if([messages count] > 0) {
		if(!self.cancel)
			[self performSelectorOnMainThread:@selector(didDecode:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:image, @"image", [messages objectAtIndex:0], @"string", nil] waitUntilDone:NO];
	} else {
		if(!self.cancel)
			[self performSelectorOnMainThread:@selector(didNotDecode:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:image, @"image", nil] waitUntilDone:NO];
	}
	
	[self performSelectorOnMainThread:@selector(didStopOperation) withObject:nil waitUntilDone:NO];
	
	[pool release];
	
}

- (UIImage *)imageForDmtxImage:(DmtxImage *)dmtxImage {
	
	// Calculate image dimensions.
	NSUInteger width = (NSUInteger)dmtxImage->width;
	NSUInteger height = (NSUInteger)dmtxImage->height;
	NSUInteger bytesPerRow = width * 4;
	
	// Create color space object.
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	if(colorSpaceRef == NULL)
		return nil;
	
	// Create context memory.
	unsigned char *data = malloc(bytesPerRow * height);
	if(data == NULL) {
		CGColorSpaceRelease(colorSpaceRef);
		return nil;
	}
	
	// Copy horizontally flipped image data.
	NSUInteger row, column, index;
	for(row = 0; row < height; row++) {
		for(column = 0; column < width; column++) {
			index = (height - row - 1) * width + column;
			data[row * width * 4 + column * 4 + 0] = (unsigned char)255;
			data[row * width * 4 + column * 4 + 1] = dmtxImage->pxl[index][0];
			data[row * width * 4 + column * 4 + 2] = dmtxImage->pxl[index][1];
			data[row * width * 4 + column * 4 + 3] = dmtxImage->pxl[index][2];
		}
	}
	
	// Create bitmap context.
	CGContextRef contextRef = CGBitmapContextCreate((void *)data, width, height, 8, bytesPerRow, colorSpaceRef, kCGImageAlphaPremultipliedFirst);
	if(contextRef == NULL) {
		CGColorSpaceRelease(colorSpaceRef);
		free(data);
		return nil;
	}
	
	// Release color space object.
	CGColorSpaceRelease(colorSpaceRef);
	
	// Create CGImage from bitmap context.
	CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
	if(imageRef == NULL) {
		CGContextRelease(contextRef);
		free(data);
		return nil;
	}
	
	// Release bitmap context.
	CGContextRelease(contextRef);
	
	// Free context memory.
	free(data);
	
	// Create UIImage from CGImage.
	return [[[UIImage alloc] initWithCGImage:imageRef] autorelease];
	
}

- (DmtxImage *)dmtxImageFromImage:(UIImage *)image withRect:(CGRect)rect {
	
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
	NSUInteger bytesPerRow = width * 4;
	
	// Create color space object.
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	if(colorSpaceRef == NULL)
		return NULL;
	
	// Create context memory.
	void *memory = malloc(bytesPerRow * height);
	if(memory == NULL) {
		CGColorSpaceRelease(colorSpaceRef);
		return NULL;
	}
	
	// Create bitmap context.
	CGContextRef contextRef = CGBitmapContextCreate(memory, width, height, 8, bytesPerRow, colorSpaceRef, kCGImageAlphaPremultipliedFirst);
	if(contextRef == NULL) {
		CGColorSpaceRelease(colorSpaceRef);
		free(memory);
		return NULL;
	}
	
	// Release color space object.
	CGColorSpaceRelease(colorSpaceRef);
	
	CGContextSetAllowsAntialiasing(contextRef, false);
	CGContextSetInterpolationQuality(contextRef, kCGInterpolationNone);
	
	// Scale image to desired size.
	CGContextDrawImage(contextRef, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), croppedImage);
	
	// Get context data.
	unsigned char *data = (unsigned char *)CGBitmapContextGetData(contextRef);
	if(data == NULL) {
		CGContextRelease(contextRef);
		free(memory);
		return NULL;
	}
	
	// Create dmtx image.
	DmtxImage *dmtxImage = dmtxImageMalloc((int)width, (int)height);
	if(dmtxImage == NULL) {
		CGContextRelease(contextRef);
		free(memory);
		return NULL;
	}
	
	// Copy horizontally flipped image data.
	NSUInteger row, column, index;
	for(row = 0; row < height; row++) {
		for(column = 0; column < width; column++) {
			index = (height - row - 1) * width + column;
			dmtxImage->pxl[index][0] = data[row * width * 4 + column * 4 + 1];
			dmtxImage->pxl[index][1] = data[row * width * 4 + column * 4 + 2];
			dmtxImage->pxl[index][2] = data[row * width * 4 + column * 4 + 3];
//			NSLog(@"%i, %i: %i, %i, %i", row, column, (NSInteger)data[row * width * 4 + column * 4 + 1], (NSInteger)data[row * width * 4 + column * 4 + 2], (NSInteger)data[row * width * 4 + column * 4 + 3]);
		}
	}
	
	// Release bitmap context.
	CGContextRelease(contextRef);
	
	// Free context memory.
	free(memory);
	
	// Release CGImage.
	CGImageRelease(croppedImage);
	
	return dmtxImage;
	
}

@end
