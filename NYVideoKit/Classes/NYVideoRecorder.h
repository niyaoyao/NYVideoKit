//
//  NYVideoRecorder.h
//  lib-test-demo
//
//  Created by niyao  on 2019/3/18.
//  Copyright © 2019 niyao . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NYVideoRecorder : NSObject

@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

- (void)setPreviewLayerFrame:(CGRect)frame;
- (void)startCapture;
- (void)stopCapture;

@end

NS_ASSUME_NONNULL_END
