//
//  NYViewController.m
//  NYVideoKit
//
//  Created by niyaoyao on 03/17/2019.
//  Copyright (c) 2019 niyaoyao. All rights reserved.
//

#import "NYViewController.h"

#import <NYVideoRecorder.h>
#import <NYVideoKitDefinition.h>

@interface NYViewController ()

@property (nonatomic, strong) UIButton *reloadButton;
@property (nonatomic, strong) NYVideoRecorder *recorder;

@end

@implementation NYViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view.layer addSublayer:self.recorder.videoPreviewLayer];
    [self.view addSubview:self.reloadButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.recorder startCapture];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.recorder stopCapture];
}

- (NYVideoRecorder *)recorder {
    if (!_recorder) {
        _recorder = [[NYVideoRecorder alloc] init];
        [_recorder setPreviewLayerFrame:self.view.frame];
    }
    return _recorder;
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc]init];
        configuration.allowsInlineMediaPlayback = YES;
        configuration.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
        _webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
        _webView.navigationDelegate = self;
        _webView.scrollView.delegate = self;
        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            
        }
        [self.view addSubview:_webView];
    }
    return _webView;
}

- (UIButton *)reloadButton {
    if (!_reloadButton) {
        _reloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _reloadButton.frame = CGRectMake(self.view.frame.size.width - 100, self.view.frame.size.height - 50, 100, 30);
        [_reloadButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        [_reloadButton setTitle:@"⏺️" forState:UIControlStateNormal];
        [_reloadButton addTarget:self action:@selector(startRecord) forControlEvents:UIControlEventTouchUpInside];
    }
    return _reloadButton;
}

- (void)startRecord {
    if(self.recorder.recorderStatus != NYVideoRecorderStatusWriting) {
        [self.recorder startRecording];
        [self.reloadButton setTitle:@"⏸️" forState:UIControlStateNormal];
    } else {
        __weak typeof (self) weakSelf = self;
        [self.recorder stopRecording:^(NSError * _Nullable error) {
            if (error) {
                [self showMessage:error.localizedDescription];
            }
            [weakSelf.reloadButton setTitle:@"⏺️" forState:UIControlStateNormal];
        }];
    }
}


@end
