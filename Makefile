# STM32 Makefile for GNU toolchain and openocd
#
# Copyright	2013 Steffen Vogel
# License	http://www.gnu.org/licenses/gpl.txt GNU Public License
# Author	Steffen Vogel <post@steffenvogel.de>
# Link		http://www.steffenvogel.de
# 

# A name common to all output files (elf, map, hex, bin, lst)
TARGET     = demo

# Take a look into $(CUBE_DIR)/Drivers/BSP for available BSPs
BOARD      = STM32F3-Discovery
#BOARD     = STM32303C_EVAL
#BOARD     = STM32303E_EVAL
#BOARD     = STM32373C_EVAL
#BOARD     = STM32F302R8-Nucleo
#BOARD     = STM32F303RE-Nucleo
#BOARD     = STM32F3348-Discovery
#BOARD     = STM32F334R8-Nucleo
#BOARD     = STM32F3-Discovery
#BOARD     = Adafruit_Shield

OCDFLAGS   = -f board/stm32f3discovery.cfg
GDBFLAGS   = 

#EXAMPLE   = Templates
EXAMPLE    = Examples/GPIO/GPIO_IOToggle

# MCU family and type in various capitalizations o_O
MCU_FAMILY = stm32f3xx
MCU_LC     = stm32f303xc
MCU_MC     = STM32F303xC
MCU_UC     = STM32F303XC

# Your C files from the /src directory
SRCS       = main.c
SRCS      += system_$(MCU_FAMILY).c
SRCS      += stm32f3xx_it.c

SRCS      += stm32f3xx_hal_rcc.c
SRCS      += stm32f3xx_hal_rcc_ex.c
SRCS      += stm32f3xx_hal.c
SRCS      += stm32f3xx_hal_cortex.c
SRCS      += stm32f3xx_hal_gpio.c

CUBE_URL   = http://www.st.com/st-web-ui/static/active/en/st_prod_software_internet/resource/technical/software/firmware/stm32cubef3.zip
CUBE_DIR   = cube

BSP_DIR    = $(CUBE_DIR)/Drivers/BSP/$(BOARD)
HAL_DIR    = $(CUBE_DIR)/Drivers/STM32F3xx_HAL_Driver
CMSIS_DIR  = $(CUBE_DIR)/Drivers/CMSIS
DEV_DIR    = $(CMSIS_DIR)/Device/ST/STM32F3xx

# location of OpenOCD Board .cfg files (only used with 'make program')
OCD_DIR    = /usr/share/openocd/scripts/board

# that's it, no need to change anything below this line!

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
DEFS       = -D $(MCU_MC)

# Include search paths (-I)
INCS       = -I src
INCS      += -I $(BSP_DIR)
INCS      += -I $(CMSIS_DIR)/Include
INCS      += -I $(DEV_DIR)/Include
INCS      += -I $(HAL_DIR)/Inc

# Library search paths
LIBS       = -L $(CMSIS_DIR)/Lib

# Compiler flags
CFLAGS     = -Wall -g -std=c99 -Os
CFLAGS    += -mlittle-endian -mcpu=cortex-m4 -march=armv7e-m -mthumb
CFLAGS    += -mfpu=fpv4-sp-d16 -mfloat-abi=hard
CFLAGS    += -ffunction-sections -fdata-sections
CFLAGS    += $(INCS) $(DEFS)

# Linker flags
LDFLAGS    = -Wl,--gc-sections -Wl,-Map=$(TARGET).map $(LIBS) -T $(MCU_LC).ld

# Source search paths
VPATH      = ./src
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

.PHONY: all dirs program debug template clean

all: $(TARGET).elf

-include $(DEPS)

dirs: dep obj cube
dep obj src:
	@echo "[MKDIR]   $@"
	$Qmkdir -p $@

obj/%.o : %.c | dirs
	@echo "[CC]      $(notdir $<)"
	$Q$(CC) $(CFLAGS) -c -o $@ $< -MMD -MF dep/$(*F).d

$(TARGET).elf: $(OBJS)
	@echo "[LD]      $(TARGET).elf"
	$Q$(CC) $(CFLAGS) $(LDFLAGS) src/startup_$(MCU_LC).s $^ -o $@
	@echo "[OBJDUMP] $(TARGET).lst"
	$Q$(OBJDUMP) -St $(TARGET).elf >$(TARGET).lst
	@echo "[SIZE]    $(TARGET).elf"
	$(SIZE) $(TARGET).elf

program: all
	$(OCD) -c "program $(TARGET).elf verify reset" $(OCDFLAGS)

debug:
	$(GDB)  -ex "target remote | openocd $(OCDFLAGS) -c 'gdb_port pipe'" \
		-ex "monitor reset halt" \
		-ex "load" $(GDBFLAGS) $(TARGET).elf

cube:
	wget -O cube.zip $(CUBE_URL)
	unzip cube.zip
	mv STM32Cube* cube
	chmod -R u+w cube
	rm -f cube.zip

template: cube src
	cp -ri $(CUBE_DIR)/Projects/$(BOARD)/$(EXAMPLE)/Src/* src
	cp -ri $(CUBE_DIR)/Projects/$(BOARD)/$(EXAMPLE)/Inc/* src
	cp -i $(DEV_DIR)/Source/Templates/gcc/startup_$(MCU_LC).s src
	cp -i $(DEV_DIR)/Source/Templates/gcc/linker/$(MCU_UC)_FLASH.ld scripts/$(MCU_LC).ld

clean:
	@echo "[RM]      $(TARGET).elf"; rm -f $(TARGET).elf
	@echo "[RM]      $(TARGET).map"; rm -f $(TARGET).map
	@echo "[RM]      $(TARGET).lst"; rm -f $(TARGET).lst
	@echo "[RMDIR]   dep"          ; rm -fr dep
	@echo "[RMDIR]   obj"          ; rm -fr obj

