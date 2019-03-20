//
//  NYAudioVideoCapture.m
//  NYVideoKit_Example
//
//  Created by niyao on 3/17/19.
//  Copyright © 2019 niyaoyao. All rights reserved.
//

#import "NYVideoCapture.h"
#import "NYVideoKitDefinition.h"

@interface NYVideoCapture () <AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) AVCaptureConnection *videoCaptureConnection;
@property (nonatomic, strong) AVCaptureConnection *audioCaptureConnection;
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;
@property (nonatomic, strong, readwrite) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, strong) AVCaptureDevice *backCamera;
@property (nonatomic, strong) AVCaptureDevice *microphone;
@property (nonatomic, assign, readwrite) BOOL isLightOn;

@end

@implementation NYVideoCapture {
    dispatch_queue_t _captureQueue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _captureQueue = dispatch_queue_create("nyvideokit.capture.data.output.queue", DISPATCH_QUEUE_SERIAL);
//        dispatch_set_target_queue(_captureQueue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    }
    return self;
}

- (void)dealloc {
    [self stop];
    NYVideoLog(@"========== Camera Dealloc =========");
}

- (AVCaptureVideoOrientation)videoOrientationFromCurrentDeviceOrientation {
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
            
            if (curOrientation == AVCaptureVideoOrientationLandscapeLeft) {
                theImage = [theImage imageByApplyingOrientation:3];
            } else if (curOrientation == AVCaptureVideoOrientationLandscapeRight) {
                theImage = [theImage imageByApplyingOrientation:1];
            } else if (curOrientation == AVCaptureVideoOrientationPortrait) {
                theImage = [theImage imageByApplyingOrientation:6];
            } else if (curOrientation == AVCaptureVideoOrientationPortraitUpsideDown) {
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
    BOOL isAudio = self.audioDataOutput == output;
    if ([self.outputSampleBufferDelegate respondsToSelector:@selector(captureOutput:didOutputSampleBuffer:fromConnection:isAudio:)]) {
        [self.outputSampleBufferDelegate captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection isAudio:isAudio];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NYVideoLog(@"didOutputSampleBuffer");
    BOOL isAudio = self.audioDataOutput == output;
    if ([self.outputSampleBufferDelegate respondsToSelector:@selector(captureOutput:didDropSampleBuffer:fromConnection:isAudio:)]) {
        [self.outputSampleBufferDelegate captureOutput:output didDropSampleBuffer:sampleBuffer fromConnection:connection isAudio:isAudio];
    }
}

#pragma mark - Public
- (void)start {
    if (!self.captureSession.isRunning) {
        [self.captureSession startRunning];
    }
}

- (void)stop {
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}

- (void)handleLight {
    if ([self.backCamera hasTorch]) {
        if (self.isLightOn) {
            [self.backCamera lockForConfiguration:nil];
            [self.backCamera setTorchMode: AVCaptureTorchModeOff];
            [self.backCamera unlockForConfiguration];
            
        } else {
            [self.backCamera lockForConfiguration:nil];
            [self.backCamera setTorchMode: AVCaptureTorchModeOn];
            [self.backCamera unlockForConfiguration];
            
        }
        self.isLightOn = !self.isLightOn;
    }
}

+ (AVCaptureDevice *)getCameraDevicePosition:(AVCaptureDevicePosition)position {
    if (@available(iOS 10.0, *)) {
        return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                  mediaType:AVMediaTypeVideo
                                                   position:position];
    } else {
        // Fallback on earlier versions
        NSArray <AVCaptureDevice *> *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if ([device position] == position) {
                return device;
            }
        }
        return nil;
    }
}

- (void)setPreviewLayerFrame:(CGRect)previewLayerFrame {
    _previewLayerFrame = previewLayerFrame;
    self.captureVideoPreviewLayer.bounds = _previewLayerFrame;
}

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        [_captureSession beginConfiguration];
        if ([_captureSession canAddInput:self.videoDeviceInput]) {
            [_captureSession addInput:self.videoDeviceInput];
        }

        if ([_captureSession canAddOutput:self.videoDataOutput]) {
            [_captureSession addOutput:self.videoDataOutput];
        }
        
        if ([_captureSession canAddInput:self.audioDeviceInput]) {
            [_captureSession addInput:self.audioDeviceInput];
        } else {
            NYVideoLog(@"Cannot add audio input");
        }
        
        if ([_captureSession canAddOutput:self.audioDataOutput]) {
            [_captureSession addOutput:self.audioDataOutput];
        } else {
            NYVideoLog(@"Cannot add audio output");
        }
        
        if ([_captureSession canAddOutput:self.imageOutput]) {
            [_captureSession addOutput:self.imageOutput];
        }
        
        [_captureSession commitConfiguration];
    }
    return _captureSession;
}

- (AVCaptureDevice *)backCamera {
    if (!_backCamera) {
        _backCamera = [NYVideoCapture getCameraDevicePosition:AVCaptureDevicePositionBack];
    }
    return _backCamera;
}

- (AVCaptureDevice *)microphone {
    if (!_microphone) {
        _microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    }
    return _microphone;
}

- (AVCaptureDeviceInput *)videoDeviceInput {
    if (!_videoDeviceInput) {
        NSError *error = nil;
        _videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.backCamera error:&error];
        NSParameterAssert(error == NULL);
    }
    return _videoDeviceInput;
}

- (AVCaptureDeviceInput *)audioDeviceInput {
    if (!_audioDeviceInput) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error = nil;
        _audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        NSParameterAssert(error == nil);
    }
    return _audioDeviceInput;
}

- (AVCaptureVideoDataOutput *)videoDataOutput {
    if (!_videoDataOutput) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoDataOutput setSampleBufferDelegate:self queue:_captureQueue];
        _videoDataOutput.videoSettings = @{
                                           (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) };
    }
    return _videoDataOutput;
}

- (AVCaptureAudioDataOutput *)audioDataOutput {
    if (!_audioDataOutput) {
        _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioDataOutput setSampleBufferDelegate:self queue:_captureQueue];
    }
    return _audioDataOutput;
}

- (AVCaptureConnection *)videoCaptureConnection {
    if (!_videoCaptureConnection) {
        _videoCaptureConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    }
    return _videoCaptureConnection;
}

- (AVCaptureConnection *)audioCaptureConnection {
    if (!_audioCaptureConnection) {
        _audioCaptureConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioCaptureConnection;
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
