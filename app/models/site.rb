# == Schema Information
#
# Table name: sites
#
#  id           :integer(4)      not null, primary key
#  name         :text            default(""), not null
#  title        :text            default(""), not null
#  path         :text            default(""), not null
#  host         :text            default(""), not null
#  gender       :text            default(""), not null
#  email        :text            default(""), not null
#  twitter      :text            default(""), not null
#  facebook     :text            default(""), not null
#  blog         :text            default(""), not null
#  created_at   :datetime
#  updated_at   :datetime
#  auth_gateway :boolean(1)      default(FALSE), not null
#  port         :text
#

# coding: utf-8
class Site < ActiveRecord::Base
  
  validates_presence_of :name, :title, :path, :host
  validates_uniqueness_of :name, :path, :host
  
  has_many :projects
  has_many :projects_sites
  has_many :present_projects, :through => :projects_sites, :source => :project
  has_many :backers
  has_many :users
  
  def self.auth_gateway
    where(:auth_gateway => true).first
  end
  
  def full_url(path = "")
    "http://#{host}#{port ? ":#{port}" : ""}#{path}"
  end

  def the(capitalize = false)
    if gender == "male"
      text = I18n.t('site.male.the')
    elsif gender == "female"
      text = I18n.t('site.female.the')
    end
    text.capitalize! if capitalize
    text
  end
  
  def the_name(capitalize = false)
    "#{the(capitalize)} #{name}".strip
  end
  
  def in_the
    if gender == "male"
      text = I18n.t('site.male.in_the')
    elsif gender == "female"
      text = I18n.t('site.female.in_the')
    end
    text
  end
  
  def in_the_name
    "#{in_the} #{name}".strip
  end
  
  def in_the_twitter
    "#{in_the} @#{twitter}".strip
  end
  
  def to_the
    if gender == "male"
      text = I18n.t('site.male.to_the')
    elsif gender == "female"
      text = I18n.t('site.female.to_the')
    end
  end
  
  def to_the_name
    "#{to_the} #{name}".strip
  end
  
end
