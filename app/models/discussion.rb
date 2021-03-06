class Discussion < ApplicationRecord
  include SpamFilter::Util
  include Sentiment::Util
  include Search::Searchable

  attr_accessor :request_url, :remote_ip, :referrer, :user_agent, :model_changes

  searchkick callbacks: false, similarity: 'LMJelinekMercer'

  validates_presence_of :title

  belongs_to :user
  belongs_to :category, optional: true
  has_many :answers
  has_many :discussion_tags
  has_many :tags, through: :discussion_tags
  has_many :notifications

  before_save :set_model_changes # For search to get the model changes after_commit

  after_save :update_reports_data
  after_commit :perform_spam_check, on: :create # , :if => :spam_filter_enabled?
  after_commit :perform_sentiment_analyze, on: :create # , :if => :sentiment_analyze_enabled?

  def content
    "#{title} #{description_text}"
  end

  def description_text
    Sanitize.clean(description)
  end

  def view_count
    MetaInfo::ViewCount.new(viewable_id: id, viewable_type: 'discussion').count
  end

  def add_tags(tag_names)
    self.model_changes = [:tags]
    tag_names.each do |tag_name|
      tags << Tag.find_or_create_by_name(tag_name)
    end
  end

  def remove_tags(tag_names)
    self.model_changes = [:tags]
    tag_names.each do |tag_name|
      tag = Tag.find_by_name(tag_name)
      discussion_tags.where(tag_id: tag.id).first.destroy
    end
  end

  def tag_names
    tags.map(&:name)
  end

  def update_reports_data
    Reports::Data.update_spammed_count(spam) if saved_change_to_attribute?(:spam)
    Reports::Data.update_unpublished_count(!published) if saved_change_to_attribute?(:published)
  end

  def set_model_changes
    self.model_changes ||= []
    self.model_changes += changes.keys.map(&:to_sym) if changes.present?
  end

  def search_data
    es_document_payload
  end

  def es_document_payload
    payload_hash = {}
    DiscussionConstants::ES_INDEX_COLUMNS.each do |column|
      column_value = send(column)
      if column_value.class.to_s == 'Tag::ActiveRecord_Associations_CollectionProxy'
        tags_arr = []
        column_value.each do |value|
          tags_arr << value.name
        end
        payload_hash.merge!(column => tags_arr)
      else
        payload_hash.merge!(column => column_value)
      end
    end
    payload_hash
  end

  def check_model_changes
    (DiscussionConstants::ES_INDEX_COLUMNS - self.model_changes).present?
  end
end
