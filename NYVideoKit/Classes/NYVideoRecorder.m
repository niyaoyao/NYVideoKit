//
//  NYVideoRecorder.m
//  lib-test-demo
//
//  Created by niyao  on 2019/3/18.
//  Copyright © 2019 niyao . All rights reserved.
//

#import "NYVideoRecorder.h"
#import "NYVideoCapture.h"
#import "NYVideoKitDefinition.h"

@interface NSFileManager (VideoFileSupport)

+ (BOOL)removeFileAtPath:(NSString *)path;

@end

@implementation NSFileManager (VideoFileSupport)

+ (BOOL)removeFileAtPath:(NSString *)path {
    BOOL success = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        NSParameterAssert(error == nil);
    }
    return success;
}

+ (NSURL *)temporaryDirectory {
    if (@available(iOS 10.0, *)) {
        return [[NSFileManager defaultManager] temporaryDirectory];
    } else {
        return [NSURL fileURLWithPath:NSTemporaryDirectory()];
    }
}

+ (NSURL *)documentDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
}

@end

@interface NSDate (VideoFileSupport)

@end

@implementation NSDate (VideoFileSupport)

+ (NSString *)date:(NSDate *)date toStringWithFormat:(NSString *)format {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = format;
    return [dateFormatter stringFromDate:date];
}

+ (NSString *)currentDateStringWithFormat:(NSString *)format {
    return [self date:[NSDate date] toStringWithFormat:format];
}

@end

@interface NYVideoRecorder () <NYVideoCaptureOutputSampleBufferDelegate>

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) NYVideoCapture *capture;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor;
@property (nonatomic, assign, readwrite) NYVideoRecorderStatus recorderStatus;

@end


@implementation NYVideoRecorder {
    CMFormatDescriptionRef _videoFormatDescription;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _recorderStatus = NYVideoRecorderStatusCreated;
        NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusCreated;");
        [self initFileRootPath];
    }
    return self;
}

- (void)dealloc {
    NYVideoLog(@"================= Bye~ ===================");
}

- (BOOL)initFileRootPath {
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    BOOL success = NO;
    if (![defaultManager fileExistsAtPath:[NYVideoRecorder rootDirectory].path]) {
        NSError *error = nil;
        success = [defaultManager createDirectoryAtPath:[NYVideoRecorder rootDirectory].path
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:&error];
        if (error != nil) {
            @throw error;
        }
        return success;
    } else {
        return YES;
    }
}

- (void)_setupAssetWriter {
    NSURL *outputURL = [self outputURL];
    NYVideoLog(@"outputURL: %@", outputURL);
    [NSFileManager removeFileAtPath:outputURL.path];
    NSError *error = nil;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:outputURL fileType:AVFileTypeMPEG4 error:&error];
    _recorderStatus = error == nil ? NYVideoRecorderStatusInitializedAssestWriter : NYVideoRecorderStatusError;
    NYVideoLog(@"_recorderStatus = %ld", (long)_recorderStatus);
    NSParameterAssert(error == nil);
    _assetWriter.shouldOptimizeForNetworkUse = YES;
    if ([_assetWriter canAddInput:_videoInput]) {
        [_assetWriter addInput:_videoInput];
        _recorderStatus = NYVideoRecorderStatusAddedVideoInput;
        NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusAddedVideoInput;");
    } else {
        _recorderStatus = NYVideoRecorderStatusCannotAddVideoInput;
        NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusCannotAddVideoInput;");
        NSParameterAssert(_assetWriter.error == nil);
    }
    
    if ([_assetWriter canAddInput:_audioInput]) {
        [_assetWriter addInput:_audioInput];
        _recorderStatus = NYVideoRecorderStatusAddedAudioInput;
        NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusAddedAudioInput;");
    } else {
        _recorderStatus = NYVideoRecorderStatusCannotAddAudioInput;
        NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusCannotAddAudioInput;");
        NSParameterAssert(_assetWriter.error == nil);
    }
}

- (void)_setupVideoWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    _videoFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(_videoFormatDescription);
    NSDictionary <NSString *, id> *settings = nil;
    if (@available(iOS 11.0, *)) {
        settings = @{
                     AVVideoCodecKey : AVVideoCodecTypeH264,
                     AVVideoWidthKey : @(dimensions.width),
                     AVVideoHeightKey: @(dimensions.height),
                     };
    } else {
        settings = @{
                     AVVideoCodecKey : AVVideoCodecH264,
                     AVVideoWidthKey : @(dimensions.width),
                     AVVideoHeightKey: @(dimensions.height),
                     };
    }
    NYVideoLog(@"settings: %@", settings);
    _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    _videoInput.expectsMediaDataInRealTime = YES;
    NSDictionary *pixelBufferAttributes = @{
                                            (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],
                                            (id)kCVPixelBufferWidthKey : [NSNumber numberWithInt:dimensions.width],
                                            (id)kCVPixelBufferHeightKey : [NSNumber numberWithInt:dimensions.height]
                                            };
    NYVideoLog(@"settings: %@", pixelBufferAttributes);
    _videoPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoInput
                                                                                                sourcePixelBufferAttributes:pixelBufferAttributes];
    _recorderStatus = NYVideoRecorderStatusInitializedVideoInput;
    NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusInitializedVideoInput;");
}

