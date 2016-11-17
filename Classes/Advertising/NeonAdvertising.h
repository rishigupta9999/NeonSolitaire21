//
//  NeonAdvertising.h
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#ifdef __cplusplus
extern "C"
{
#endif

@class NeonVungleDelegate;

#if ADVERTISING_DEBUG
    #define AdLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
    #define AdLog(...) do { } while (0)
#endif

#ifdef __cplusplus
}
#endif