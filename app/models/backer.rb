# == Schema Information
#
# Table name: backers
#
#  id               :integer(4)      not null, primary key
#  project_id       :integer(4)      not null
#  user_id          :integer(4)      not null
#  reward_id        :integer(4)
#  value            :integer(10)     not null
#  confirmed        :boolean(1)      default(FALSE), not null
#  confirmed_at     :datetime
#  created_at       :datetime
#  updated_at       :datetime
#  display_notice   :boolean(1)      default(FALSE)
#  anonymous        :boolean(1)      default(FALSE)
#  key              :integer(4)
#  can_refund       :boolean(1)      default(FALSE)
#  requested_refund :boolean(1)      default(FALSE)
#  refunded         :boolean(1)      default(FALSE)
#  credits          :boolean(1)      default(FALSE)
#  notified_finish  :boolean(1)      default(FALSE)
#  site_id          :integer(4)      default(1), not null
#

# coding: utf-8
class Backer < ActiveRecord::Base
  
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::DateHelper
  
  belongs_to :project
  belongs_to :user
  belongs_to :reward
  belongs_to :site
  
  validates_presence_of :project, :user, :value, :site
  validates_numericality_of :value, :greater_than_or_equal_to => 10.00
  validate :reward_must_be_from_project
  
  scope :anonymous, where(:anonymous => true)
  scope :not_anonymous, where(:anonymous => false)
  scope :confirmed, where(:confirmed => true)
  scope :pending, where(:confirmed => false)
  scope :display_notice, where(:display_notice => true)
  scope :can_refund, where(:can_refund => true)
  scope :within_refund_deadline, where("current_timestamp < (created_at + interval '180 days')")
  
  def self.project_visible(site)
    joins(:project).joins("INNER JOIN projects_sites ON projects_sites.project_id = projects.id").where("projects_sites.site_id = #{site.id} AND projects_sites.visible = true")
  end
  
  after_create :define_key
  
  def define_key
    self.update_attribute :key, Digest::MD5.new.update("#{self.id}###{self.created_at}###{Kernel.rand}").to_s
  end
  
  before_save :confirm?
  
  def confirm?
    if confirmed and confirmed_at.nil?
      self.confirmed_at = Time.now
      self.display_notice = true
    end
  end
  
  def confirm!
    update_attribute :confirmed, true
  end
  
  def reward_must_be_from_project
    return unless reward
    errors.add(:reward, I18n.t('backer.reward_must_be_from_project')) unless reward.project == project
  end
  
  validate :value_must_be_at_least_rewards_value
  
  def value_must_be_at_least_rewards_value
    return unless reward
    errors.add(:value, I18n.t('backer.value_must_be_at_least_rewards_value', :minimum_value => reward.display_minimum)) unless value >= reward.minimum_value
  end
  
  validate :should_not_back_if_maximum_backers_been_reached, :on => :create
  
  def should_not_back_if_maximum_backers_been_reached
    return unless reward and reward.maximum_backers and reward.maximum_backers > 0
    errors.add(:reward, I18n.t('backer.should_not_back_if_maximum_backers_been_reached')) unless reward.backers.confirmed.count < reward.maximum_backers
  end
  
  def display_value
    number_to_currency value, :local => I18n.locale
  end
  
  def display_confirmed_at
    I18n.l(confirmed_at.to_date) if confirmed_at
  end
  
  def moip_value
    "%0.0f" % (value * 100)
  end
  
  def generate_credits!
    return if self.can_refund
    self.user.update_attribute :credits, self.user.credits + self.value
    self.update_attribute :can_refund, true
  end
  
  def refund_deadline
    created_at + 180.days
  end
  
  def as_json(options={})
    {
      :id => id,
      :anonymous => anonymous,
      :confirmed => confirmed,
      :confirmed_at => display_confirmed_at,
      :display_value => display_value,
      :user => user,
      :reward => reward
    }
  end
  
end
