# makefile relelase 0.1.0
NAME = dformlib.lib
NAME_DEBUG = dformlib.lib
NAME_REL = dformlib.rel.lib
PROJECT_VERSION = 0.1.0

#SRC = $(wildcard src/dfl/*.d)
#SRC += $(wildcard src/dfl/internal/*.d)

#SRC += src/dfl/internal/d1.d
#SRC += src/dfl/internal/wincom.d ?

SRC += src/dfl/internal/clib.d
SRC += src/dfl/internal/com.d
SRC += src/dfl/internal/d2.d
SRC += src/dfl/internal/dlib.d
SRC += src/dfl/internal/utf.d
SRC += src/dfl/internal/winapi.d

SRC += src/dfl/exception.d
SRC += src/dfl/event.d
SRC += src/dfl/drawing.d
SRC += src/dfl/base.d
SRC += src/dfl/collections.d
SRC += src/dfl/control.d
SRC += src/dfl/data.d
SRC += src/dfl/application.d
SRC += src/dfl/menu.d
SRC += src/dfl/form.d
SRC += src/dfl/label.d
SRC += src/dfl/button.d
SRC += src/dfl/textbox.d
SRC += src/dfl/environment.d
SRC += src/dfl/timer.d
SRC += src/dfl/commondialog.d
SRC += src/dfl/filedialog.d
SRC += src/dfl/colordialog.d
SRC += src/dfl/fontdialog.d
SRC += src/dfl/folderdialog.d

D_DIR = 
ROOT_SOURCE_DIR = src

BIN=bin
#SRC = $(getSources)

TARGET = lib
#COMPRESS=yes
SRC_TEST = $(SRC)
#oppure
#SRC_TEST = $(filter-out $(ROOT_SOURCE_DIR)/app.d, $(SRC))
#SRC_TEST += $(wildcard tests/*.d)

# Compiler flag
# -----------
ifeq ($(TARGET),lib)
	DCFLAGS += -lib
	DCFLAGS_REL += -lib
endif

DCFLAGS += $(DBG_CODE) #compile in debug code
DCFLAGS += $(OPTIMIZE) #optimize
DCFLAGS += -g # add symbolic debug info
DCFLAGS += $(WARN_AS_ERR) # warnings as errors (compilation will halt)
#DCFLAGS += $(WARN_AS_MSG) # warnings as messages (compilation will continue)

# release flags
DCFLAGS_REL += $(OPTIMIZE) $(WARN_AS_MSG) -release -inline -boundscheck=off

DCFLAGS_TEST += -unittest
# DCFLAGS_TEST += -main -quiet

# Linker flag
# -----------
#DCFLAGS_LINK += $(LINKERFLAG)-lhpdf
# DCFLAGS_LINK += $(LINKERFLAG)-L/usr/lib/

# Version flag
# -----------
#VERSION_FLAG += -version=StdLoggerDisableLogging
#VERSION_FLAG += -version=use_gtk

# Packages
# -----------
PKG = $(wildcard $(BIN)/$(NAME))
PKG_SRC = $(PKG) $(SRC) makefile

# -----------
# Libraries
# -----------

LIB_TEST += $(LIB)
DCFLAGS_IMPORT_TEST += $(DCFLAGS_IMPORT)

###############
# Common part
###############
DEFAULT: all

DC = dmd
DEPEND = $(D_DIR)/depend/depend

STATIC_LIB_EXT = .a
STATIC_LIB_PRE = lib

ifeq ($(DC),gdc)
	COMPILER=gdc
	STATIC_LIBNAME=$(NAME)-$(COMPILER)
	WARN_AS_ERR=-Werror
	WARN_AS_MSG=-w
	DBG_CODE=-fdebug
	OUTPUT=-o
	OPTIMIZE=-O2
	LINKERFLAG=-Xlinker
else
	COMPILER=dmd
	STATIC_LIBNAME=$(NAME)
	WARN_AS_MSG=-wi
	WARN_AS_ERR=-w
	#compile in debug code
	DBG_CODE=-debug
	OUTPUT=-of
	OPTIMIZE=-O
	LINKERFLAG=-L
endif

NAME_TEST = test-runner

DSCAN=~/d/Dscanner/bin/dscanner
MKDIR = mkdir
RM = del /Q
UPX = upx --no-progress

DCFLAGS += -m32

getSources = $(shell find $(ROOT_SOURCE_DIR) -name "*.d")

# Version flag
# use: make VERS=x
# -----------
VERSION_FLAG += $(if $(VERS), -version=$(VERS), )

.PHONY: all clean clobber test testv run pkg pkgsrc tags syn style loc var ver help release

all: $(BIN)/$(NAME_DEBUG)
release: builddir $(BIN)/$(NAME_REL)
deps: deps.pdf 
deps2: deps2.pdf 

builddir:
	@$(MKDIR) $(BIN)

