class BusPirate

  module Mode
    RESET   = 0
    SPI     = 1
    I2C     = 2
    UART    = 3
    ONEWIRE = 4
    RAWWIRE = 5
  end

  module PinMode
    OUTPUT = 0
    INPUT  = 1
  end

  module UART
    PIN_OUTPUT_HIZ  = 0b00000000
    PIN_OUTPUT_33V  = 0b00010000
    FORMAT_8N       = 0b00000000
    FORMAT_8E       = 0b00000100
    FORMAT_80       = 0b00001000
    FORMAT_9N       = 0b00001100
    STOPBITS_1      = 0b00000000
    STOPBITS_2      = 0b00000010
    IDLE_POLARITY_1 = 0b00000000
    IDLE_POLARITY_0 = 0b00000001
  end

  module SPI
    SPEED_30KHZ     = 0b00000000
    SPEED_125KHZ    = 0b00000001
    SPEED_250KHZ    = 0b00000010
    SPEED_1MHZ      = 0b00000011
    SPEED_2MHZ      = 0b00000100
    SPEED_2_6MHZ    = 0b00000101
    SPEED_4MHZ      = 0b00000110
    SPEED_8MHZ      = 0b00000111
    PIN_OUTPUT_HIZ  = 0b00000000
    PIN_OUTPUT_33V  = 0b00001000
    CLOCK_IDLE_LOW  = 0b00000000
    CLOCK_IDLE_HIGH = 0b00000100
    CLOCK_EDGE_IDLE_TO_ACTIVE = 0b00000000
    CLOCK_EDGE_ACTIVE_TO_IDLE = 0b00000010
    SAMPLE_TIME_MIDDLE = 0b00000000
    SAMPLE_TIME_END    = 0b00000001
  end

  FOSC = 32000000
  UART_CLOCK_DIVIDER = 2

end
