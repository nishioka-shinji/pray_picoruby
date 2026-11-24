require 'gpio'
require 'pwm'
require 'adc'

def delay_ms(ms)
  start = Time.now
  while true
    elapsed = Time.now - start
    break if elapsed * 1000 >= ms
  end
end

KEY_PINS = [20, 19, 18, 16]
BANKS = [
  [262, 294, 330, 349],
  [330, 349, 392, 440]
]

keys = KEY_PINS.map { |pin| GPIO.new(pin, GPIO::IN | GPIO::PULL_UP) }
led = GPIO.new(17, GPIO::OUT)
buzzer = PWM.new(15, frequency: BANKS[0][0], duty: 0)
pot = ADC.new(26)

bank = 0
current = nil
current_freq = 0

while true
  raw = pot.read_raw
  if bank == 0 && raw > 2300
    bank = 1
  elsif bank == 1 && raw < 1800
    bank = 0
  end

  pressed = nil
  i = 0
  while i < keys.size
    if keys[i].low?
      pressed = i
      break
    end
    i += 1
  end

  if pressed
    freq = BANKS[bank][pressed]
    if pressed != current || freq != current_freq
      buzzer.frequency(freq)
      buzzer.duty(50)
      led.write(1)
      current_freq = freq
    end
  elsif current
    buzzer.duty(0)
    led.write(0)
    current_freq = 0
  end
  current = pressed
  delay_ms 5
end
