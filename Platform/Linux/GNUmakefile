# GNUmakefile for Xenolexia Linux App

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Xenolexia

Xenolexia_OBJC_FILES = \
	main.m \
	UI/XLLinuxApp.m \
	UI/Screens/XLLibraryWindowController.m \
	../../Core/Models/Book.m \
	../../Core/Models/Language.m \
	../../Core/Models/Vocabulary.m \
	../../Core/Models/Reader.m \
	../../Core/Services/XLManager.m \
	../../Core/Services/XLBookParserService.m \
	../../Core/Services/XLStorageService.m \
	../../Core/Services/XLTranslationEngine.m \
	../../Core/Services/XLTranslationService.m \
	../../Core/Services/XLExportService.m \
	../../SmallStep/SmallStep/Core/SSPlatform.m \
	../../SmallStep/SmallStep/Core/SSFileSystem.m \
	../../SmallStep/SmallStep/Platform/Linux/SSLinuxPlatform.m \
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
	-I../../

Xenolexia_HEADER_FILES = \
	UI/XLLinuxApp.h \
	UI/Screens/XLLibraryWindowController.h

# Link against SQLite
Xenolexia_LIBRARIES_DEPEND_UPON = -lsqlite3

include $(GNUSTEP_MAKEFILES)/application.make
