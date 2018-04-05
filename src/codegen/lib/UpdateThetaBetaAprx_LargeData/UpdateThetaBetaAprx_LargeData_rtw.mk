###########################################################################
## Makefile generated for MATLAB file/project 'UpdateThetaBetaAprx_LargeData'. 
## 
## Makefile     : UpdateThetaBetaAprx_LargeData_rtw.mk
## Generated on : Fri Nov 24 16:24:58 2017
## MATLAB Coder version: 3.3 (R2017a)
## 
## Build Info:
## 
## Final product: $(RELATIVE_PATH_TO_ANCHOR)/UpdateThetaBetaAprx_LargeData.a
## Product type : static-library
## 
###########################################################################

###########################################################################
## MACROS
###########################################################################

# Macro Descriptions:
# PRODUCT_NAME            Name of the system to build
# MAKEFILE                Name of this makefile
# COMPUTER                Computer type. See the MATLAB "computer" command.

PRODUCT_NAME              = UpdateThetaBetaAprx_LargeData
MAKEFILE                  = UpdateThetaBetaAprx_LargeData_rtw.mk
COMPUTER                  = MACI64
MATLAB_ROOT               = /Applications/MATLAB_R2017a.app
MATLAB_BIN                = /Applications/MATLAB_R2017a.app/bin
MATLAB_ARCH_BIN           = /Applications/MATLAB_R2017a.app/bin/maci64
MASTER_ANCHOR_DIR         = 
START_DIR                 = /Users/joshlukemire/repos/prerelease_hcica/src
ARCH                      = maci64
RELATIVE_PATH_TO_ANCHOR   = .
C_STANDARD_OPTS           = -fno-common -fexceptions
CPP_STANDARD_OPTS         = -fno-common -fexceptions

###########################################################################
## TOOLCHAIN SPECIFICATIONS
###########################################################################

# Toolchain Name:          Clang v3.1 | gmake (64-bit Mac)
# Supported Version(s):    3.1
# ToolchainInfo Version:   R2017a
# Specification Revision:  1.0
# 
#-------------------------------------------
# Macros assumed to be defined elsewhere
#-------------------------------------------

# C_STANDARD_OPTS
# CPP_STANDARD_OPTS

#-----------
# MACROS
#-----------

ARCHS             = x86_64
XCODE_SDK_VER     = $(shell perl $(MATLAB_ROOT)/rtw/c/tools/macsdkver.pl)
XCODE_SDK         = MacOSX$(XCODE_SDK_VER).sdk
XCODE_DEVEL_DIR   = $(shell xcode-select -print-path)
XCODE_SDK_ROOT    = $(XCODE_DEVEL_DIR)/Platforms/MacOSX.platform/Developer/SDKs/$(XCODE_SDK)

TOOLCHAIN_SRCS = 
TOOLCHAIN_INCS = 
TOOLCHAIN_LIBS = 

#------------------------
# BUILD TOOL COMMANDS
#------------------------

# C Compiler: Clang C Compiler
CC = xcrun clang

# Linker: Clang Linker
LD = xcrun clang

# C++ Compiler: Clang C++ Compiler
CPP = xcrun clang++

# C++ Linker: Clang C++ Linker
CPP_LD = xcrun clang++

# Archiver: Clang Archiver
AR = xcrun ar

# MEX Tool: MEX Tool
MEX_PATH = $(MATLAB_BIN)
MEX = "$(MEX_PATH)/mex"

# Download: Download
DOWNLOAD =

# Execute: Execute
EXECUTE = $(PRODUCT)

# Builder: GMAKE Utility
MAKE_PATH = %MATLAB%/bin/maci64
MAKE = "$(MAKE_PATH)/gmake"


#-------------------------
# Directives/Utilities
#-------------------------

CDEBUG              = -g
C_OUTPUT_FLAG       = -o
LDDEBUG             = -g
OUTPUT_FLAG         = -o
CPPDEBUG            = -g
CPP_OUTPUT_FLAG     = -o
CPPLDDEBUG          = -g
OUTPUT_FLAG         = -o
ARDEBUG             =
STATICLIB_OUTPUT_FLAG =
MEX_DEBUG           = -g
RM                  = @rm -f
ECHO                = @echo
MV                  = @mv
RUN                 =

#--------------------------------------
# "Faster Runs" Build Configuration
#--------------------------------------

ARFLAGS              = ruvs
CFLAGS               = -c -isysroot $(XCODE_SDK_ROOT) -arch $(ARCHS) $(C_STANDARD_OPTS) \
                       -O3
CPPFLAGS             = -c -isysroot $(XCODE_SDK_ROOT) -arch $(ARCHS) $(CPP_STANDARD_OPTS) \
                       -O3
