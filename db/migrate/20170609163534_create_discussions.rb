class CreateDiscussions < ActiveRecord::Migration[5.1]
  def change
    create_table :discussions do |t|
      t.text :title, null: false
      t.text :description, null: false
      t.references :user, index: true, foreign_key: true
      t.integer :upvotes_count, default: 0
      t.integer :downvotes_count, default: 0
      t.integer :posts_count, default: 0
      t.integer :comments_count, default: 0
      t.integer :follows_count, default: 0
      t.integer :views, default: 0
      t.float :score, default: 0
      t.boolean :pinned, default: false
      t.boolean :deleted, default: false
      t.boolean :spam, default: false

      t.timestamps    end
  end
end
