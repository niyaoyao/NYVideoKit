//
//  NYVideoKitDefinition.h
//  NYVideoKit
//
//  Created by niyao on 3/17/19.
//  Copyright © 2019 niyaoyao. All rights reserved.
//

#ifndef NYVideoKitDefinition_h
#define NYVideoKitDefinition_h

#ifdef DEBUG
#define NYVideoLog(...) NSLog(@"%s\n\n%@\n\n==================================================\n", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__]);
#else
#define NYVideoLog(...)
#endif

#endif /* NYVideoKitDefinition_h */
