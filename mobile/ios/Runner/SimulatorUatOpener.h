#import <Foundation/Foundation.h>

/// Opens an already-installed app by bundle id and hands it a URL.
/// Used so sandbox ABA PAY can target Simulator UAT instead of live ABA Mobile,
/// which both claim the same `abaMobileBank` URL scheme.
BOOL GoITCOpenInstalledApp(NSString *_Nonnull bundleId, NSURL *_Nonnull url);
