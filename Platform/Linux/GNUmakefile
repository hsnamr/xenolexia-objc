# GNUmakefile for Xenolexia Linux App
# SmallStep: use ../../../SmallStep (Xenolexia/SmallStep). Create symlink: from Xenolexia repo: ln -sn ../SmallStep SmallStep

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Xenolexia

# Path to SmallStep from Platform/Linux (Xenolexia/SmallStep or sibling via symlink)
SMALLSTEP_DIR = ../../../SmallStep

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
	../../Core/Services/XLStorageService.m \
	../../Core/Services/XLStorageServiceBlockHelper.m \
	../../Core/Services/XLExportService.m \
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
	-I$(SMALLSTEP_DIR)/SmallStep/Core \
	-I$(SMALLSTEP_DIR)/SmallStep/Platform/Linux \
	-I../../ \
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

# Link against SmallStep (from xenolexia-objc/lib), SQLite, libxml2, zlib, libzip
Xenolexia_LIBRARIES_DEPEND_UPON = -lSmallStep -lsqlite3 -lxml2 -lz -lzip
ADDITIONAL_LDFLAGS = -L$(SMALLSTEP_LIB) -L/lib/x86_64-linux-gnu

include $(GNUSTEP_MAKEFILES)/application.make
