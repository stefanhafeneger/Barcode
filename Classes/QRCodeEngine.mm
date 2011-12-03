//
//  QRCodeEngine.m
//  Barcode
//
//  Created by Stefan Hafeneger on 28.05.08.
//  Copyright 2008 CocoaHeads Aachen. All rights reserved.
//

#import "QRCodeEngine.h"

#include "QRCodeReader.h"
#include "GrayBytesMonochromeBitmapSource.h"
#include "ReaderException.h"
#include "IllegalArgumentException.h"

using namespace qrcode;

@implementation QRCodeEngine

#pragma mark Private

- (void)encode:(NSDictionary *)dictionary {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[self performSelectorOnMainThread:@selector(didNotEncode:) withObject:dictionary waitUntilDone:NO];
	
	[pool release];
	
}

- (void)decode:(NSDictionary *)dictionary {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	UIImage *image = (UIImage *)[dictionary objectForKey:@"image"];
	
	NSString *string = nil;
	
	// Create gray image.
	CGImageRef grayImage = [self grayImageFromImage:image withRect:(CGRect)[(NSValue *)[dictionary objectForKey:@"rect"] CGRectValue]];
	if(grayImage == NULL) {
		if(!self.cancel)
			[self performSelectorOnMainThread:@selector(didNotDecode:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:image, @"image", nil] waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(didStopOperation) withObject:nil waitUntilDone:NO];
		[pool release];
		return;
	}
	
	if(self.cancel) {
		CGImageRelease(grayImage);
		[self performSelectorOnMainThread:@selector(didStopOperation) withObject:nil waitUntilDone:NO];
		[pool release];
		return;
	}
	
	// Get gray image data.
	NSData *dataProvider = (NSData *)CGDataProviderCopyData(CGImageGetDataProvider(grayImage));
	if(dataProvider == nil) {
		CGImageRelease(grayImage);
		if(!self.cancel)
			[self performSelectorOnMainThread:@selector(didNotDecode:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:image, @"image", nil] waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(didStopOperation) withObject:nil waitUntilDone:NO];
		[pool release];
		return;
	}
	
	// Create zxing image.
	Ref<MonochromeBitmapSource> zxingImage(new GrayBytesMonochromeBitmapSource((const unsigned char *)[dataProvider bytes], CGImageGetWidth(grayImage), CGImageGetHeight(grayImage), CGImageGetBytesPerRow(grayImage)));
	
	// Release gray image.
	CGImageRelease(grayImage);
	
	QRCodeReader reader;
	
	for(NSInteger i = 0; i < 4; i++) {
		
		if(self.cancel)
			break;
		
		try {
			
			// Decode zxing image.
			Ref<Result> zxingResult(reader.decode(zxingImage));
			
			// Since there is no exception we got a result.
			Ref<String> zxingString(zxingResult->getText());
			string = [NSString stringWithUTF8String:(const char *)zxingString->getText().c_str()];
			
		} catch(ReaderException *exception) {
//			NSLog(@"Error: failed to decode, caught ReaderException '%s'.", exception->what());
			delete exception;
		} catch(IllegalArgumentException *exception) {
//			NSLog(@"Error: failed to decode, caught IllegalArgumentException '%s'.", exception->what());
			delete exception;
		} catch(...) {
//			NSLog(@"Error: caught unknown exception!");
		}
		
		if(string != nil)
			break;
		
		// Rotate zxing image.
		zxingImage = zxingImage->rotateCounterClockwise();
		
	}
	
	// Release gray image data.
	CFRelease((CFDataRef)dataProvider);
	
	if(string != nil) {
		if(!self.cancel)
			[self performSelectorOnMainThread:@selector(didDecode:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:image, @"image", string, @"string", nil] waitUntilDone:NO];
	} else {
		if(!self.cancel)
			[self performSelectorOnMainThread:@selector(didNotDecode:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:image, @"image", nil] waitUntilDone:NO];
	}
	
	[self performSelectorOnMainThread:@selector(didStopOperation) withObject:nil waitUntilDone:NO];
	
	[pool release];
	
}

@end
