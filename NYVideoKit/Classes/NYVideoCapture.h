//
//  NYAudioVideoCapture.h
//  NYVideoKit_Example
//
//  Created by niyao on 3/17/19.
//  Copyright © 2019 niyaoyao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol NYVideoCaptureOutputSampleBufferDelegate <NSObject>
@optional

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection isAudio:(BOOL)isAudio;

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection isAudio:(BOOL)isAudio;
@end
NS_ASSUME_NONNULL_BEGIN

@interface NYVideoCapture : NSObject

@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, assign) CGRect previewLayerFrame;
@property (nonatomic, assign, readonly) BOOL isLightOn;
@property (nonatomic, weak) id<NYVideoCaptureOutputSampleBufferDelegate> outputSampleBufferDelegate;

- (void)captureStillUIImage:(void (^)(UIImage * _Nullable image, NSError * _Nullable error))completionHandler;
- (void)start;
- (void)stop;
- (void)handleLight;

@end

NS_ASSUME_NONNULL_END
