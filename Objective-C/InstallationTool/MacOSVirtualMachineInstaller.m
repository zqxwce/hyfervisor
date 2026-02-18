/*
Refer to LICENSE.txt for licensing details.

Summary:
Helper class for installing a macOS virtual machine.
*/

#ifdef __arm64__  // Compile only on Apple Silicon Macs

#import "HyfervisorInstaller.h"  // Header import

#import "Error.h"  // Error handling helpers
#import "HyfervisorConfigurationHelper.h"  // hyfervisor configuration helpers
#import "HyfervisorDelegate.h"  // hyfervisor delegate
#import "Path.h"  // Path helper functions

#import <Foundation/Foundation.h>  // Foundation framework
#import <sys/stat.h>  // System status header
#import <Virtualization/Virtualization.h>  // Virtualization framework

@implementation HyfervisorInstaller {  // hyfervisor installer implementation
    VZVirtualMachine *_virtualMachine;  // Virtual machine instance
    HyfervisorDelegate *_delegate;  // hyfervisor delegate
}

// MARK: - Internal helper methods

// Create the bundle used to store artifacts produced during installation.
static void createVMBundle(void)
{
    NSError *error;
    BOOL bundleCreateResult = [[NSFileManager defaultManager] createDirectoryAtURL:getVMBundleURL()
                                                       withIntermediateDirectories:NO
                                                                        attributes:nil
                                                                             error:&error];
    if (!bundleCreateResult) {
        abortWithErrorMessage([error description]);
    }
}

// The Virtualization framework supports two disk image formats:
// * RAW disk image: a 1:1 mapping between file offsets and VM disk offsets.
//   Logical size matches the disk size.
//   On APFS volumes, sparse-file support keeps the physical size small.
//
// * ASIF disk image: a sparse format that transfers efficiently between hosts
//   without depending on host filesystem sparsity features.
//   ASIF is supported starting in macOS 16.
static void createASIFDiskImage(void)
{
    NSError *error = nil;
    NSTask *task = [NSTask launchedTaskWithExecutableURL:[NSURL fileURLWithPath:@"/usr/sbin/diskutil"]
                                               arguments:@[@"image", @"create", @"blank", @"--fs", @"none", @"--format", @"ASIF", @"--size", @"128GiB", getDiskImageURL().path]
                                                   error:&error
                                      terminationHandler:nil];

    if (error != nil) {
        abortWithErrorMessage([NSString stringWithFormat:@"Failed to run diskutil: %@", error]);
    }

    [task waitUntilExit];
    if (task.terminationStatus != 0) {
        abortWithErrorMessage(@"Failed to create disk image.");
    }
}

