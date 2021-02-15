# stm32f429_C_examples
Just a basic setup to code, compile and debug using VSCode and STM32 HAL libraries in a linux environment.

## Target
This program is targeted as STM32F429 Discovery board, however can be applied to any ST MCU by modifing some defines and using the correct ST files.

## Getting Started
First install all dependencies:

#### GNU ARM Embedded Toolchain
Can be downloaded for debian based distros by clicking in this [blue words](https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2?revision=ca0cbf9c-9de2-491c-ac48-898b5bbc0443&la=en&hash=68760A8AE66026BCF99F05AC017A6A50C6FD832A), if you use other platform please check their [website](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads). I strongly recommend installing from link because the one available in apt repository does not have gdb.

#### Open OCD
Used to program and debug, the one at opt repository works with ST-link out of the box.
```
$ sudo apt install openocd
```
Supported board files are located in `usr/shared/openocd/boards`

#### STM32F4 SDK
This one can be obtained either using STMCube or just clone [ST Repository](https://github.com/STMicroelectronics/STM32CubeF4). I recommend taking a look into these folders to find the correct path for your board/MCU files, it may not be as straightfoward as it seems.

## Running
First check all paths on toolchain.cmake and CMakeLists.txt to make sure it points to whatever folder you chose to install. In my case SDK was in `home` folder and toolchain was in `/opt`.
Once paths are correct, create a build folder inside project root and build.
```
$ mkdir build
$ cd build
$ cmake ..
$ make
```
If everything is OK it should compile and generate a test.elf file. Just run `make program` and it should flash the MCU connected to your PC.
For now it just toggle green led whenever you press user button.
