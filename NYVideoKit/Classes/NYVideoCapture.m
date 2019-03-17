//
//  NYAudioVideoCapture.m
//  NYVideoKit_Example
//
//  Created by niyao on 3/17/19.
//  Copyright © 2019 niyaoyao. All rights reserved.
//

#import "NYVideoCapture.h"

@interface NYVideoCapture () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;
@property (nonatomic, strong, readwrite) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, assign, readwrite) BOOL isLightOn;

@end

@implementation NYVideoCapture {
    dispatch_queue_t _sampleQueue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sampleQueue = dispatch_queue_create("io.camera.capture.sample.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_sampleQueue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    }
    return self;
}

- (void)dealloc {
    [self.captureSession stopRunning];
    
#if DEBUG
    NSLog(@"========== Camera Dealloc =========");
#endif
    
}

- (AVCaptureVideoOrientation) videoOrientationFromCurrentDeviceOrientation {
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationPortrait: {
            return AVCaptureVideoOrientationPortrait;
        }
        case UIInterfaceOrientationLandscapeLeft: {
            return AVCaptureVideoOrientationLandscapeLeft;
        }
        case UIInterfaceOrientationLandscapeRight: {
            return AVCaptureVideoOrientationLandscapeRight;
        }
        case UIInterfaceOrientationPortraitUpsideDown: {
            return AVCaptureVideoOrientationPortraitUpsideDown;
        }
        case UIInterfaceOrientationUnknown: {
            return AVCaptureVideoOrientationPortrait;
            break;
        }
    }
    return AVCaptureVideoOrientationPortrait;
}

- (void)captureStillCMSampleBuffer:(void (^)(CMSampleBufferRef sampleBuffer, NSError *error))completionHandler {
    AVCaptureConnection *videoConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:self.captureVideoPreviewLayer.connection.videoOrientation];
    }
    
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (completionHandler) {
            completionHandler(imageDataSampleBuffer, error);
        }
    }];
}

- (void)captureStillCVImageBuffer:(void (^)(CVImageBufferRef imageBuffer, NSError *error))completionHandler {
    
    [self captureStillCMSampleBuffer:^(CMSampleBufferRef sampleBuffer, NSError *error) {
        CVImageBufferRef theImageBuffer = NULL;
        if (sampleBuffer != NULL) {
            theImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        }
        
        if (completionHandler) {
            completionHandler(theImageBuffer, error);
        }
    }];
}

- (void)captureStillCIImage:(void (^)(CIImage *image, NSError *error))completionHandler {
    
    [self captureStillCVImageBuffer:^(CVImageBufferRef imageBuffer, NSError *error) {
        CIImage *theImage = NULL;
        if (imageBuffer != NULL) {
            
            theImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
            UIInterfaceOrientation curOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            
            if (curOrientation == AVCaptureVideoOrientationLandscapeLeft){
                theImage = [theImage imageByApplyingOrientation:3];
            } else if (curOrientation == AVCaptureVideoOrientationLandscapeRight){
                theImage = [theImage imageByApplyingOrientation:1];
            } else if (curOrientation == AVCaptureVideoOrientationPortrait){
                theImage = [theImage imageByApplyingOrientation:6];
            } else if (curOrientation == AVCaptureVideoOrientationPortraitUpsideDown){
                theImage = [theImage imageByApplyingOrientation:8];
            }
        }
        
        if (completionHandler) {
            completionHandler(theImage, error);
        }
    }];
}

- (void)captureStillCGImage:(void (^)(CGImageRef image, NSError *error))completionHandler {
    
    [self captureStillCIImage:^(CIImage *image, NSError *error) {
        
        CGImageRef theCGImage = NULL;
        if (image != NULL) {
            NSDictionary *theOptions = @{
                                         // TODO
                                         };
            CIContext *theCIContext = [CIContext contextWithOptions:theOptions];
            theCGImage = [theCIContext createCGImage:image fromRect:image.extent];
        }
        
        if (completionHandler) {
            completionHandler(theCGImage, error);
        }
        
        
        CGImageRelease(theCGImage);
    }];
}

- (void)captureStillUIImage:(void (^)(UIImage *image, NSError *error))completionHandler {
    
    [self captureStillCGImage:^(CGImageRef image, NSError *error) {
        UIImage *theUIImage = NULL;
        if (image != NULL) {
            theUIImage = [UIImage imageWithCGImage:image];
        }
        
        if (completionHandler) {
            completionHandler(theUIImage, error);
        }
    }];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
#if DEBUG
    //    NSLog(@"didOutputSampleBuffer: %@", sampleBuffer);
#endif
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
#if DEBUG
    //    NSLog(@"didOutputSampleBuffer: %@", sampleBuffer);
#endif
}

#pragma mark - Public
- (void)start {
    [self.captureSession startRunning];
}

- (void)stop {
    [self.captureSession stopRunning];
}

- (void)handleLight {
    if ([self.device hasTorch]) {
        if (self.isLightOn) {
            [self.device lockForConfiguration:nil];
            [self.device setTorchMode: AVCaptureTorchModeOff];
            [self.device unlockForConfiguration];
            
        } else {
            [self.device lockForConfiguration:nil];
            [self.device setTorchMode: AVCaptureTorchModeOn];
            [self.device unlockForConfiguration];
            
        }
        self.isLightOn = !self.isLightOn;
    }
}

+ (AVCaptureDevice *)getCameraDevicePosition:(AVCaptureDevicePosition)position {
    return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                              mediaType:AVMediaTypeVideo
                                               position:position];
}

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        [_captureSession beginConfiguration];
        if ([_captureSession canAddInput:self.captureDeviceInput]) {
            [_captureSession addInput:self.captureDeviceInput];
        }
        if ([_captureSession canAddOutput:self.captureVideoDataOutput]) {
            [_captureSession addOutput:self.captureVideoDataOutput];
        }
        
        if ([_captureSession canAddOutput:self.imageOutput]) {
            [_captureSession addOutput:self.imageOutput];
        }
        
        [_captureSession commitConfiguration];
    }
    return _captureSession;
}

- (AVCaptureDevice *)device {
    if (!_device) {
        _device = [NYVideoCapture getCameraDevicePosition:AVCaptureDevicePositionBack];
    }
    return _device;
}

- (AVCaptureDeviceInput *)captureDeviceInput {
    if (!_captureDeviceInput) {
        
        NSError *error = nil;
        _captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
        
        NSParameterAssert(error == NULL);
    }
    return _captureDeviceInput;
}

- (AVCaptureVideoDataOutput *)captureVideoDataOutput {
    if (!_captureVideoDataOutput) {
        _captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_captureVideoDataOutput setSampleBufferDelegate:self queue:_sampleQueue];
        _captureVideoDataOutput.videoSettings = @{
                                                  (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
                                                  };
    }
    return _captureVideoDataOutput;
}

- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
    if (!_captureVideoPreviewLayer) {
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _captureVideoPreviewLayer.connection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
    }
    return _captureVideoPreviewLayer;
}

- (AVCaptureStillImageOutput *)imageOutput {
    if (!_imageOutput) {
        _imageOutput = [[AVCaptureStillImageOutput alloc] init];
        _imageOutput.outputSettings = @{
                                        (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                        };
        
    }
    return _imageOutput;
}

@end