static void createRAWDiskImage(void)
{
    int fd = open([getDiskImageURL() fileSystemRepresentation], O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
    if (fd == -1) {
        abortWithErrorMessage(@"Could not create disk image.");
    }

    // 128 GB disk space
    int result = ftruncate(fd, 128ull * 1024ull * 1024ull * 1024ull);
    if (result) {
        abortWithErrorMessage(@"ftruncate() failed.");
    }

    result = close(fd);
    if (result) {
        abortWithErrorMessage(@"Failed to close disk image.");
    }
}

static void createDiskImage(void)
{
    if (@available(macOS 16.0, *)) {
        createASIFDiskImage();
    } else {
        createRAWDiskImage();
    }
}

// MARK: Create Mac platform configuration

- (VZMacPlatformConfiguration *)createMacPlatformConfiguration:(VZMacOSConfigurationRequirements *)macOSConfiguration
{
    VZMacPlatformConfiguration *macPlatformConfiguration = [[VZMacPlatformConfiguration alloc] init];

    NSError *error;
    VZMacAuxiliaryStorage *auxiliaryStorage = [[VZMacAuxiliaryStorage alloc] initCreatingStorageAtURL:getAuxiliaryStorageURL()
                                                                                        hardwareModel:macOSConfiguration.hardwareModel
                                                                                              options:VZMacAuxiliaryStorageInitializationOptionAllowOverwrite
                                                                                                error:&error];
    if (!auxiliaryStorage) {
        abortWithErrorMessage([NSString stringWithFormat:@"Failed to create auxiliary storage. %@", error.localizedDescription]);
    }

    macPlatformConfiguration.hardwareModel = macOSConfiguration.hardwareModel;
    macPlatformConfiguration.auxiliaryStorage = auxiliaryStorage;
    macPlatformConfiguration.machineIdentifier = [[VZMacMachineIdentifier alloc] init];

    // Persist the hardware model and machine identifier so they can be reused on subsequent boots.
    [macPlatformConfiguration.hardwareModel.dataRepresentation writeToURL:getHardwareModelURL() atomically:YES];
    [macPlatformConfiguration.machineIdentifier.dataRepresentation writeToURL:getMachineIdentifierURL() atomically:YES];

    return macPlatformConfiguration;
}

// MARK: Create VM configuration and instantiate the VM

- (void)setupVirtualMachineWithMacOSConfigurationRequirements:(VZMacOSConfigurationRequirements *)macOSConfiguration
{
    VZVirtualMachineConfiguration *configuration = [VZVirtualMachineConfiguration new];

    configuration.platform = [self createMacPlatformConfiguration:macOSConfiguration];
    assert(configuration.platform);

    configuration.CPUCount = [HyfervisorConfigurationHelper computeCPUCount];
    if (configuration.CPUCount < macOSConfiguration.minimumSupportedCPUCount) {
        abortWithErrorMessage(@"CPU count is not supported by the macOS configuration.");
    }

    configuration.memorySize = [HyfervisorConfigurationHelper computeMemorySize];
    if (configuration.memorySize < macOSConfiguration.minimumSupportedMemorySize) {
        abortWithErrorMessage(@"Memory size is not supported by the macOS configuration.");
    }

    // Create 128 GB disk image
    createDiskImage();

    configuration.bootLoader = [HyfervisorConfigurationHelper createBootLoader];

    configuration.audioDevices = @[ [HyfervisorConfigurationHelper createSoundDeviceConfiguration] ];
    configuration.graphicsDevices = @[ [HyfervisorConfigurationHelper createGraphicsDeviceConfiguration] ];
    configuration.networkDevices = @[ [HyfervisorConfigurationHelper createNetworkDeviceConfiguration] ];
    configuration.storageDevices = @[ [HyfervisorConfigurationHelper createBlockDeviceConfiguration] ];

    configuration.pointingDevices = @[ [HyfervisorConfigurationHelper createPointingDeviceConfiguration] ];
    configuration.keyboards = @[ [HyfervisorConfigurationHelper createKeyboardConfiguration] ];
    
    BOOL isValidConfiguration = [configuration validateWithError:nil];
    if (!isValidConfiguration) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Invalid configuration" userInfo:nil];
    }
    
    if (@available(macOS 14.0, *)) {
        BOOL supportsSaveRestore = [configuration validateSaveRestoreSupportWithError:nil];
        if (!supportsSaveRestore) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Invalid configuration" userInfo:nil];
        }
    }

    self->_virtualMachine = [[VZVirtualMachine alloc] initWithConfiguration:configuration];
    self->_delegate = [HyfervisorDelegate new];
    self->_virtualMachine.delegate = self->_delegate;
}

- (void)startInstallationWithRestoreImageFileURL:(NSURL *)restoreImageFileURL
{
    VZMacOSInstaller *installer = [[VZMacOSInstaller alloc] initWithVirtualMachine:self->_virtualMachine restoreImageURL:restoreImageFileURL];

    NSLog(@"Starting installation.");
    [installer installWithCompletionHandler:^(NSError *error) {
        if (error) {
            abortWithErrorMessage([NSString stringWithFormat:@"%@", error.localizedDescription]);
        } else {
            NSLog(@"Installation succeeded.");
        }
    }];

    [installer.progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"fractionCompleted"] && [object isKindOfClass:[NSProgress class]]) {
        NSProgress *progress = (NSProgress *)object;
        NSLog(@"Installation progress: %f.", progress.fractionCompleted * 100);

        if (progress.finished) {
            [progress removeObserver:self forKeyPath:@"fractionCompleted"];
        }
    }
}

// MARK: - Public methods

// Create the bundle in the user’s home directory to store artifacts generated during installation.
- (void)setUpVirtualMachineArtifacts
{
    createVMBundle();
}

// MARK: Start macOS installation

- (void)installMacOS:(NSURL *)ipswURL
{
    NSLog(@"Attempting installation from IPSW file: %s\n", [ipswURL fileSystemRepresentation]);
    [VZMacOSRestoreImage loadFileURL:ipswURL completionHandler:^(VZMacOSRestoreImage *restoreImage, NSError *error) {
        if (error) {
            abortWithErrorMessage(error.localizedDescription);
        }

        VZMacOSConfigurationRequirements *macOSConfiguration = restoreImage.mostFeaturefulSupportedConfiguration;
        if (!macOSConfiguration || !macOSConfiguration.hardwareModel.supported) {
            abortWithErrorMessage(@"No supported Mac configuration available.");
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupVirtualMachineWithMacOSConfigurationRequirements:macOSConfiguration];
            [self startInstallationWithRestoreImageFileURL:ipswURL];
        });
    }];
}

@end  // End implementation

#endif  // Apple Silicon conditional compilation end
