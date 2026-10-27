require 'gpio'

led = GPIO.new(25, GPIO::OUT)
while true
  led.write(1); sleep_ms 500
  led.write(0); sleep_ms 500
end
