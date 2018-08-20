#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "KTVHCCommon.h"
#import "KTVHCError.h"
#import "KTVHCLog.h"
#import "KTVHCDataCacheItem.h"
#import "KTVHCDataCacheItemZone.h"
#import "KTVHCDataCallback.h"
#import "KTVHCDataFileSource.h"
#import "KTVHCDataNetworkSource.h"
#import "KTVHCDataPrivate.h"
#import "KTVHCDataReader.h"
#import "KTVHCDataRequest.h"
#import "KTVHCDataResponse.h"
#import "KTVHCDataSourceProtocol.h"
#import "KTVHCDataSourceQueue.h"
#import "KTVHCDataSourcer.h"
#import "KTVHCDataStorage.h"
#import "KTVHCDataUnit.h"
#import "KTVHCDataUnitItem.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDataUnitQueue.h"
#import "KTVHCDownload.h"
#import "KTVHCHTTPConnection.h"
#import "KTVHCHTTPHeader.h"
#import "KTVHCHTTPRequest.h"
#import "KTVHCHTTPResponse.h"
#import "KTVHCHTTPResponsePing.h"
#import "KTVHCHTTPServer.h"
#import "KTVHCHTTPURL.h"
#import "KTVHCPathTools.h"
#import "KTVHCURLTools.h"
#import "KTVHTTPCacheImp.h"
#import "KTVHTTPCache.h"

FOUNDATION_EXPORT double KTVHTTPCacheVersionNumber;
FOUNDATION_EXPORT const unsigned char KTVHTTPCacheVersionString[];

