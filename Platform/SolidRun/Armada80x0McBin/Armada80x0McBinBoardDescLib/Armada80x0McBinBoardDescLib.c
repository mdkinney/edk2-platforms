/**
*
*  Copyright (C) 2018, Marvell International Ltd. and its affiliates.
*
*  SPDX-License-Identifier: BSD-2-Clause-Patent
*
**/

#include <Uefi.h>

#include <Library/ArmadaBoardDescLib.h>
#include <Library/BaseMemoryLib.h>
#include <Library/DebugLib.h>
#include <Library/IoLib.h>
#include <Library/MemoryAllocationLib.h>
#include <Library/UefiBootServicesTableLib.h>

//
// GPIO Expander
//
EFI_STATUS
EFIAPI
ArmadaBoardGpioExpanderGet (
  IN OUT MV_GPIO_EXPANDER **GpioExpanders,
  IN OUT UINTN             *GpioExpanderCount
  )
{
  /* No GPIO expanders on board */
  *GpioExpanders = NULL;
  *GpioExpanderCount = 0;

  return EFI_SUCCESS;
}

//
// Order of devices in SdMmcDescTemplate has to be in par with ArmadaSoCDescLib
//
STATIC
MV_BOARD_SDMMC_DESC mMcBinSdMmcDescTemplate[] = {
  { /* eMMC 0xF06E0000 */
    0,     /* SOC will be filled by MvBoardDescDxe */
    0,     /* SdMmcDevCount will be filled by MvBoardDescDxe */
    FALSE, /* Xenon1v8Enabled */
    TRUE,  /* Xenon8BitBusEnabled */
    TRUE,  /* XenonSlowModeEnabled */
    0x40,  /* XenonTuningStepDivisor */
    EmbeddedSlot /* SlotType */
  },
  { /* SD/MMC 0xF2780000 */
    0,     /* SOC will be filled by MvBoardDescDxe */
    0,     /* SdMmcDevCount will be filled by MvBoardDescDxe */
    FALSE, /* Xenon1v8Enabled */
    FALSE, /* Xenon8BitBusEnabled */
    FALSE, /* XenonSlowModeEnabled */
    0x19,  /* XenonTuningStepDivisor */
    EmbeddedSlot /* SlotType */
  }
};

EFI_STATUS
EFIAPI
ArmadaBoardDescSdMmcGet (
  OUT UINTN               *SdMmcDevCount,
  OUT MV_BOARD_SDMMC_DESC **SdMmcDesc
  )
{
  *SdMmcDesc = mMcBinSdMmcDescTemplate;
  *SdMmcDevCount = ARRAY_SIZE (mMcBinSdMmcDescTemplate);

  return EFI_SUCCESS;
}
