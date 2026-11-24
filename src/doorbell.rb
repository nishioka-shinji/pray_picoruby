require 'gpio'
require 'pwm'

def delay_ms(ms)
  start = Time.now
  while true
    elapsed = Time.now - start
    break if elapsed * 1000 >= ms
  end
end

def ring(buzzer, freq, ms)
  buzzer.frequency(freq)
  buzzer.duty(50)
  delay_ms ms
end

led = GPIO.new(17, GPIO::OUT)
button = GPIO.new(16, GPIO::IN | GPIO::PULL_UP)
buzzer = PWM.new(15, frequency: 659, duty: 0)

was_pressed = false

while true
  pressed = button.low?
  if pressed && !was_pressed
    led.write(1)
    ring(buzzer, 659, 400)
    ring(buzzer, 523, 700)
    buzzer.duty(0)
    led.write(0)
  end
  was_pressed = pressed
  delay_ms 20
end
