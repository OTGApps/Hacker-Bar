class Machine

  def self.tracking_data
    @tracking_data ||= {
      app: App.identifier,
      version: App.version,
      locale: NSLocale.preferredLanguages.first,
      serial: Machine.unique_id
    }
  end

  def self.unique_id
    u = UniqueIdentifier.new
    u.uniqueIdentifier
  end

end
