require 'adc'

pot = ADC.new(26)

while true
  puts pot.read_raw
  sleep_ms 200
end
