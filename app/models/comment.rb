class Comment < ApplicationRecord
  include SpamFilter::Util

  attr_accessor :request_url, :remote_ip, :referrer, :user_agent

  MAX_LEVEL = 15

  belongs_to :user
  belongs_to :commentable, polymorphic: true
  belongs_to :parent, class_name: 'Comment', optional: true
  has_many   :comments, class_name: 'Comment', foreign_key: :parent_id, dependent: :destroy

  before_validation :calculate_level, if: :parent_present?

  validate :validate_level

  after_create :update_child_count, if: :parent_present?
  after_create :update_comments_count
  after_commit :perform_spam_check, on: :create #, :if => :spam_filter_enabled?

  def calculate_level
    self.level = parent.level + 1
  end

  def validate_level
    if self.level > MAX_LEVEL
      self.errors.add(:level, :limit_reached, message: 'Maximum child limit reached')
      return false
    end
  end

  def update_child_count
    Comment.update_counters(parent.id, child_count: 1)
  end

  def update_comments_count
    commentable.class.update_counters(commentable.id, comments_count: 1)
  end

  private
    def parent_present?
      parent.present?
    end
end
