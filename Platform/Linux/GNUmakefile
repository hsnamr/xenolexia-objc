# GNUmakefile for Xenolexia Linux App

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Xenolexia

Xenolexia_OBJC_FILES = \
	main.m \
	UI/XLLinuxApp.m \
	UI/Screens/XLLibraryWindowController.m \
	UI/Screens/XLBookDetailWindowController.m \
	UI/Screens/XLReaderWindowController.m \
	../../Core/Models/Book.m \
	../../Core/Models/Language.m \
	../../Core/Models/Vocabulary.m \
	../../Core/Models/Reader.m \
	../../Core/Services/XLBookParserService.m \
	../../Core/Services/XLEpubParser.m \
	../../Core/Services/XLManager.m \
	../../Core/Services/XLTranslationEngine.m \
	../../Core/Services/XLTranslationService.m \
	../../Core/Services/XLStorageService.m \
	../../Core/Services/XLStorageServiceBlockHelper.m \
	../../Core/Services/XLExportService.m \
	../../../SmallStep/SmallStep/Core/SSPlatform.m \
	../../../SmallStep/SmallStep/Core/SSFileSystem.m \
	../../../SmallStep/SmallStep/Platform/Linux/SSLinuxPlatform.m \
	../../DictionaryService.m \
	../../DownloadService.m \
	../../TranslationService.m

Xenolexia_INCLUDE_DIRS = \
	-I. \
	-IUI \
	-IUI/Screens \
	-I../../Core/Models \
	-I../../Core/Services \
	-I../../SmallStep/SmallStep/Core \
	-I../../SmallStep/SmallStep/Platform/Linux \
	-I../../ \
	-I/usr/include \
	-I/usr/include/libxml2 \
	-I/usr/include/libzip

Xenolexia_HEADER_FILES = \
	UI/XLLinuxApp.h \
	UI/Screens/XLLibraryWindowController.h \
	UI/Screens/XLBookDetailWindowController.h \
	UI/Screens/XLReaderWindowController.h

# Link against SQLite, libzip, and libxml2
# GNUStep uses LIBRARIES_DEPEND_UPON for linking
Xenolexia_LIBRARIES_DEPEND_UPON = -lsqlite3 -lzip -lxml2
ADDITIONAL_LDFLAGS = -L/lib/x86_64-linux-gnu

include $(GNUSTEP_MAKEFILES)/application.make
