//
//  NYAudioVideoCapture.h
//  NYVideoKit_Example
//
//  Created by niyao on 3/17/19.
//  Copyright © 2019 niyaoyao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NYVideoCapture : NSObject

@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, assign, readonly) BOOL isLightOn;

- (void)captureStillUIImage:(void (^)(UIImage *image, NSError *error))completionHandler;
- (void)start;
- (void)stop;
- (void)handleLight;

@end

NS_ASSUME_NONNULL_END
