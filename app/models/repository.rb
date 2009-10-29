require 'gitosis_config'

class Repository < ActiveRecord::Base

  has_many :public_keys, :through => :permissions
  has_many :permissions

  validates_uniqueness_of :name
  validates_format_of :name, :with => %r{^[a-z]+[0-9a-z_]+$} # repository name may only contain lowercase letters, numbers and underscores
  validates_format_of :email, :with => %r{^(?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i 

  before_save :save_config
  after_destroy :remove_from_config

  def remote_git_repository_url
    configatron.remote_git_repository+":#{self.name}.git"
  end

  def public_key_filenames
    self.public_keys.collect(&:keyfilename).join(' ')
  end

private

  def save_config
    if self.new_record?
      # add new group
      logger.info("Adding new repository #{self.name}")
      @config ||= GitosisConfig.new
      @config.add_group(self.name)
      @config.add_to_group(self.name, 'writable', self.name)
      @config.save
    elsif self.name_changed?
      # rename group (delete old, add new)
      logger.info("Removing repository #{self.name_was}")
      logger.info("Adding new repository #{self.name}")
      @config ||= GitosisConfig.new
      @config.remove_group(self.name_was)
      @config.add_group(self.name)
      @config.add_to_group(self.name, 'writable', self.name)
      @config.save
    end
  end

  def remove_from_config
    logger.info("Removing repository #{self.name}")
    @config ||= GitosisConfig.new
    @config.remove_group(self.name)
    @config.save
  end

end
