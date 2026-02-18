/*
Refer to LICENSE.txt for licensing details.

Summary:
Helper class for installing a macOS virtual machine.
*/

#ifndef HyfervisorInstaller_h  // Header guard start
#define HyfervisorInstaller_h  // Header guard definition

#import <Foundation/Foundation.h>  // Import Foundation framework

#ifdef __arm64__  // Compile only on Apple Silicon Macs

@interface HyfervisorInstaller : NSObject  // hyfervisor installer class declaration

- (void)setUpVirtualMachineArtifacts;  // Set up virtual machine artifacts

- (void)installMacOS:(NSURL *)ipswURL;  // Install macOS using an IPSW file URL

@end  // End of interface

#endif /* __arm64__ */  // Apple Silicon conditional compilation end
#endif /* HyfervisorInstaller_h */  // End header guard
