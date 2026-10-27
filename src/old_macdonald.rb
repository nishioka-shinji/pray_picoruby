require 'pwm'

# sleep / sleep_ms 中は PWM の音が乱れるため busy loop で待つ
def delay_ms(ms)
  start = Time.now
  while true
    elapsed = Time.now - start
    break if elapsed * 1000 >= ms
  end
end

BEAT_MS = 350
SO3 = 196; RA3 = 220; DO = 262; RE = 294; MI = 330

# ゆかいな牧場（Old MacDonald Had a Farm）。[周波数, 拍数]
EIEIO = [[MI, 1], [MI, 1], [RE, 1], [RE, 1], [DO, 3]]
MELODY =
  [[DO, 1], [DO, 1], [DO, 1], [SO3, 1], [RA3, 1], [RA3, 1], [SO3, 2]] + EIEIO +
  [[SO3, 1], [DO, 1], [DO, 1], [DO, 1], [SO3, 1], [RA3, 1], [RA3, 1], [SO3, 2]] + EIEIO

buzzer = PWM.new(15, frequency: DO, duty: 0)
MELODY.each do |freq, beats|
  buzzer.frequency(freq)
  buzzer.duty(50); delay_ms BEAT_MS * beats - 40
  buzzer.duty(0); delay_ms 40
end
