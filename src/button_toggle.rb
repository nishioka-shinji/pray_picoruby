require 'gpio'

led = GPIO.new(17, GPIO::OUT)
button = GPIO.new(16, GPIO::IN | GPIO::PULL_UP)

on = false
was_pressed = false

while true
  pressed = button.low?
  if pressed && !was_pressed
    on = !on
    led.write(on ? 1 : 0)
  end
  was_pressed = pressed
  sleep_ms 20
end