$(BIN)/$(NAME_DEBUG): $(SRC) $(LIB)
	$(DC) $^ $(VERSION_FLAG) $(DCFLAGS) $(DCFLAGS_IMPORT) $(DCFLAGS_LINK) $(DCFLAGS_J) $(OUTPUT)$@

$(BIN)/$(NAME_REL): $(SRC) $(LIB)| builddir
	$(DC) $^ $(VERSION_FLAG) $(DCFLAGS_REL) $(DCFLAGS_IMPORT) $(DCFLAGS_LINK) $(DCFLAGS_J) $(OUTPUT)$@
ifdef COMPRESS
	$(UPX) $@
endif

deps2.pdf: dependencies
	$(DEPEND) --filter='src' --dot dependencies | dot -Tpdf -o $@

deps.pdf: dependencies
	$(DEPEND) --filter='src' --dot dependencies | tred | dot -Tpdf -o $@

dependencies: $(SRC)
	$(DC) -deps=dependencies $^ -c $(DCFLAGS) $(DCFLAGS_IMPORT) $(DCFLAGS_J) $(OUTPUT)/dev/null

run: all
	$(BIN)/$(NAME_DEBUG)

## with unit_threaded:
## make test T=test_name
test: build_test
	@$(BIN)/$(NAME_TEST) $(T)

testv: build_test
	@$(BIN)/$(NAME_TEST) -d $(T)

build_test: $(BIN)/$(NAME_TEST)

$(BIN)/$(NAME_TEST): $(SRC_TEST) $(LIB_TEST)| builddir
	$(DC) $^ $(VERSION_FLAG) $(DCFLAGS_TEST) $(DCFLAGS_IMPORT_TEST) $(DCFLAGS_LINK) $(DCFLAGS_J) $(OUTPUT)$@

pkgdir:
	$(MKDIR) pkg

pkg: $(PKG) | pkgdir
	tar -jcf pkg/$(NAME)-$(PROJECT_VERSION).tar.bz2 $^
	zip pkg/$(NAME)-$(PROJECT_VERSION).zip $^

pkgsrc: $(PKG_SRC) | pkgdir
	tar -jcf pkg/$(NAME)-$(PROJECT_VERSION)-src.tar.bz2 $^

tags: $(SRC)
	$(DSCAN) --ctags $^ > tags

style: $(SRC)
	$(DSCAN) --styleCheck $^

syn: $(SRC)
	$(DSCAN) --syntaxCheck $^

loc: $(SRC)
	$(DSCAN) --sloc $^

clean:
	$(RM) $(BIN)/*.o
	$(RM) $(BIN)/*.log
	$(RM) $(BIN)/__*
	$(RM) $(BIN)/$(NAME_TEST)
	$(RM) deps.pdf
	$(RM) deps2.pdf
	$(RM) dependencies

clobber: clean
	$(RM) $(BIN)/$(NAME_REL)
	$(RM) $(BIN)/$(NAME_DEBUG)

ver:
	@echo $(PROJECT_VERSION)

var:
	@echo
	@echo NAME:       $(NAME)
	@echo NAME_DEBUG: $(NAME_DEBUG)
	@echo NAME_REL:   $(NAME_REL)
	@echo TARGET:     $(TARGET)
	@echo COMPRESS:   $(COMPRESS)
	@echo PRJ_VER:    $(PROJECT_VERSION)
	@echo
	@echo D_DIR: $(D_DIR)
	@echo BIN:   $(BIN)
	@echo SRC:   $(SRC)
	@echo LIB:   $(LIB)
	@echo
	@echo DC:      $(DC)
	@echo DCFLAGS: $(DCFLAGS)
	@echo DCFLAGS_LINK: $(DCFLAGS_LINK)
	@echo DCFLAGS_IMPORT: $(DCFLAGS_IMPORT)
	@echo VERSION: $(VERSION_FLAG)
	@echo
	@echo ==== test ===
	@echo NAME_TEST: $(NAME_TEST)
	@echo SRC_TEST: $(SRC_TEST)
	@echo DCFLAGS_IMPORT_TEST: $(DCFLAGS_IMPORT_TEST)
	@echo LIB_TEST: $(LIB_TEST)
	@echo
	@echo T: $(T)

# Help Target
help:
	@echo "The following are some of the valid targets for this Makefile:"
	@echo "... all (the default if no target is provided)"
	@echo "... test"
	@echo "... testv Runs unitt_threded test in verbose (-debug) mode"
	@echo "... run"
	@echo "... clean"
	@echo "... clobber"
	@echo "... pkg Generates a binary package"
	@echo "... pkgsrc Generates a source package"
	@echo "... tags Generates tag file"
	@echo "... style Checks programming style"
	@echo "... syn"
	@echo "... upx Compress using upx"
	@echo "... loc Counts lines of code"
	@echo "... var Lists all variables"