CPP_LDFLAGS          = -arch $(ARCHS) -isysroot $(XCODE_SDK_ROOT) -Wl,-rpath,$(MATLAB_ARCH_BIN) -Wl,-rpath,@executable_path -Wl,-rpath,@executable_path/$(RELATIVE_PATH_TO_ANCHOR) -L"$(MATLAB_ARCH_BIN)"
CPP_SHAREDLIB_LDFLAGS  = -dynamiclib -install_name @rpath/$(notdir $(PRODUCT)) -isysroot $(XCODE_SDK_ROOT) -L"$(MATLAB_ARCH_BIN)" \
                         -Wl,$(LD_NAMESPACE) $(LD_UNDEFS)
DOWNLOAD_FLAGS       =
EXECUTE_FLAGS        =
LDFLAGS              = -arch $(ARCHS) -isysroot $(XCODE_SDK_ROOT) -Wl,-rpath,$(MATLAB_ARCH_BIN) -Wl,-rpath,@executable_path -Wl,-rpath,@executable_path/$(RELATIVE_PATH_TO_ANCHOR) -L"$(MATLAB_ARCH_BIN)"
MEX_CPPFLAGS         =
MEX_CPPLDFLAGS       =
MEX_CFLAGS           = -MATLAB_ARCH=$(ARCH) $(INCLUDES) \
                         \
                       COPTIMFLAGS="$(C_STANDARD_OPTS)  \
                       -O3 \
                        $(DEFINES)" \
                         \
                       -silent
MEX_LDFLAGS          = LDFLAGS=='$$LDFLAGS'
MAKE_FLAGS           = -f $(MAKEFILE)
SHAREDLIB_LDFLAGS    = -dynamiclib -install_name @rpath/$(notdir $(PRODUCT)) -isysroot $(XCODE_SDK_ROOT) -L"$(MATLAB_ARCH_BIN)" \
                       -Wl,$(LD_NAMESPACE) $(LD_UNDEFS)

#--------------------
# File extensions
#--------------------

H_EXT               = .h
OBJ_EXT             = .o
C_EXT               = .c
EXE_EXT             =
SHAREDLIB_EXT       = .dylib
HPP_EXT             = .hpp
OBJ_EXT             = .o
CPP_EXT             = .cpp
EXE_EXT             =
SHAREDLIB_EXT       = .dylib
STATICLIB_EXT       = .a
MEX_EXT             = .mexmaci64
MAKE_EXT            = .mk


###########################################################################
## OUTPUT INFO
###########################################################################

PRODUCT = $(RELATIVE_PATH_TO_ANCHOR)/UpdateThetaBetaAprx_LargeData.a
PRODUCT_TYPE = "static-library"
BUILD_TYPE = "Static Library"

###########################################################################
## INCLUDE PATHS
###########################################################################

