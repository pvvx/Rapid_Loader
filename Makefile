#############################################################
#
# Root Level Makefile
#
#############################################################

ESPOPTION ?= -p COM6 -b 256000

GENIMAGEOPTION = -ff 80m -fm qio -fs 4m

ADDR_FW1 = 0x00000
ADDR_FW2 = 0x40000

# Base directory for the compiler
XTENSA_TOOLS_ROOT ?= c:/Espressif/xtensa-lx106-elf/bin
#PATH := $(XTENSA_TOOLS_ROOT);$(PATH)

# select which tools to use as compiler, librarian and linker
CC := $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
AR := $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-ar
LD := $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
NM := $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-nm
CPP = $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-cpp
OBJCOPY = $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-objcopy
CCFLAGS += -Os -Wall -Wno-pointer-sign -fno-tree-ccp -mno-target-align -mno-serialize-volatile -foptimize-register-move
#
# -Wall -Wno-pointer-sign -mno-target-align -mno-serialize-volatile -foptimize-register-move
# -fomit-frame-pointer -fmerge-all-constants
#
# https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
# https://gcc.gnu.org/onlinedocs/gcc-4.8.2/gcc/Xtensa-Options.html#Xtensa-Options
#

FIRMWAREDIR := bin
DEFAULTBIN := ./$(FIRMWAREDIR)/esp_init_data_default.bin
DEFAULTADDR := 0x7C000
BLANKBIN := ./$(FIRMWAREDIR)/blank.bin
BLANKADDR := 0x7E000
CLREEPBIN := ./$(FIRMWAREDIR)/clear_eep.bin
CLREEPADDR := 0x79000

SDK_TOOLS ?= c:/Espressif/utils
#ESPTOOL		?= $(SDK_TOOLS)/esptool
CWD ?=$(PDIR)
PRJ_BASE := $(subst \,/,$(CWD))
ESPTOOL	?= C:/Python27/python.exe $(PRJ_BASE)esptool.py

CSRCS ?= $(wildcard *.c)
ASRCs ?= $(wildcard *.s)
ASRCS ?= $(wildcard *.S)
SUBDIRS ?= $(patsubst %/,%,$(dir $(wildcard */Makefile)))

ODIR := .output
OBJODIR := $(ODIR)/$(TARGET)/obj

OBJS := $(CSRCS:%.c=$(OBJODIR)/%.o) \
        $(ASRCs:%.s=$(OBJODIR)/%.o) \
        $(ASRCS:%.S=$(OBJODIR)/%.o)

DEPS := $(CSRCS:%.c=$(OBJODIR)/%.d) \
        $(ASRCs:%.s=$(OBJODIR)/%.d) \
        $(ASRCS:%.S=$(OBJODIR)/%.d)

LIBODIR := $(ODIR)/$(TARGET)/lib
OLIBS := $(GEN_LIBS:%=$(LIBODIR)/%)

IMAGEODIR := $(ODIR)/$(TARGET)/image
OIMAGES := $(GEN_IMAGES:%=$(IMAGEODIR)/%)

BINODIR := $(ODIR)/$(TARGET)/bin
OBINS := $(GEN_BINS:%=$(BINODIR)/%)

OUTBIN1 := ./$(FIRMWAREDIR)/$(ADDR_FW1).bin
OUTBIN2 := ./$(FIRMWAREDIR)/$(ADDR_FW2).bin

CCFLAGS += \
	-Wundef			\
	-Wpointer-arith	\
	-Werror	\
	-Wl,-EL	\
	-fno-inline-functions	\
	-nostdlib	\
	-mlongcalls	\
	-mtext-section-literals

CFLAGS = $(CCFLAGS) $(DEFINES) $(EXTRA_CCFLAGS) $(INCLUDES)
DFLAGS = $(CCFLAGS) $(DDEFINES) $(EXTRA_CCFLAGS) $(INCLUDES)

define ShortcutRule
$(1): .subdirs $(2)/$(1)
endef

