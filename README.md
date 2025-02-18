All heavy lifting was done by FixedBit-san, Makapoo-san, and who they worked with in the repo history
This is just a clone with my lazy updates mainly on builtin.txt and builtin_txt.cc
Please see the original repo - [FixedBit/lslint](https://github.com/FixedBit/lslint)

#### Compiling
* Install [Visual Studio 2022](https://visualstudio.microsoft.com/ja/vs/community/) and C++ Desktop Environment using the VS installer
* Install [Win flex-bison](http://sourceforge.net/projects/winflexbison/) to C:\flexandbison
* Open Visual Studio Command Prompt, cd to the local repo root folder, and run the creator_win64.bat
* The updated binary lslint.exe should be created in binary\windows64 subfolder when successful

#### License
All code is public domain unless otherwise noted.
LSL scripts are from various sources and the property of their respective owners.
`.l` and `.y` files are based on samples provided by Linden Lab.

**WARNING:** `lslint` faithfully reproduced all the quirks of the LSL compiler circa ~2006,
like having constants as lexer tokens, events as part of the parser grammar,
and lots of right recursions. From a compiler perspective, it does everything
wrong and is not recommended as a base for anything but a lint tool.

#### Additional changes
##### Otoa
* updated the creator_win64.bat to use VSCode 2022 (I did not touch any other build scripts... sorry)
* updated builtins.txt and builtins_txt.cc with Second Life Server 2024-12-17 
  
##### Makopoppo
* added nmake support (see NMAkefile for details).
* dropped builtins.txt creator. if you look for new builtins.txt, see [kwdb project](https://github.com/Sei-Lisa/kwdb)
* enabled appending the input file path to the result lines by "-p".

##### Xenhat
* Makefile-less VS2022 support (more cpp hybridization was necessary)
    * Side effects includes x86_64 binary, x86 is possible still

##### Sei-Lisa
* added Mono mode (-m for Mono(default), -m- for LSO)
* added option to make the warning on unused event parameters optional (-u to enable, -u- to disable)
* added option to ignore preprocessor commands (-i)
* added switch() statement and lazy list support
* added god mode support
* added reporting of several errors and warnings
* numerous bug fixes and enhancements

##### FixedBit
* updated and cleaned up compile for all languages

#### Special Thanks
* Strife Onizuka
* Howie Lament
* Cory Linden
* Huns Valen
* Doran Zemlja / Adam Wozniak

#### Shout Outs
* Daniel Linden
* Bakuzelas Khan
* One Song
* Otacon Falcone
* Shokra Patel