- (void)_setupAudioWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
    if (streamBasicDescription) {
        NSDictionary *settings = @{
                                   AVFormatIDKey: [NSNumber numberWithInt: kAudioFormatMPEG4AAC],
                                   AVSampleRateKey: @(streamBasicDescription->mSampleRate),
                                   AVEncoderBitRateKey: @(128000),
                                   AVNumberOfChannelsKey: @(streamBasicDescription->mChannelsPerFrame),
                                   };
        NYVideoLog(@"settings: %@", settings);
        _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                         outputSettings:settings
                                                       sourceFormatHint:formatDescription];
        _audioInput.expectsMediaDataInRealTime = YES;
        _recorderStatus = NYVideoRecorderStatusInitializedAudioInput;
        NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusInitializedAudioInput;");
    }
}

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (_audioInput.isReadyForMoreMediaData) {
        [_audioInput appendSampleBuffer:sampleBuffer];
        NYVideoLog(@"[_audioInput appendSampleBuffer:sampleBuffer];");
    }
}

- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (_videoInput.isReadyForMoreMediaData) {
        [_videoInput appendSampleBuffer:sampleBuffer];
        NYVideoLog(@"[_videoInput appendSampleBuffer:sampleBuffer];");
    }
}

- (void)_appendSampleBuffer:(CMSampleBufferRef)sampleBuffer isAudio:(BOOL)isAudio {
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        if (_assetWriter.status != AVAssetWriterStatusWriting) {
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            if ([_assetWriter startWriting]) {
                [_assetWriter startSessionAtSourceTime:startTime];
                NYVideoLog(@"startSessionAtSourceTime:");
                _recorderStatus = NYVideoRecorderStatusWriting;
                NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusWriting;");
            } else {
                if (_assetWriter.error) {
                    NYVideoLog(@"[Writer Error] %@", _assetWriter.error.localizedDescription);
                    _recorderStatus = NYVideoRecorderStatusError;
                    NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusError;");
                }
            }
            
            if (_assetWriter.status == AVAssetWriterStatusFailed) {
                _recorderStatus = NYVideoRecorderStatusFailed;
                NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusFailed;");
                NYVideoLog(@"[Writer Error] %@", _assetWriter.error.localizedDescription);
                return;
            }
            
        } else if (_assetWriter.status == AVAssetWriterStatusWriting) {
            if (isAudio) {
                [self appendAudioSampleBuffer:sampleBuffer];
            } else {
                [self appendVideoSampleBuffer:sampleBuffer];
            }
        }
    } else {
        NYVideoLog(@"CMSampleBufferDataIsReady(sampleBuffer): %d", CMSampleBufferDataIsReady(sampleBuffer));
    }
}

#pragma mark - NYVideoCaptureOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection isAudio:(BOOL)isAudio {
    
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection isAudio:(BOOL)isAudio {
    if (self.audioInput == nil && isAudio) {
        [self _setupAudioWithSampleBuffer:sampleBuffer];
    }
    
    if (self.videoInput == nil && !isAudio) {
        [self _setupVideoWithSampleBuffer:sampleBuffer];
    }
    
    if ( self.recorderStatus == NYVideoRecorderStatusStartToWrite || self.recorderStatus == NYVideoRecorderStatusWriting) {
        [self _appendSampleBuffer:sampleBuffer isAudio:isAudio];
    }
}

#pragma mark - Public
+ (NSURL *)rootDirectory {
    NSURL *root = [[NSFileManager documentDirectory] URLByAppendingPathComponent:@"ny.video.kit"];
    NYVideoLog(@"root.absoluteString: %@, root.path:%@", root.absoluteString, root.path);
    return root;
}

- (NSURL *)outputURL {
    return [[NYVideoRecorder rootDirectory] URLByAppendingPathComponent:[self.fileName stringByAppendingString:@".mp4"]];
}

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

- (void)startRecording {
    [self _setupAssetWriter];
    _recorderStatus = NYVideoRecorderStatusStartToWrite;
    NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusStartToWrite;");
}

- (void)stopRecording:(void (^)(NSError * _Nullable error))handler {
    if (self.recorderStatus != NYVideoRecorderStatusFailed && self.recorderStatus != NYVideoRecorderStatusError) {
        _recorderStatus = NYVideoRecorderStatusStopRecording;
        NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusStopRecording;");
        if (_assetWriter.status == AVAssetWriterStatusWriting) {
            __weak typeof (self) weakSelf = self;
            [_assetWriter finishWritingWithCompletionHandler:^{
                weakSelf.recorderStatus = NYVideoRecorderStatusFinishWriting;
                weakSelf.assetWriter = nil;
                NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusFinishWriting;");
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(handler) {
                        handler(nil);
                    }
                });
            }];
        }
    } else {
        if (handler) {
            handler(_assetWriter.error);
            _recorderStatus = NYVideoRecorderStatusError;
            NYVideoLog(@"_recorderStatus = NYVideoRecorderStatusError;");
        }
    }
}

- (NYVideoCapture *)capture {
    if (!_capture) {
        _capture = [[NYVideoCapture alloc] init];
        _capture.outputSampleBufferDelegate = self;
    }
    return _capture;
}

- (NSString *)fileName {
    if (!_fileName) {
        _fileName = [NSDate currentDateStringWithFormat:@"yyyy_MM_dd_hh_mm_ss"];
    }
    return _fileName;
}

@end
