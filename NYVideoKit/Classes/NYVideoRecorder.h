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

typedef NS_ENUM(NSInteger, NYVideoRecorderStatus) {
    NYVideoRecorderStatusError = -1,
    NYVideoRecorderStatusCreated,
    NYVideoRecorderStatusInitializedVideoInput,
    NYVideoRecorderStatusInitializedAudioInput,
    NYVideoRecorderStatusCannotAddVideoInput,
    NYVideoRecorderStatusAddedVideoInput,
    NYVideoRecorderStatusCannotAddAudioInput,
    NYVideoRecorderStatusAddedAudioInput,
    NYVideoRecorderStatusStartToWrite,
    NYVideoRecorderStatusInitializedAssestWriter,
    NYVideoRecorderStatusWriting,
    NYVideoRecorderStatusStopRecording,
    NYVideoRecorderStatusFinishWriting,
    NYVideoRecorderStatusFailed = NYVideoRecorderStatusError,
};

@interface NYVideoRecorder : NSObject

@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, assign, readonly) NYVideoRecorderStatus recorderStatus;
@property (nonatomic, copy) NSString *fileName;

+ (NSURL *)rootDirectory;
- (NSURL *)outputURL;
- (void)setPreviewLayerFrame:(CGRect)frame;
- (void)startCapture;
- (void)stopCapture;
- (void)startRecording;
- (void)stopRecording:(void (^)(NSError * _Nullable error))handler;

@end

NS_ASSUME_NONNULL_END
