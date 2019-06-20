# Makefile for screencast
#
# Copyright (c) 2015-2019 Daniel Bermond < gmail.com: danielbermond >
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

NAME    := screencast
RELEASE := v1.5.0.next

# source directory
SOURCE_DIR := src

# source files (the order of files in '$(SOURCE_FILES)' is important)
SOURCE_FILES := settings_general.sh
SOURCE_FILES += settings_format.sh
SOURCE_FILES += settings_audio.sh
SOURCE_FILES += settings_video.sh
SOURCE_FILES += settings_effects.sh
SOURCE_FILES += cmdline_get.sh
SOURCE_FILES += cmdline_check.sh
SOURCE_FILES += system.sh
SOURCE_FILES += message.sh
SOURCE_FILES += error.sh
SOURCE_FILES += show.sh
SOURCE_FILES += screen.sh
SOURCE_FILES += effects.sh
SOURCE_FILES += set_configs.sh
SOURCE_FILES += ffmpeg.sh
SOURCE_FILES += record.sh
SOURCE_FILES += start.sh
SOURCE_FILES := $(addprefix $(SOURCE_DIR)/, $(SOURCE_FILES))
SOURCE_MAIN  := $(SOURCE_DIR)/start.sh

# install directories
PREFIX   := /usr/local
CONFDIR  := /etc
BINDIR   := $(PREFIX)/bin
DATADIR  := $(PREFIX)/share
DOCDIR   := $(DATADIR)/doc
MANDIR   := $(DATADIR)/man
BCOMPDIR := $(DATADIR)/bash-completion/completions

# shell commands
PRINT_SCLINE_SRCFILE := head -n2 "$$file" | tail -n1
PRINT_SCLINE_SCRIPT  := head -n2 $(NAME)  | tail -n1

# shell strings
HEADER_DESC     := \# $(NAME) - POSIX-compliant shell script to record a X11 desktop

# shell regular expressions
HEADER_START    := ^\#!\/bin\/.*
HEADER_END      := <http:\/\/www\.gnu\.org\/licenses\/>\.$$
COPYRIGHT_LINE  := ^\#[[:space:]]Copyright[[:space:]](c)[[:space:]]2015.*Daniel[[:space:]]Bermond[[:space:]]<.*
SHELLCHECK_LINE := ^\#[[:space:]]shellcheck[[:space:]]disable=.*

# skip these global shellcheck ignores (should be used only in module files)
SHELLCHECK_SKIP := SC2034 SC2154

# correctly assign program version (development/git or stable release)
ifeq ($(shell [ -d '.git' ] ; printf '%s' "$$?"), 0)
    
    VERSION := $(shell git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g')

    ifneq (,$(findstring .r0., $(VERSION)))
    
        VERSION := $(RELEASE)
        
    endif
else
    VERSION := $(RELEASE)
    
endif

.PHONY: all clean distclean check install uninstall

.PHONY: shellcheck shellcheck-src shellcheck-modules shellcheck-tests shellcheck-tools shellcheck-all

all: $(NAME)

$(NAME): $(SOURCE_FILES)
	@# add header
	@printf '%s\n' 'adding copyright and license header'
	@sed -n '/$(HEADER_START)/,/$(HEADER_END)/p' $(SOURCE_MAIN) > $(NAME)
	@desc_line="$$(sed -n '/$(COPYRIGHT_LINE)/=' $(NAME))" ; \
	 desc_line=$$((desc_line - 2)) ; \
	 sed -i "$${desc_line}s/^.*$$/$(HEADER_DESC)/" $(NAME)
	@sed -i "s/2015-[0-9]\{4\}/2015-$$(date +%Y)/" $(NAME)
	
	@# add source files
	@for file in $(SOURCE_FILES) ; \
	do \
	    printf '%s\n' "adding file '$${file}'" ; \
	    cat "$$file" | sed '/$(HEADER_START)/,/$(HEADER_END)/d' >> $(NAME) ; \
	done
	
	@# add global shellcheck ignores
	@printf '%s\n' 'adding global shellcheck ignores'
	@if $(PRINT_SCLINE_SCRIPT) | grep -q '$(SHELLCHECK_LINE)' ; \
	then \
	    sed -i '2d' $(NAME) ; \
	fi
	@for file in $(SOURCE_FILES) ; \
	do \
	    if $(PRINT_SCLINE_SRCFILE) | grep -q '$(SHELLCHECK_LINE)' ; \
	    then \
	        module_rules="$$($(PRINT_SCLINE_SRCFILE) | grep '$(SHELLCHECK_LINE)' | sed 's/.*=//')" ; \
	        \
	        module_rules="$$(printf '%s' "$$module_rules" | sed 's/,/ /g')" ; \
	        \
	        for rule in $$module_rules ; \
	        do \
	            if printf '%s' '$(SHELLCHECK_SKIP)' | grep -q "$$rule" ; \
	            then \
	                continue ; \
	                \
	            elif ! $(PRINT_SCLINE_SCRIPT) | grep -q "$$rule" ; \
	            then \
	                if $(PRINT_SCLINE_SCRIPT) | grep -q '$(SHELLCHECK_LINE)' ; \
	                then \
	                    sed -i "2s/$$/,$${rule}/" $(NAME) ; \
	                else \
	                    sed -i "2i# shellcheck disable=$${rule}" $(NAME) ; \
	                fi ; \
	            fi ; \
	        done ; \
	    fi ; \
	done
	
	@# set program version
	@printf '%s\n' 'setting program version'
	@sed -i "s/^$(NAME)_version=$$/$(NAME)_version='$(VERSION)'/" $(NAME)
	
	@# set script file to be executable
	@ chmod a+x $(NAME)

clean:
	@if [ -f '$(NAME)' ] ; \
	then \
	    printf '%s\n' "removing file '$(NAME)'" ; \
	    rm -f $(NAME) ; \
	fi

distclean: clean
	@if [ -d './test/output' ] ; \
	then \
	    printf '%s\n' "removing tests output directory './test/output/'" ; \
	    rm -rf ./test/output ; \
	fi

check: all
	@./test/checksc

shellcheck: all
	@shellcheck ./$(NAME)

shellcheck-src shellcheck-modules:
	@shellcheck ./src/*.sh

shellcheck-tests:
	@shellcheck ./test/checksc

shellcheck-tools:
	@shellcheck ./tools/*

shellcheck-all: shellcheck shellcheck-src shellcheck-tests shellcheck-tools

install: all
	install -D -m755 $(NAME)                 $(DESTDIR)$(BINDIR)/$(NAME)
	install -D -m644 bash-completion/$(NAME) $(DESTDIR)$(BCOMPDIR)/$(NAME)
	install -D -m644 README.md                  $(DESTDIR)$(DOCDIR)/$(NAME)/README.md
	install -D -m644 doc/$(NAME).1           $(DESTDIR)$(MANDIR)/man1/$(NAME).1
	gzip    -9 -n -f $(DESTDIR)$(MANDIR)/man1/$(NAME).1

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(NAME)
	rm -f $(DESTDIR)$(BCOMPDIR)/$(NAME)
	rm -f $(DESTDIR)$(DOCDIR)/$(NAME)/README.md
	rm -f $(DESTDIR)$(MANDIR)/man1/$(NAME).1.gz
