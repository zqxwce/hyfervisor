/*
Refer to LICENSE.txt for licensing details.

Summary:
Entry point for the macOS virtual machine installer tool.
*/

#import "Error.h"  // Error handling helpers
#import "HyfervisorInstaller.h"  // hyfervisor installer class
#import "Path.h"  // Path helper functions

#import <Foundation/Foundation.h>  // Foundation framework

static NSString *InstallerConfigFilePath(void)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupportDir = [paths firstObject];
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] ?: @"hyfervisor";
    NSString *configDir = [appSupportDir stringByAppendingPathComponent:appName];
    return [configDir stringByAppendingPathComponent:@"hyfervisor_config.plist"];
}

int main(int argc, const char * argv[])
{
#ifdef __arm64__  // Runs only on Apple Silicon Macs
    @autoreleasepool {  // Autorelease pool
        if (argc >= 2) {  // IPSW file path provided
            NSString *ipswPath = [NSString stringWithUTF8String:argv[1]];  // Convert first argument to NSString
            NSString *vmBundlePath = (argc >= 3) ? [NSString stringWithUTF8String:argv[2]] : [NSHomeDirectory() stringByAppendingPathComponent:@"VM.bundle"];

            // Persist the chosen bundle path so the app uses the same location.
            NSString *configPath = InstallerConfigFilePath();
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *configDir = [configPath stringByDeletingLastPathComponent];
            if (![fileManager fileExistsAtPath:configDir]) {
                [fileManager createDirectoryAtPath:configDir withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSMutableDictionary *config = [NSMutableDictionary dictionaryWithContentsOfFile:configPath] ?: [NSMutableDictionary dictionary];
            config[@"vmBundlePath"] = getVMBundlePath(vmBundlePath);
            [config writeToFile:configPath atomically:YES];

            HyfervisorInstaller *installer = [[HyfervisorInstaller alloc] initWithVMBundlePath:vmBundlePath];  // Create installer instance with bundle path

            NSURL *ipswURL = [[NSURL alloc] initFileURLWithPath:ipswPath];  // Build file URL
            if (!ipswURL.isFileURL) {  // Validate file URL
                abortWithErrorMessage(@"The provided IPSW path is not a valid file URL.");  // Exit with error
            }

            [installer setUpVirtualMachineArtifacts];  // Prepare VM artifacts
            [installer installMacOS:ipswURL];  // Start macOS installation

            dispatch_main();  // Run the main dispatch queue
        } else {  // Invalid arguments
            NSLog(@"Invalid arguments. Please provide the path to the IPSW file.");  // Error message
            NSLog(@"Usage: %s <IPSW file path> [vm bundle path]", argv[0]);  // Usage hint
            exit(-1);  // Exit
        }
    }
#else
    NSLog(@"This tool can only run on Apple Silicon Macs.");  // Error message
    exit(-1);  // Exit
#endif
}
