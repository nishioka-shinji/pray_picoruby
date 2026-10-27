require 'pwm'

# sleep / sleep_ms 中は PWM の音が乱れるため busy loop で待つ
def delay_ms(ms)
  start = Time.now
  while true
    elapsed = Time.now - start
    break if elapsed * 1000 >= ms
  end
end

# 上のブザー（GP15）でソを 1 秒鳴らす
buzzer = PWM.new(15, frequency: 392, duty: 50)
delay_ms 1000
buzzer.duty(0)
