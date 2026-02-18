/*
Refer to LICENSE.txt for licensing details.

Summary:
Entry point for the macOS virtual machine installer tool.
*/

#import "Error.h"  // Error handling helpers
#import "HyfervisorInstaller.h"  // hyfervisor installer class
#import "Path.h"  // Path helper functions

#import <Foundation/Foundation.h>  // Foundation framework

int main(int argc, const char * argv[])
{
#ifdef __arm64__  // Runs only on Apple Silicon Macs
    @autoreleasepool {  // Autorelease pool
        HyfervisorInstaller *installer = [HyfervisorInstaller new];  // Create installer instance

        if (argc == 2) {  // IPSW file path provided
            NSString *ipswPath = [NSString stringWithUTF8String:argv[1]];  // Convert first argument to NSString

            NSURL *ipswURL = [[NSURL alloc] initFileURLWithPath:ipswPath];  // Build file URL
            if (!ipswURL.isFileURL) {  // Validate file URL
                abortWithErrorMessage(@"The provided IPSW path is not a valid file URL.");  // Exit with error
            }

            [installer setUpVirtualMachineArtifacts];  // Prepare VM artifacts
            [installer installMacOS:ipswURL];  // Start macOS installation

            dispatch_main();  // Run the main dispatch queue
        } else {  // Invalid arguments
            NSLog(@"Invalid arguments. Please provide the path to the IPSW file.");  // Error message
            NSLog(@"Usage: %s <IPSW file path>", argv[0]);  // Usage hint
            exit(-1);  // Exit
        }
    }
#else
    NSLog(@"This tool can only run on Apple Silicon Macs.");  // Error message
    exit(-1);  // Exit
#endif
}
