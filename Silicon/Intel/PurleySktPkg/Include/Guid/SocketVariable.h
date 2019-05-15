/** @file

Copyright (c) 2018, Intel Corporation. All rights reserved.<BR>
SPDX-License-Identifier: BSD-2-Clause-Patent

**/

#ifndef   __SOCKET_CONFIG_DATA_H__
#define   __SOCKET_CONFIG_DATA_H__

#include <UncoreCommonIncludes.h>
#include "SocketConfiguration.h"
#include <Guid/SocketIioVariable.h>
#include <Guid/SocketCommonRcVariable.h>
#include <Guid/SocketPowermanagementVariable.h>
#include <Guid/SocketProcessorCoreVariable.h>
#include <Guid/SocketMpLinkVariable.h>
#include <Guid/SocketMemoryVariable.h>

#pragma pack(1)

typedef struct {
  SOCKET_IIO_CONFIGURATION       IioConfig;
  SOCKET_COMMONRC_CONFIGURATION  CommonRcConfig;
  SOCKET_MP_LINK_CONFIGURATION   CsiConfig;
  SOCKET_MEMORY_CONFIGURATION    MemoryConfig;
  SOCKET_POWERMANAGEMENT_CONFIGURATION PowerManagementConfig;
  SOCKET_PROCESSORCORE_CONFIGURATION   SocketProcessorCoreConfiguration;
} SOCKET_CONFIGURATION;



#pragma pack()
#endif