define MakeLibrary
DEP_LIBS_$(1) = $$(foreach lib,$$(filter %.a,$$(COMPONENTS_$(1))),$$(dir $$(lib))$$(LIBODIR)/$$(notdir $$(lib)))
DEP_OBJS_$(1) = $$(foreach obj,$$(filter %.o,$$(COMPONENTS_$(1))),$$(dir $$(obj))$$(OBJODIR)/$$(notdir $$(obj)))
$$(LIBODIR)/$(1).a: $$(OBJS) $$(DEP_OBJS_$(1)) $$(DEP_LIBS_$(1)) $$(DEPENDS_$(1))
	@mkdir -p $$(LIBODIR)
	$$(if $$(filter %.a,$$?),mkdir -p $$(EXTRACT_DIR)_$(1))
	$$(if $$(filter %.a,$$?),cd $$(EXTRACT_DIR)_$(1); $$(foreach lib,$$(filter %.a,$$?),$$(AR) xo $$(UP_EXTRACT_DIR)/$$(lib);))
	$$(AR) ru $$@ $$(filter %.o,$$?) $$(if $$(filter %.a,$$?),$$(EXTRACT_DIR)_$(1)/*.o)
	$$(if $$(filter %.a,$$?),$$(RM) -r $$(EXTRACT_DIR)_$(1))
endef

define MakeImage
DEP_LIBS_$(1) = $$(foreach lib,$$(filter %.a,$$(COMPONENTS_$(1))),$$(dir $$(lib))$$(LIBODIR)/$$(notdir $$(lib)))
DEP_OBJS_$(1) = $$(foreach obj,$$(filter %.o,$$(COMPONENTS_$(1))),$$(dir $$(obj))$$(OBJODIR)/$$(notdir $$(obj)))
$$(IMAGEODIR)/$(1).out: $$(OBJS) $$(DEP_OBJS_$(1)) $$(DEP_LIBS_$(1)) $$(DEPENDS_$(1))
	@mkdir -p $$(IMAGEODIR)
	$$(CC) $$(LDFLAGS) $$(if $$(LINKFLAGS_$(1)),$$(LINKFLAGS_$(1)),$$(LINKFLAGS_DEFAULT) $$(OBJS) $$(DEP_OBJS_$(1)) $$(DEP_LIBS_$(1))) -o $$@
endef

$(BINODIR)/%.bin: $(IMAGEODIR)/%.out
	@mkdir -p ../$(FIRMWAREDIR)
	$(OBJCOPY) --only-section .lit4 -O binary $< ../$(FIRMWAREDIR)/addld.bin
	$(ESPTOOL) elf2image -o ../$(FIRMWAREDIR)/ $(GENIMAGEOPTION) $<
	$(ESPTOOL) image_info ../$(FIRMWAREDIR)/0x00000.bin
	@cp -f ../$(FIRMWAREDIR)/0x00000.bin ../$(FIRMWAREDIR)/rapid_loader.bin
	@dd if=../$(FIRMWAREDIR)/addld.bin >>../$(FIRMWAREDIR)/rapid_loader.bin
	
#	@dd if=../$(FIRMWAREDIR)/0x00000.bin bs=1 count=1 >../$(FIRMWAREDIR)/rapid_loader.bin
#	@dd if=/dev/zero bs=1 count=1 >>../$(FIRMWAREDIR)/rapid_loader.bin
#	@dd if=../$(FIRMWAREDIR)/0x00000.bin bs=1 skip=2 >>../$(FIRMWAREDIR)/rapid_loader.bin


all: .subdirs $(OBJS) $(OLIBS) $(OIMAGES) $(OBINS) $(SPECIAL_MKTARGETS)

clean:
	$(foreach d, $(SUBDIRS), $(MAKE) -C $(d) clean;)
	$(RM) -r $(ODIR)/$(TARGET)

clobber: $(SPECIAL_CLOBBER)
	$(foreach d, $(SUBDIRS), $(MAKE) -C $(d) clobber;)
	$(RM) -r $(ODIR)


.subdirs:
	@set -e; $(foreach d, $(SUBDIRS), $(MAKE) -C $(d);)

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),clobber)
ifdef DEPS
sinclude $(DEPS)
endif
endif
endif

$(OBJODIR)/%.o: %.c
	@mkdir -p $(OBJODIR);
	$(CC) $(if $(findstring $<,$(DSRCS)),$(DFLAGS),$(CFLAGS)) $(COPTS_$(*F)) -o $@ -c $<

$(OBJODIR)/%.d: %.c
	@mkdir -p $(OBJODIR);
	@echo DEPEND: $(CC) -M $(CFLAGS) $<
	@set -e; rm -f $@; \
	$(CC) -M $(CFLAGS) $< > $@.$$$$; \
	sed 's,\($*\.o\)[ :]*,$(OBJODIR)/\1 $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

$(OBJODIR)/%.o: %.s
	@mkdir -p $(OBJODIR);
	$(CC) $(CFLAGS) -o $@ -c $<

$(OBJODIR)/%.d: %.s
	@mkdir -p $(OBJODIR); \
	set -e; rm -f $@; \
	$(CC) -M $(CFLAGS) $< > $@.$$$$; \
	sed 's,\($*\.o\)[ :]*,$(OBJODIR)/\1 $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

$(OBJODIR)/%.o: %.S
	@mkdir -p $(OBJODIR);
	$(CC) $(CFLAGS) -D__ASSEMBLER__ -o $@ -c $<

$(OBJODIR)/%.d: %.S
	@mkdir -p $(OBJODIR); \
	set -e; rm -f $@; \
	$(CC) -M $(CFLAGS) $< > $@.$$$$; \
	sed 's,\($*\.o\)[ :]*,$(OBJODIR)/\1 $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

$(foreach lib,$(GEN_LIBS),$(eval $(call ShortcutRule,$(lib),$(LIBODIR))))

$(foreach image,$(GEN_IMAGES),$(eval $(call ShortcutRule,$(image),$(IMAGEODIR))))

$(foreach bin,$(GEN_BINS),$(eval $(call ShortcutRule,$(bin),$(BINODIR))))

$(foreach lib,$(GEN_LIBS),$(eval $(call MakeLibrary,$(basename $(lib)))))

$(foreach image,$(GEN_IMAGES),$(eval $(call MakeImage,$(basename $(image)))))

INCLUDES := $(INCLUDES) -I $(PDIR)include -I $(PDIR)include/$(TARGET)
#PDIR := ../$(PDIR)
#sinclude $(PDIR)Makefile
