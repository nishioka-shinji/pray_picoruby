require 'gpio'
require 'pwm'

def delay_ms(ms)
  start = Time.now
  while true
    elapsed = Time.now - start
    break if elapsed * 1000 >= ms
  end
end

KEY_PINS = [20, 19, 18, 16]
NOTES = [262, 294, 330, 349]

keys = KEY_PINS.map { |pin| GPIO.new(pin, GPIO::IN | GPIO::PULL_UP) }
led = GPIO.new(17, GPIO::OUT)
buzzer = PWM.new(15, frequency: NOTES[0], duty: 0)

current = nil

while true
  pressed = nil
  i = 0
  while i < keys.size
    if keys[i].low?
      pressed = i
      break
    end
    i += 1
  end

  if pressed != current
    if pressed
      buzzer.frequency(NOTES[pressed])
      buzzer.duty(50)
      led.write(1)
    else
      buzzer.duty(0)
      led.write(0)
    end
    current = pressed
  end
  delay_ms 5
end
