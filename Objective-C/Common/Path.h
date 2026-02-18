/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A helper function to retrieve the various file URLs that this sample code uses.
*/

#ifndef Path_h
#define Path_h

#import <Foundation/Foundation.h>

static inline NSString *getVMBundlePath(NSString *vmBundlePath)
{
    NSString *path = vmBundlePath ?: [NSHomeDirectory() stringByAppendingPathComponent:@"VM.bundle"];
    // Expand ~ and remove any trailing slash inconsistencies.
    return [[path stringByExpandingTildeInPath] stringByStandardizingPath];
}

static inline NSURL *getVMBundleURL(NSString *vmBundlePath)
{
    return [[NSURL alloc] initFileURLWithPath:getVMBundlePath(vmBundlePath) isDirectory:YES];
}

static inline NSURL *getAuxiliaryStorageURL(NSString *vmBundlePath)
{
    return [getVMBundleURL(vmBundlePath) URLByAppendingPathComponent:@"AuxiliaryStorage"];
}

static inline NSURL *getDiskImageURL(NSString *vmBundlePath)
{
    return [getVMBundleURL(vmBundlePath) URLByAppendingPathComponent:@"Disk.img"];
}

static inline NSURL *getHardwareModelURL(NSString *vmBundlePath)
{
    return [getVMBundleURL(vmBundlePath) URLByAppendingPathComponent:@"HardwareModel"];
}

static inline NSURL *getMachineIdentifierURL(NSString *vmBundlePath)
{
    return [getVMBundleURL(vmBundlePath) URLByAppendingPathComponent:@"MachineIdentifier"];
}

static inline NSURL *getRestoreImageURL(NSString *vmBundlePath)
{
    return [getVMBundleURL(vmBundlePath) URLByAppendingPathComponent:@"RestoreImage.ipsw"];
}

static inline NSURL *getSaveFileURL(NSString *vmBundlePath)
{
    return [getVMBundleURL(vmBundlePath) URLByAppendingPathComponent:@"SaveFile.vzvmsave"];
}

#endif /* Path_h */
