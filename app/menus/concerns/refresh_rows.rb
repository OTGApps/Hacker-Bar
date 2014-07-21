module RefreshRows

  def refresh_sections
    refresh_rows << {title: last_check_words}
  end

  def refresh_rows
    [
      ['5 minutes', 300],
      ['10 Minutes', 600],
      ['30 minutes', 1800],
      ['1 hour', 3600],
      ['2 hours', 7200]
    ].map do |t|
      if App::Persistence['check_interval'] == t[1]
        {
          title: t[0],
          checked: true,
        }
      else
        {
          title: t[0],
          target: self,
          action: 'update_refresh_interval:',
          object: t[1]
        }
      end
    end
  end

  def last_check_words
    'Server checked ' << last_check
  end

  def last_check
    check = App::Persistence['last_check'].to_i
    return '- Unknown' if check == 0
    Time.at(check).distanceOfTimeInWords
  end

  def update_refresh_interval(sender)
    @update_timer.invalidate unless @update_timer.nil? # Invalidate the current timer.

    # Update the defaults setting for the check interval
    previous_time = App::Persistence['check_interval']
    App::Persistence['check_interval'] = sender.object
    App.delegate.main_menu.build_menu

    Mixpanel.sharedInstance.track('Update Fetch Interval', properties: {
      from: previous_time,
      to: time
    }) unless BW.debug?

    # Restart the timer
    start_update_timer
  end
end
