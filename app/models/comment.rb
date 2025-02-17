# == Schema Information
#
# Table name: comments
#
#  id               :integer(4)      not null, primary key
#  title            :text
#  comment          :text            default(""), not null
#  comment_html     :text
#  commentable_id   :integer(4)      not null
#  commentable_type :string(255)     not null
#  user_id          :integer(4)      not null
#  project_update   :boolean(1)      default(FALSE)
#  created_at       :datetime
#  updated_at       :datetime
#

class Comment < ActiveRecord::Base

  include ActionView::Helpers::DateHelper
  include ActsAsCommentable::Comment

  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  
  validates_presence_of :comment, :commentable, :user

  acts_as_commentable

  auto_html_for :comment do
    html_escape :map => { 
      '&' => '&amp;',  
      '>' => '&gt;',
      '<' => '&lt;',
      '"' => '"' }
    redcloth :target => :_blank
    image
    youtube :width => 580, :height => 378
    vimeo :width => 580, :height => 378
    link :target => :_blank
  end
    
  def display_time
    I18n.t('comment.display_time', :time_ago => time_ago_in_words(created_at))
  end
  
  def as_json(options={})
    {
      :id => id,
      :user => user,
      :display_time => display_time,
      :title => title,
      :html => comment_html
    }
  end
  
end
