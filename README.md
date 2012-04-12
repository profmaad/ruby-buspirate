# ruby-buspirate - Ruby interface to Bus Pirate (via binary mode)

## Description

Ruby class (and gem in the future) to access [The Bus Pirate](http://dangerousprototypes.com/docs/Bus_Pirate) in binary mode

## Features

 * all "basic" features
 * UART mode
 * SPI mode
 * all other modes are missing (but will be implemented soon'ish)

Tested on Linux and OSX (should on windoze if seriaport does).


## Use

Create a BusPirate instance:

    require 'buspirate'

    pirate = BusPirate.new('/dev/port', bauds, bits, stopbit, parity)

Linux example (115200b 8-N-1):

    pirate = BusPirate.new('/dev/ttyACM0')

Select Mode:

    Mode::SPI
    Mode::I2C
    Mode::UART
    Mode::ONEWIRE
    Mode::RAWWIRE

    pirate.switch_mode(BusPirate::Mode::XXX)


Have fun!

## Dependencies

 * serialport
 * a Bus Pirate ^^

## License

Copyright (c) 2011, *Prof. MAAD* aka Max Wolter
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
