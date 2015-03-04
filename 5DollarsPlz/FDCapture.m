//
//  FDCapture.m
//  5DollarsPlz
//
//  Created by Chinmay Garde on 3/3/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "FDCapture.h"
@import AVFoundation;
@import AppKit;

@interface FDCapture () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic, strong) NSOpenGLContext *context;
@property (nonatomic) NSUInteger imagesCaptured;

@end

@implementation FDCapture {
    NSUInteger _captureSuspended;
}

-(instancetype) init {
    self = [super init];
    
    if (self) {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        NSCAssert(devices.count > 0, @"There must be at least one camera");
        
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:devices.lastObject error:&error];
        
        NSCAssert(error == nil && input != nil, @"Must be able to create input device");
        
        _session = [[AVCaptureSession alloc] init];
        
        [_session addInput:input];
        
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        
        _stillImageOutput.outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG };
        
        NSAssert([_session canAddOutput:_stillImageOutput], @"Must be able to add the still image output");
        
        [_session addOutput:_stillImageOutput];
        
        AVCaptureVideoDataOutput *videoImageOutput = [[AVCaptureVideoDataOutput alloc] init];

        [videoImageOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        
        NSAssert([_session canAddOutput:videoImageOutput], @"Must be able to add the video image output");
        
        [_session addOutput:videoImageOutput];
        
        _session.sessionPreset = AVCaptureSessionPresetLow;
        
        [_session startRunning];
        
        const NSOpenGLPixelFormatAttribute attributes[] = { NSOpenGLPFADoubleBuffer, NSOpenGLPFAColorSize, 32, 0 };

        NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
        
        _context = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];

        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        
        CIContext *context = [CIContext contextWithCGLContext: _context.CGLContextObj
                                                  pixelFormat: pixelFormat.CGLPixelFormatObj
                                                   colorSpace: colorspace
                                                      options: @{}];
        
        CGColorSpaceRelease(colorspace);
        
        _faceDetector = [CIDetector detectorOfType: CIDetectorTypeFace
                                           context: context
                                           options: @{ CIDetectorAccuracy : CIDetectorAccuracyLow }];
    }
    
    return self;
}

-(void) suspendCapture {
    _captureSuspended = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _captureSuspended = NO;
    });
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (_captureSuspended) {
        return;
    }
    
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CIImage *image = [CIImage imageWithCVImageBuffer:buffer];
    
    NSArray *features = [_faceDetector featuresInImage:image];
    
    if (features.count == 0 || _captureSuspended) {
        return;
    }
    
    [self suspendCapture];
    
    _imagesCaptured ++;

    NSAssert(_stillImageOutput.connections.count != 0, @"Must be able to access the still image output connection");
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:_stillImageOutput.connections.firstObject completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if (error != nil) {
            return;
        }
        
        NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        
        [data writeToFile:[NSString stringWithFormat:@"Cap_%ld.jpg", _imagesCaptured] atomically:NO];

        NSLog(@"Captured %ld people. Earnings: $%g", _imagesCaptured, _imagesCaptured * 5.0);
    }];
}

@end
