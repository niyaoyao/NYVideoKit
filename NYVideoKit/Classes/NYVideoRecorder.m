//
//  NYVideoRecorder.m
//  lib-test-demo
//
//  Created by niyao  on 2019/3/18.
//  Copyright © 2019 niyao . All rights reserved.
//

#import "NYVideoRecorder.h"
#import "NYVideoCapture.h"

@interface NYVideoRecorder () <NYVideoCaptureOutputSampleBufferDelegate>

@property (strong, nonatomic) AVAssetWriter *videoWriter;
@property (strong, nonatomic) AVAssetWriterInput *videoInput;
@property (strong, nonatomic) AVAssetWriterInput *audioInput;
@property (strong, nonatomic) NYVideoCapture *capture;

@end


@implementation NYVideoRecorder

- (void)setPreviewLayerFrame:(CGRect)frame {
    self.capture.previewLayerFrame = frame;
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return self.capture.captureVideoPreviewLayer;
}

- (void)startCapture {
    [self.capture start];
}

- (void)stopCapture {
    [self.capture stop];
}

- (NYVideoCapture *)capture {
    if (!_capture) {
        _capture = [[NYVideoCapture alloc] init];
        _capture.outputSampleBufferDelegate = self;
    }
    return _capture;
}

@end
