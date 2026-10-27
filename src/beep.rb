require 'pwm'

# sleep / sleep_ms 中は PWM の音が乱れるため busy loop で待つ
def delay_ms(ms)
  start = Time.now
  while true
    elapsed = Time.now - start
    break if elapsed * 1000 >= ms
  end
end

# ドレミファソラシド
NOTES = [262, 294, 330, 349, 392, 440, 494, 523]

buzzer = PWM.new(15, frequency: NOTES[0], duty: 0)
NOTES.each do |freq|
  buzzer.frequency(freq)
  buzzer.duty(50); delay_ms 300
  buzzer.duty(0); delay_ms 50
end
