#import <Foundation/Foundation.h>

/// True when the given bundle is installed. Used so we never open ABA Mobile
/// for sandbox PayWay links that Simulator UAT also handles.
BOOL GoITCAppIsInstalled(NSString *_Nonnull bundleId);
