#import "MigrateLocalStorage.h"

@implementation MigrateLocalStorage

- (BOOL) copyFrom:(NSString*)src to:(NSString*)dest
{
    NSFileManager* fileManager = [NSFileManager defaultManager];

    // Bail out if source file does not exist
    if (![fileManager fileExistsAtPath:src]) {
        return NO;
    }

    // Bail out if dest file exists
    if ([fileManager fileExistsAtPath:dest]) {
        return NO;
    }

    // create path to dest
    if (![fileManager createDirectoryAtPath:[dest stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil]) {
        return NO;
    }

    // copy src to dest
    return [fileManager copyItemAtPath:src toPath:dest error:nil];
}

- (void) migrateLocalStorage
{
    // Migrate UIWebView local storage files to WKWebView. Adapted from
    // https://github.com/Telerik-Verified-Plugins/WKWebView/blob/master/src/ios/MyMainViewController.m

    NSString* appLibraryFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* original;

    if ([[NSFileManager defaultManager] fileExistsAtPath:[appLibraryFolder stringByAppendingPathComponent:@"WebKit/LocalStorage/file__0.localstorage"]]) {
        original = [appLibraryFolder stringByAppendingPathComponent:@"WebKit/LocalStorage"];
    } else {
        original = [appLibraryFolder stringByAppendingPathComponent:@"Caches"];
    }

    original = [original stringByAppendingPathComponent:@"file__0.localstorage"];
    NSLog(@"original path is %@", original);

    NSString* target = [[NSString alloc] initWithString: [appLibraryFolder stringByAppendingPathComponent:@"WebKit"]];

#if TARGET_IPHONE_SIMULATOR
    // the simulutor squeezes the bundle id into the path
    NSString* bundleIdentifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    target = [target stringByAppendingPathComponent:bundleIdentifier];
    NSLog(@"original target is %@", target);
#endif

    target = [target stringByAppendingPathComponent:@"WebsiteData/LocalStorage/ionic_pace_0.localstorage"];
    NSLog(@"modified target is %@", target);

    // Only copy data if no existing localstorage data exists yet for wkwebview
    if (![[NSFileManager defaultManager] fileExistsAtPath:target]) {
        NSLog(@"No existing localstorage data found for WKWebView. Migrating data from UIWebView");
        [self copyFrom:original to:target];
        [self copyFrom:[original stringByAppendingString:@"-shm"] to:[target stringByAppendingString:@"-shm"]];
        [self copyFrom:[original stringByAppendingString:@"-wal"] to:[target stringByAppendingString:@"-wal"]];
    }
    
    // for using hostname in config.xml, local storage path changed
    NSString* target2 = [appLibraryFolder stringByAppendingPathComponent:@"WebsiteData/LocalStorage/ionic_pace.topo.cc_0.localstorage"];
    NSLog(@"modified target2 is %@", target2);
    // Only copy data if no existing localstorage data exists yet for hostname
    if (![[NSFileManager defaultManager] fileExistsAtPath:target2]) {
        NSLog(@"No existing localstorage data found for hostname. Migrating data from normal wkwebview");
        [self copyFrom:target to:target2];
        [self copyFrom:[target stringByAppendingString:@"-shm"] to:[target2 stringByAppendingString:@"-shm"]];
        [self copyFrom:[target stringByAppendingString:@"-wal"] to:[target2 stringByAppendingString:@"-wal"]];
    }
}

- (void)pluginInitialize
{
    [self migrateLocalStorage];
}


@end
