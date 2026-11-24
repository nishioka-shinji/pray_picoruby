require 'gpio'

led = GPIO.new(17, GPIO::OUT)
button = GPIO.new(16, GPIO::IN | GPIO::PULL_UP)

while true
  led.write(button.low? ? 1 : 0)
  sleep_ms 10
end
