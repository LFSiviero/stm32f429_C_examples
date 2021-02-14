cmake_minimum_required(VERSION 3.13)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR ARM)
set(CMAKE_TOOLCHAIN_FILE /home/lfsiviero/Projects/stm32f429_C_examples/toolchain.cmake)

# set the project name and version
project(test VERSION 0.1)

# Take a look into $(SDK_DIR)/Drivers/BSP for available BSPs
# several capitalizations were needed beacuse of SDK files and folders structure
# name needed in upper case and lower case
set(BOARD_UC STM32F429I-Discovery)
set(BOARD_LC stm32f429i_discovery)
set(BSP_BASE ${BOARD_LC})

set(OCDFLAGS    -f board/stm32f429discovery.cfg)

# MCU family and type in various capitalizations o_O
set(MCU_FAMILY      stm32f4xx)
set(MCU_FAMILY_UC   STM32F4xx)
set(MCU_LC          stm32f429xx)
set(MCU_MC          STM32F429xx)
set(MCU_UC          STM32F429ZI)

# SDK Directories
set(OCD_DIR     /usr/share/openocd/scripts)
set(SDK_DIR     /home/lfsiviero/STM32CubeF4)
set(BSP_DIR     ${SDK_DIR}/Drivers/BSP/${BOARD_UC})
set(HAL_DIR     ${SDK_DIR}/Drivers/STM32F4xx_HAL_Driver)
set(CMSIS_DIR   ${SDK_DIR}/Drivers/CMSIS)
set(DEV_DIR     ${CMSIS_DIR}/Device/ST/STM32F4xx)
set(BUILD_DIR   ${PROJECT_SOURCE_DIR}/build)
set(CONFIG_DIR  ${PROJECT_SOURCE_DIR}/config)

# external libraries needed
set(halSources
        ${HAL_DIR}/Src/stm32f4xx_hal_rcc.c 
        ${HAL_DIR}/Src/stm32f4xx_hal_rcc_ex.c 
        ${HAL_DIR}/Src/stm32f4xx_hal.c 
        ${HAL_DIR}/Src/stm32f4xx_hal_cortex.c 
        ${HAL_DIR}/Src/stm32f4xx_hal_gpio.c 
        ${HAL_DIR}/Src/stm32f4xx_hal_pwr_ex.c 
        ${BSP_DIR}/${BSP_BASE}.c
)

# project source files
set(projectSources
        ${CMAKE_SOURCE_DIR}/src/main.c
        ${CMAKE_SOURCE_DIR}/src/stm32f4xx_it.c
        ${CMAKE_SOURCE_DIR}/src/system_stm32f4xx.c
)

# add the executable
set(EXECUTABLE ${PROJECT_NAME}.elf)
add_executable(${EXECUTABLE} ${projectSources} ${halSources})

# add the binary tree to the search path for include files
# so that we will find TutorialConfig.h
target_include_directories(${EXECUTABLE}
        PUBLIC
            ${CMAKE_SOURCE_DIR}/inc/
            ${BSP_DIR}
            ${CMSIS_DIR}/Include
            ${DEV_DIR}/Include
            ${HAL_DIR}/Inc
        )

# set commom flags needed for compile and linking options
# actually don't know why it is needed on both...
set(MCU_DEFINITION_FLAGS    -mlittle-endian -mcpu=cortex-m4 -march=armv7e-m)
set(MCU_LIBS_FLAGS          -mfloat-abi=hard -mfpu=fpv4-sp-d16)
set(MCU_DATA_SECTION_FLAGS  -ffunction-sections -fdata-sections)

# Compiler flags
target_compile_options(${EXECUTABLE}
        PRIVATE
            ${MCU_DEFINITION_FLAGS}
            ${MCU_LIBS_FLAGS}
            ${MCU_DATA_SECTION_FLAGS}
            -Wall 
            -std=c99 
            -Os
            -g
            -D${MCU_MC} 
            -DUSE_HAL_DRIVER 
            -DUSE_DBPRINTF
)

# set required file paths
set(startupFile ${CMSIS_DIR}/Device/ST/${MCU_FAMILY_UC}/Source/Templates/gcc/startup_${MCU_LC}.s)
set(linkerFile  ${SDK_DIR}/Projects/${BOARD_UC}/Templates/SW4STM32/STM32F429I_DISCO/${MCU_UC}Tx_FLASH.ld)

#linker flags
target_link_options(${EXECUTABLE}
        PRIVATE
            ${MCU_DEFINITION_FLAGS}
            ${MCU_LIBS_FLAGS}
            ${MCU_DATA_SECTION_FLAGS}
            -L${CMSIS_DIR}/Lib 
            -T${linkerFile}
            ${startupFile}
            # remove code not used and generate .map file
            -Wl,--gc-sections,-Map=${PROJECT_NAME}.map 
            # Enable Semihosting
            --specs=rdimon.specs -lc -lrdimon
        ) 

# show size after compile
add_custom_command(TARGET ${EXECUTABLE}
        POST_BUILD
            COMMAND ${CMAKE_SIZE_UTIL} ${EXECUTABLE}
        )

# generate .bin file
add_custom_command(TARGET ${EXECUTABLE}
        POST_BUILD
            COMMAND ${CMAKE_OBJCOPY} -O binary ${EXECUTABLE} ${PROJECT_NAME}.bin
        )

# Improve clean target
set_target_properties(${EXECUTABLE} 
        PROPERTIES ADDITIONAL_CLEAN_FILES
            "${PROJECT_NAME}.bin;${PROJECT_NAME}.map"
        )

# add flash command
add_custom_target(flash 
        DEPENDS ${EXECUTABLE}
            COMMAND openocd -s ${OCD_DIR} ${OCDFLAGS} -c "program ${EXECUTABLE} verify reset"
        )

add_custom_target(openocd
    COMMAND openocd -s ${OCD_DIR} ${OCDFLAGS}
)