INCLUDES_BUILDINFO = -I$(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData -I$(START_DIR) -I$(MATLAB_ROOT)/extern/include -I$(MATLAB_ROOT)/simulink/include -I$(MATLAB_ROOT)/rtw/c/src -I$(MATLAB_ROOT)/rtw/c/src/ext_mode/common -I$(MATLAB_ROOT)/rtw/c/ert

INCLUDES = $(INCLUDES_BUILDINFO)

###########################################################################
## DEFINES
###########################################################################

DEFINES_STANDARD = -DMODEL=UpdateThetaBetaAprx_LargeData -DHAVESTDIO -DUSE_RTMODEL -DUNIX

DEFINES = $(DEFINES_STANDARD)

###########################################################################
## SOURCE FILES
###########################################################################

SRCS = $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/UpdateThetaBetaAprx_LargeData_rtwutil.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/UpdateThetaBetaAprx_LargeData_initialize.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/UpdateThetaBetaAprx_LargeData_terminate.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/UpdateThetaBetaAprx_LargeData.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/eye.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/mrdivide.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/lusolve.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/colon.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/ixamax.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/rdivide.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/kron.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/diag.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/G_zv_gen.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/blkdiag.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/log.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/sum.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/sqrt.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/normpdf.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/xgeqp3.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/xnrm2.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/xzlarfg.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/xscal.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/xzlarf.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/squeeze.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/permute.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/mean.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/power.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/inv.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/norm.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/sqrtm.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/schur.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/xgehrd.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/xdhseqr.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/xdlanv2.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/xrot.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/trace.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/UpdateThetaBetaAprx_LargeData_emxutil.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/UpdateThetaBetaAprx_LargeData_emxAPI.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/rt_nonfinite.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/rtGetNaN.c $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/rtGetInf.c

ALL_SRCS = $(SRCS)

###########################################################################
## OBJECTS
###########################################################################

OBJS = UpdateThetaBetaAprx_LargeData_rtwutil.o UpdateThetaBetaAprx_LargeData_initialize.o UpdateThetaBetaAprx_LargeData_terminate.o UpdateThetaBetaAprx_LargeData.o eye.o mrdivide.o lusolve.o colon.o ixamax.o rdivide.o kron.o diag.o G_zv_gen.o blkdiag.o log.o sum.o sqrt.o normpdf.o xgeqp3.o xnrm2.o xzlarfg.o xscal.o xzlarf.o squeeze.o permute.o mean.o power.o inv.o norm.o sqrtm.o schur.o xgehrd.o xdhseqr.o xdlanv2.o xrot.o trace.o UpdateThetaBetaAprx_LargeData_emxutil.o UpdateThetaBetaAprx_LargeData_emxAPI.o rt_nonfinite.o rtGetNaN.o rtGetInf.o

ALL_OBJS = $(OBJS)

###########################################################################
## PREBUILT OBJECT FILES
###########################################################################

PREBUILT_OBJS = 

###########################################################################
## LIBRARIES
###########################################################################

LIBS = 

###########################################################################
## SYSTEM LIBRARIES
###########################################################################

SYSTEM_LIBS =  -lm

###########################################################################
## ADDITIONAL TOOLCHAIN FLAGS
###########################################################################

#---------------
# C Compiler
#---------------

CFLAGS_BASIC = $(DEFINES) $(INCLUDES)

CFLAGS += $(CFLAGS_BASIC)

#-----------------
# C++ Compiler
#-----------------

CPPFLAGS_BASIC = $(DEFINES) $(INCLUDES)

CPPFLAGS += $(CPPFLAGS_BASIC)

###########################################################################
## INLINED COMMANDS
###########################################################################

###########################################################################
## PHONY TARGETS
###########################################################################

.PHONY : all build clean info prebuild download execute


all : build
	@echo "### Successfully generated all binary outputs."


build : prebuild $(PRODUCT)


prebuild : 


download : build


execute : download


###########################################################################
## FINAL TARGET
###########################################################################

#---------------------------------
# Create a static library         
#---------------------------------

$(PRODUCT) : $(OBJS) $(PREBUILT_OBJS)
	@echo "### Creating static library "$(PRODUCT)" ..."
	$(AR) $(ARFLAGS)  $(PRODUCT) $(OBJS)
	@echo "### Created: $(PRODUCT)"


###########################################################################
## INTERMEDIATE TARGETS
###########################################################################

#---------------------
# SOURCE-TO-OBJECT
#---------------------

%.o : %.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.o : %.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.o : $(RELATIVE_PATH_TO_ANCHOR)/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.o : $(RELATIVE_PATH_TO_ANCHOR)/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.o : $(MATLAB_ROOT)/rtw/c/src/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.o : $(MATLAB_ROOT)/rtw/c/src/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.o : $(START_DIR)/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.o : $(START_DIR)/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.o : $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.o : $(START_DIR)/codegen/lib/UpdateThetaBetaAprx_LargeData/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


###########################################################################
## DEPENDENCIES
###########################################################################

$(ALL_OBJS) : $(MAKEFILE) rtw_proj.tmw


###########################################################################
## MISCELLANEOUS TARGETS
###########################################################################

info : 
	@echo "### PRODUCT = $(PRODUCT)"
	@echo "### PRODUCT_TYPE = $(PRODUCT_TYPE)"
	@echo "### BUILD_TYPE = $(BUILD_TYPE)"
	@echo "### INCLUDES = $(INCLUDES)"
	@echo "### DEFINES = $(DEFINES)"
	@echo "### ALL_SRCS = $(ALL_SRCS)"
	@echo "### ALL_OBJS = $(ALL_OBJS)"
	@echo "### LIBS = $(LIBS)"
	@echo "### MODELREF_LIBS = $(MODELREF_LIBS)"
	@echo "### SYSTEM_LIBS = $(SYSTEM_LIBS)"
	@echo "### TOOLCHAIN_LIBS = $(TOOLCHAIN_LIBS)"
	@echo "### CFLAGS = $(CFLAGS)"
	@echo "### LDFLAGS = $(LDFLAGS)"
	@echo "### SHAREDLIB_LDFLAGS = $(SHAREDLIB_LDFLAGS)"
	@echo "### CPPFLAGS = $(CPPFLAGS)"
	@echo "### CPP_LDFLAGS = $(CPP_LDFLAGS)"
	@echo "### CPP_SHAREDLIB_LDFLAGS = $(CPP_SHAREDLIB_LDFLAGS)"
	@echo "### ARFLAGS = $(ARFLAGS)"
	@echo "### MEX_CFLAGS = $(MEX_CFLAGS)"
	@echo "### MEX_CPPFLAGS = $(MEX_CPPFLAGS)"
	@echo "### MEX_LDFLAGS = $(MEX_LDFLAGS)"
	@echo "### MEX_CPPLDFLAGS = $(MEX_CPPLDFLAGS)"
	@echo "### DOWNLOAD_FLAGS = $(DOWNLOAD_FLAGS)"
	@echo "### EXECUTE_FLAGS = $(EXECUTE_FLAGS)"
	@echo "### MAKE_FLAGS = $(MAKE_FLAGS)"


clean : 
	$(ECHO) "### Deleting all derived files..."
	$(RM) $(PRODUCT)
	$(RM) $(ALL_OBJS)
	$(ECHO) "### Deleted all derived files."


