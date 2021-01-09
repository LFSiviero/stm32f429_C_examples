# STM32 Makefile for GNU toolchain and openocd
#
# You need to have the STM32F4 SDK inside your home folder. Available at https://github.com/STMicroelectronics/STM32CubeF4
#
# Usage:
#	make all			Compile project
#	make program		Flash the board with OpenOCD
#	make openocd		Start OpenOCD
#	make debug			Start GDB and attach to OpenOCD
#
#
# Copyright	2015 Steffen Vogel, 2016 Roman Belkov
# License	http://www.gnu.org/licenses/gpl.txt GNU Public License
# Authors	Steffen Vogel <post@steffenvogel.de>
#           Roman Belkov  <roman.belkov@gmail.com>
# Link		http://www.steffenvogel.de


# A name common to all output files (elf, map, hex, bin, lst)
TARGET     = test

# Take a look into $(SDK_DIR)/Drivers/BSP for available BSPs
# name needed in upper case and lower case
BOARD      = STM32F429I-Discovery
BOARD_UC   = STM32F429I-Discovery
BOARD_LC   = stm32f429i_discovery
BSP_BASE   = $(BOARD_LC)

OCDFLAGS   = -f board/stm32f429discovery.cfg
GDBFLAGS   =

# MCU family and type in various capitalizations o_O
MCU_FAMILY 		= stm32f4xx
MCU_FAMILY_UC   = STM32F4xx
MCU_LC        	= stm32f429xx
MCU_MC	    	= STM32F429xx
MCU_UC 		    = STM32F429ZI

# linker file is inside project exemples
LDFILE     = $(SDK_DIR)/Projects/$(BOARD)/Templates/SW4STM32/STM32F429I_DISCO/$(MCU_UC)Tx_FLASH.ld

# startup file
START_ASM  = $(CMSIS_DIR)/Device/ST/$(MCU_FAMILY_UC)/Source/Templates/gcc/startup_$(MCU_LC).s

# Your C files from the /src directory
SRCS       = main.c
SRCS      += system_$(MCU_FAMILY).c
SRCS      += stm32f4xx_it.c

# Basic HAL libraries
SRCS      += stm32f4xx_hal_rcc.c stm32f4xx_hal_rcc_ex.c stm32f4xx_hal.c stm32f4xx_hal_cortex.c stm32f4xx_hal_gpio.c stm32f4xx_hal_pwr_ex.c $(BSP_BASE).c

# Directories
OCD_DIR    = /usr/share/openocd/scripts

SDK_DIR   = /home/$(USER)/STM32CubeF4

BSP_DIR    = $(SDK_DIR)/Drivers/BSP/$(BOARD_UC)
HAL_DIR    = $(SDK_DIR)/Drivers/STM32F4xx_HAL_Driver
CMSIS_DIR  = $(SDK_DIR)/Drivers/CMSIS

DEV_DIR    = $(CMSIS_DIR)/Device/ST/STM32F4xx

###############################################################################
# Toolchain

PREFIX     = arm-none-eabi
CC         = $(PREFIX)-gcc
AR         = $(PREFIX)-ar
OBJCOPY    = $(PREFIX)-objcopy
OBJDUMP    = $(PREFIX)-objdump
SIZE       = $(PREFIX)-size
GDB        = $(PREFIX)-gdb

OCD        = openocd

###############################################################################
# Options

# Defines
DEFS       = -D$(MCU_MC) -DUSE_HAL_DRIVER

# Debug specific definitions for semihosting
DEFS       += -DUSE_DBPRINTF

# Include search paths (-I)
INCS       = -Iinc
INCS      += -I$(BSP_DIR)
INCS      += -I$(CMSIS_DIR)/Include
INCS      += -I$(DEV_DIR)/Include
INCS      += -I$(HAL_DIR)/Inc

# Library search paths
LIBS       = -L$(CMSIS_DIR)/Lib

# Compiler flags
CFLAGS     = -Wall -g -std=c99 -Os
CFLAGS    += -mlittle-endian -mcpu=cortex-m4 -march=armv7e-m -mthumb
CFLAGS    += -mfpu=fpv4-sp-d16 -mfloat-abi=hard
CFLAGS    += -ffunction-sections -fdata-sections
CFLAGS    += $(INCS) $(DEFS)

# Linker flags
LDFLAGS    = -Wl,--gc-sections -Wl,-Map=$(TARGET).map $(LIBS) -T$(LDFILE)

# Enable Semihosting
LDFLAGS   += --specs=rdimon.specs -lc -lrdimon

# Source search paths
VPATH      = src
VPATH     += $(BSP_DIR)
VPATH     += $(HAL_DIR)/Src
VPATH     += $(DEV_DIR)/Source/

OBJS       = $(addprefix obj/,$(SRCS:.c=.o))
DEPS       = $(addprefix dep/,$(SRCS:.c=.d))

# Prettify output
V = 0
ifeq ($V, 0)
	Q = @
	P = > /dev/null
endif

###################################################

.PHONY: all dirs openocd program debug clean

all: $(TARGET).bin

-include $(DEPS)

dirs: dep obj
dep obj src:
	@echo "[MKDIR]   $@"
	$Qmkdir -p $@

obj/%.o : %.c | dirs
	@echo "[CC]      $(notdir $<)"
	@echo "$Q$(CC) $(CFLAGS) -c -o $@ $< -MMD -MF dep/$(*F).d"
	$Q$(CC) $(CFLAGS) -c -o $@ $< -MMD -MF dep/$(*F).d

$(TARGET).elf: $(OBJS)
	@echo "[LD]      $(TARGET).elf"
	$Q$(CC) $(CFLAGS) $(LDFLAGS) $(START_ASM) $^ -o $@
	@echo "[OBJDUMP] $(TARGET).lst"
	$Q$(OBJDUMP) -St $(TARGET).elf >$(TARGET).lst
	@echo "[SIZE]    $(TARGET).elf"
	$(SIZE) $(TARGET).elf

$(TARGET).bin: $(TARGET).elf
	@echo "[OBJCOPY] $(TARGET).bin"
	$Q$(OBJCOPY) -O binary $< $@

openocd:
	$(OCD) -s $(OCD_DIR) $(OCDFLAGS)

program: all
	$(OCD) -s $(OCD_DIR) $(OCDFLAGS) -c "program $(TARGET).elf verify reset"

debug:
	@if ! nc -z localhost 3333; then \
		echo "\n\t[Error] OpenOCD is not running! Start it with: 'make openocd'\n"; exit 1; \
	else \
		$(GDB)  -ex "target extended localhost:3333" \
			-ex "monitor arm semihosting enable" \
			-ex "monitor reset halt" \
			-ex "load" \
			-ex "monitor reset init" \
			$(GDBFLAGS) $(TARGET).elf; \
	fi

clean:
	@echo "[RM]      $(TARGET).bin"; rm -f $(TARGET).bin
	@echo "[RM]      $(TARGET).elf"; rm -f $(TARGET).elf
	@echo "[RM]      $(TARGET).map"; rm -f $(TARGET).map
	@echo "[RM]      $(TARGET).lst"; rm -f $(TARGET).lst
	@echo "[RMDIR]   dep"          ; rm -fr dep
	@echo "[RMDIR]   obj"          ; rm -fr obj