#
# David Joffe
# Copyright 1998-2022 David Joffe
# Created 1998/12
# Makefile for Dave Gnukem
#
# 2016-10: Get this working on Mac OS X [dj]
# 2017-07-29: Remove obsolete standalone-editor-related stuff, and add new thing_monsters.o
#

CPP = g++
CC = gcc

djLIBS2=
djCCFLAGS2=
djUSE_UNICODE=n
################################# dj2022-11 BETA
# dj2022-22 BETA development experimental new TTF TrueType font and Unicode support etc. set to y to enable (NOT in current production Dave Gnukem still very beta)
#djUSE_UNICODE=y

ifeq ($(djUSE_UNICODE),y)
    djLIBS_TTF= -lSDL2_ttf 
    djLIBS2+= $(djLIBS_TTF) 

    djLIBS_UTF8PROC= -lutf8proc 
    djLIBS2+= $(djLIBS_UTF8PROC) 

    djCCFLAGS2+= -DdjUNICODE_SUPPORT 
endif
#################################


# dj2016-10 Add L -I/usr/local/include/SDL in process of getting this working on Mac OS X - not sure if this is 'bad' to just have both /usr/include and /usr/local/include??
INCLUDEDIRS= -I/usr/include/SDL2 -I/usr/local/include/SDL2

#CCFLAGS = -O -Wall $(INCLUDEDIRS)

# Un/recomment as needed for removing sound support, optimizations etc
# If you don't -DDATA_DIR to a valid dir, then data files will be assumed
# to be in current directory
#CCFLAGS = -Wall -I/usr/local/include -DHAVE_SOUND -DDEBUG -O -m486
CCFLAGS = -std=c++11 -Wall -Wno-switch -DDEBUG $(INCLUDEDIRS)

################################# dj2022-11 BETA
CCFLAGS += $(djCCFLAGS2)
#################################

#Release version:
#CCFLAGS = -O -Wall -I/usr/local/include -DHAVE_SOUND $(INCLUDEDIRS)

LIBS = -lSDL2 -lSDL2_mixer $(djLIBS2) -lpthread
BIN = davegnukem


ifeq ($(OS),Windows_NT)
    #CCFLAGS += -D WIN32
    ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
        #CCFLAGS += -D AMD64
    else
        ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
            #CCFLAGS += -D AMD64
        endif
        ifeq ($(PROCESSOR_ARCHITECTURE),x86)
            #CCFLAGS += -D IA32
        endif
    endif
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        #CCFLAGS += -D LINUX
    endif
    # dj2020-06 Add basic HaikuOS detection and override some default settings here if detected
    ifeq ($(UNAME_S),Haiku)
        INCLUDEDIRS=`sdl2-config --cflags`
        CCFLAGS=-Wall -Wno-switch -DDEBUG $(INCLUDEDIRS)
        LIBS=`sdl2-config --libs` -lSDL2 -lSDL2_mixer -lpthread
    endif
    ifeq ($(UNAME_S),Darwin)
        LIBS += -framework Cocoa `sdl2-config --libs` 
	# dj2022-11 add c++17 min here for Mac (might change this later to c++17)
	CCFLAGS += -std=c++17 `sdl2-config --cflags`
    endif
    UNAME_P := $(shell uname -p)
    ifeq ($(UNAME_P),x86_64)
        #CCFLAGS += -D AMD64
    endif
    ifneq ($(filter %86,$(UNAME_P)),)
        #CCFLAGS += -D IA32
    endif
    ifneq ($(filter arm%,$(UNAME_P)),)
        #CCFLAGS += -D ARM
    endif
endif


# dj2022-11 in theory would be nice if OBJFILES list could be auto-generated from the presence of .c or .cpp files in the src folder so we could more easily add new .cpp files without having to update Makefiles

OBJFILES = src/main.o     src/graph.o   src/game.o         src/menu.o\
           src/block.o    src/credits.o src/instructions.o src/djstring.o \
           src/djimage.o  src/djlog.o   src/inventory.o    src/mission.o\
           src/hiscores.o src/mixins.o  src/thing.o        src/hero.o \
           src/thing_monsters.o src/gameending.o \
           src/level.o    src/settings.o src/keys.o \
           src/djtypes.o  src/bullet.o \
           src/ed.o src/ed_DrawBoxContents.o src/ed_common.o src/ed_lvled.o \
           src/ed_macros.o src/ed_spred.o \
           src/sdl/djgraph.o src/sdl/djinput.o src/sdl/djsound.o \
           src/sdl/djtime.o \
           src/sys_error.o src/sys_log.o src/m_misc.cpp

default: gnukem

gnukem: $(OBJFILES)
	$(CPP) -o $(BIN) $(OBJFILES) $(LIBS) $(CCFLAGS)

clean:
	rm -f $(BIN) *~ core \#*
	find src -name '*.o' | xargs rm -f

# dj2022-11 do we even need this "make dist" is it used for anything anymore? used to be for preparing a "distribution" ie release. can we remove this? want to simplify Makefile (I know I added this looong ago so in theory I should know, but I don't remember, and I don't know if any downstream port maintainers now use it for anything). Certainly I don't use it or want or need it for anything myself so I don't mind if it's gone.

dist:
	rm -f core *~ \#*
	find src -name '*.o' | xargs rm -f


%.o: %.c
	$(CPP) $(CCFLAGS) -c $< -o $@

%.o: %.cpp
	$(CPP) $(CCFLAGS) -c $< -o $@

# The following was added to support debian packaging.  The make install
# command will probably work on other unix like OS but not sure.
# There probably should be some checks for different OS to be perfect.
# Previously there was no install target at all which makes using 
# packaging tools harder (easier for me to add install to Makefile).
# Note DESTDIR variable is used by Debian packaging tools for staging
# and PREFIX may already set as environment variable for some distro
# -Craig
ifeq ($(PREFIX),)
    PREFIX := /usr/local
endif

install: 
	@install -m 755 -d $(DESTDIR)/opt/gnukem	
	@install -m 755 davegnukem $(DESTDIR)/opt/gnukem
	@install -d $(DESTDIR)/usr/share/icons/hicolor/32x32/apps
	@install -m 644 debian/gnukem.png $(DESTDIR)/usr/share/icons/hicolor/32x32/apps
	@install -d $(DESTDIR)/usr/share/applications
	@install -m 644 debian/gnukem.desktop $(DESTDIR)/usr/share/applications
	@install -d $(DESTDIR)$(PREFIX)/bin/
	@install -m 755 debian/gnukem.sh $(DESTDIR)$(PREFIX)/bin/gnukem
	@cp -r data $(DESTDIR)/opt/gnukem/
	@echo Dave Gnukem Installed.  Launch with $(DESTDIR)$(PREFIX)/bin/gnukem
	

uninstall:
	rm -rf $(DESTDIR)/opt/gnukem
	rm -f $(DESTDIR)$(PREFIX)/bin/gnukem 
	rm -f $(DESTDIR)/usr/share/applications/gnukem.desktop
	rm -f $(DESTDIR)/usr/share/icons/hicolor/32x32/apps/gnukem.png	
