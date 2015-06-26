require 'test_helper'

# Tests the lib/brake.rb class.
class BrakeTest < ActiveSupport::TestCase

  def test_get_delay_time
    # Set some Brake constants so that changes there don't affect this test,
    # and so the the sleep periods do not slow down the tests too much.
    Brake.const_set(:RESET_TIME, 0.7)
    Brake.const_set(:MAX_SLEEP, 0.5)
    Brake.const_set(:INITIAL_SLEEP, 0.1)
    Brake.const_set(:SLEEP_MULITIPLIER, 1.3)
    Brake.const_set(:MIN_REQ_INTERVAL, 0.2)
    ip = '1.2.3.4'
    assert_equal(0, Brake.get_delay_time(ip), 'Initially the brake time should be '+
        'zero')
    sleep(Brake::MIN_REQ_INTERVAL + 0.01)
    assert_equal(0, Brake.get_delay_time(ip),
      'Delay should be zero after sleeping MIN_REQ_INTERVAL')
    delay = Brake.get_delay_time(ip)
    assert_equal(Brake::INITIAL_SLEEP, delay,
      'A second immediate request should return a delay of INITIAL_SLEEP')
    delay = Brake.get_delay_time(ip)
    assert_equal(Brake::INITIAL_SLEEP*Brake::SLEEP_MULITIPLIER, delay,
      'A third immediate request should return a longer delay')
    # Sleep the returned delay, or else the next request will be considered
    # to close to (actually prior to) the previous request.
    sleep(delay) # as get_delay_time expects the caller to do
    sleep(Brake::MIN_REQ_INTERVAL + 0.01)
    assert_equal(0, Brake.get_delay_time(ip),
      'Even when there is a delay in effect, there should be zero delay for '+
      'a request after MIN_REQ_INTERVAL')
    delay = Brake.get_delay_time(ip)
    assert_equal(Brake::INITIAL_SLEEP*Brake::SLEEP_MULITIPLIER*Brake::SLEEP_MULITIPLIER,
      delay,
      'A too-rapid request after a good request should increase the delay')
    # Confirm that the delay has a maximum
    1.upto(5).each {delay = Brake.get_delay_time(ip)}
    assert_equal(Brake::MAX_SLEEP, delay, 'Delay value should not exceed MAX_SLEEP')
    # Issue only good requests until the reset time has elapsed.
    sleep(delay)
    1.upto((Brake::RESET_TIME/Brake::INITIAL_SLEEP).to_i).each do
      sleep(Brake::MIN_REQ_INTERVAL + 0.01)
      assert_equal(0, Brake.get_delay_time(ip))
    end
    assert_equal(Brake::INITIAL_SLEEP, Brake.get_delay_time(ip),
      'After the reset time has elapsed since the last penalty (not since the '+
      'last request), the next penalty should be INITIAL_SLEEP')
  end
end
