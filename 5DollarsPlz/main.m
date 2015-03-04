//
//  main.m
//  5DollarsPlz
//
//  Created by Chinmay Garde on 3/3/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

@import Foundation;

#import "FDCapture.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        FDCapture *capture = [[FDCapture alloc] init];
        
        [[NSRunLoop currentRunLoop] run];
        
        capture = nil;
    }
    return 0;
}
