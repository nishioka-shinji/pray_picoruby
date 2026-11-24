require 'gpio'
require 'pwm'

def delay_ms(ms)
  start = Time.now
  while true
    elapsed = Time.now - start
    break if elapsed * 1000 >= ms
  end
end

led = GPIO.new(17, GPIO::OUT)
button = GPIO.new(16, GPIO::IN | GPIO::PULL_UP)
buzzer = PWM.new(15, frequency: 440, duty: 0)

was_pressed = false

while true
  pressed = button.low?
  if pressed != was_pressed
    buzzer.duty(pressed ? 50 : 0)
    led.write(pressed ? 1 : 0)
    was_pressed = pressed
  end
  delay_ms 10
end
