require 'pwm'

# sleep / sleep_ms 中は PWM の音が乱れるため busy loop で待つ
def delay_ms(ms)
  start = Time.now
  while true
    elapsed = Time.now - start
    break if elapsed * 1000 >= ms
  end
end

# バッハ「トッカータとフーガ ニ短調」冒頭。原曲どおり 1 オクターブ下でもう一度繰り返す
# [周波数, ミリ秒]、周波数 nil は休符
PHRASE = [
  [440, 90], [392, 90], [440, 1100], [nil, 350],
  [392, 110], [349, 110], [330, 110], [294, 110],
  [277, 500], [294, 1400], [nil, 700]
]
LOW_PHRASE = PHRASE.map { |freq, ms| [freq && freq / 2, ms] }

buzzer = PWM.new(15, frequency: 440, duty: 0)
(PHRASE + LOW_PHRASE).each do |freq, ms|
  if freq.nil?
    delay_ms ms
    next
  end
  buzzer.frequency(freq)
  buzzer.duty(50); delay_ms ms - 15
  buzzer.duty(0); delay_ms 15
end
