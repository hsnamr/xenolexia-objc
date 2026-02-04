# GNUmakefile for Xenolexia Linux App
# SmallStep: build as library; run ./scripts/install-smallstep.sh, then headers in include/, lib in lib/.

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Xenolexia

# SmallStep: headers and lib from xenolexia-objc/include and lib (absolute path for obj/ build)
XENOLEXIA_OBJC_ROOT = $(shell cd ../.. && pwd)
SMALLSTEP_INCLUDE = $(XENOLEXIA_OBJC_ROOT)/include
SMALLSTEP_LIB = $(XENOLEXIA_OBJC_ROOT)/lib

Xenolexia_OBJC_FILES = \
	main.m \
	UI/XLLinuxApp.m \
	UI/Screens/XLLibraryWindowController.m \
	UI/Screens/XLBookDetailWindowController.m \
	UI/Screens/XLReaderWindowController.m \
	UI/Screens/XLVocabularyWindowController.m \
	UI/Screens/XLReviewWindowController.m \
	UI/Screens/XLSettingsWindowController.m \
	UI/Screens/XLOnboardingWindowController.m \
	UI/Screens/XLStatisticsWindowController.m \
	../../Core/Models/Book.m \
	../../Core/Models/Language.m \
	../../Core/Models/Vocabulary.m \
	../../Core/Models/Reader.m \
	../../Core/Native/XLSm2.m \
	../../Core/Native/XLEpubReader.m \
	../../Core/Native/XLFB2Reader.m \
	../../Core/Native/XLPDFReader.m \
	../../Core/Native/XLMobiReader.m \
	../../Core/Services/XLBookParserService.m \
	../../Core/Services/XLEpubParser.m \
	../../Core/Services/XLNativeParsers.m \
	../../Core/Services/XLManager.m \
	../../Core/Services/XLTranslationEngine.m \
	../../Core/Services/XLTranslationService.m \
	../../Core/Services/XLLibreTranslateClient.m \
	../../Core/Services/XLStorageService.m \
	../../Core/Services/XLStorageServiceBlockHelper.m \
	../../Core/Services/XLExportService.m \
	../../ThirdParty/chcsvparser/CHCSVParser/CHCSVParser/CHCSVParser.m \
	../../ThirdParty/fmdb/src/fmdb/FMDatabase.m \
	../../ThirdParty/fmdb/src/fmdb/FMResultSet.m \
	../../ThirdParty/fmdb/src/fmdb/FMDatabaseAdditions.m \
	$(SMALLSTEP_DIR)/SmallStep/Core/SSPlatform.m \
	$(SMALLSTEP_DIR)/SmallStep/Core/SSFileSystem.m \
	$(SMALLSTEP_DIR)/SmallStep/Core/SSHostApplication.m \
	$(SMALLSTEP_DIR)/SmallStep/Core/SSMainMenu.m \
	$(SMALLSTEP_DIR)/SmallStep/Platform/Linux/SSLinuxPlatform.m \
	../../DictionaryService.m \
	../../DownloadService.m \
	../../TranslationService.m

Xenolexia_INCLUDE_DIRS = \
	-I. \
	-IUI \
	-IUI/Screens \
	-I../../Core/Models \
	-I../../Core/Services \
	-I../../Core/Native \
	-I$(SMALLSTEP_INCLUDE) \
	-I../../ \
	-I../../ThirdParty/fmdb/src/fmdb \
	-I../../ThirdParty/chcsvparser/CHCSVParser/CHCSVParser \
	-I/usr/include \
	-I/usr/include/libxml2

Xenolexia_HEADER_FILES = \
	UI/XLLinuxApp.h \
	UI/Screens/XLLibraryWindowController.h \
	UI/Screens/XLBookDetailWindowController.h \
	UI/Screens/XLReaderWindowController.h \
	UI/Screens/XLVocabularyWindowController.h \
	UI/Screens/XLReviewWindowController.h \
	UI/Screens/XLSettingsWindowController.h \
	UI/Screens/XLOnboardingWindowController.h \
	UI/Screens/XLStatisticsWindowController.h

# Link against SmallStep (from xenolexia-objc/lib), SQLite, libxml2, zlib, libzip, libcurl (downloads)
Xenolexia_LIBRARIES_DEPEND_UPON = -lSmallStep -lsqlite3 -lxml2 -lz -lzip -lcurl
ADDITIONAL_LDFLAGS = -L$(SMALLSTEP_LIB) -L/lib/x86_64-linux-gnu

include $(GNUSTEP_MAKEFILES)/application.make
