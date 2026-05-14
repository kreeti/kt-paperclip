# frozen_string_literal: true

require "spec_helper"
require "paperclip/schema"

describe Paperclip::Schema do
  before do
    rebuild_class
  end

  def assert_paperclip_deprecated(&block)
    warned = false
    callback = ->(message, *) { warned = true }
    old_behavior = Paperclip.deprecator.behavior
    old_silenced = Paperclip.deprecator.silenced
    Paperclip.deprecator.silenced = false
    Paperclip.deprecator.behavior = callback
    block.call
    expect(warned).to eq(true), "Expected a Paperclip deprecation warning but received none"
  ensure
    Paperclip.deprecator.behavior = old_behavior
    Paperclip.deprecator.silenced = old_silenced
  end

  after do
    begin
      ActiveRecord::Migration.drop_table :dummies
    rescue StandardError
      nil
    end
  end

  def expect_attachment_columns(columns, prefix = "avatar")
    expect(columns).to include(["#{prefix}_file_name", "varchar"])
    expect(columns).to include(["#{prefix}_content_type", "varchar"])
    expect(columns).to include(["#{prefix}_file_size", "bigint"])
    expect(columns.any? { |name, type| name == "#{prefix}_updated_at" && type.start_with?("datetime") }).to be true
  end

  def expect_no_attachment_columns(columns, prefix = "avatar")
    expect(columns.none? { |name, _| name.start_with?("#{prefix}_") }).to be true
  end

  context "within table definition" do
    context "using #has_attached_file" do
      it "creates attachment columns" do
        ActiveRecord::Migration.create_table :dummies, force: true do |t|
          Paperclip.deprecator.silence do
            t.has_attached_file :avatar
          end
        end

        columns = Dummy.columns.map { |column| [column.name, column.sql_type] }
        expect_attachment_columns(columns)
      end

      it "displays deprecation warning" do
        ActiveRecord::Migration.create_table :dummies, force: true do |t|
          assert_paperclip_deprecated do
            t.has_attached_file :avatar
          end
        end
      end
    end

    context "using #attachment" do
      before do
        ActiveRecord::Migration.create_table :dummies, force: true do |t|
          t.attachment :avatar
        end
      end

      it "creates attachment columns" do
        columns = Dummy.columns.map { |column| [column.name, column.sql_type] }
        expect_attachment_columns(columns)
      end
    end

    context "using #attachment with options" do
      before do
        ActiveRecord::Migration.create_table :dummies, force: true do |t|
          t.attachment :avatar, default: 1, file_name: { default: "default" }
        end
      end

      it "sets defaults on columns" do
        defaults_columns = ["avatar_file_name", "avatar_content_type", "avatar_file_size"]
        columns = Dummy.columns.select { |e| defaults_columns.include? e.name }

        expect(columns).to have_column("avatar_file_name").with_default("default")
        expect(columns).to have_column("avatar_content_type").with_default("1")
        expect(columns).to have_column("avatar_file_size").with_default(1)
      end
    end
  end

  context "within schema statement" do
    before do
      ActiveRecord::Migration.create_table :dummies, force: true
    end

    context "migrating up" do
      context "with single attachment" do
        before do
          ActiveRecord::Migration.add_attachment :dummies, :avatar
        end

        it "creates attachment columns" do
          columns = Dummy.columns.map { |column| [column.name, column.sql_type] }
          expect_attachment_columns(columns)
        end
      end

      context "with single attachment and options" do
        before do
          ActiveRecord::Migration.add_attachment :dummies, :avatar, default: "1", file_name: { default: "default" }
        end

        it "sets defaults on columns" do
          defaults_columns = ["avatar_file_name", "avatar_content_type", "avatar_file_size"]
          columns = Dummy.columns.select { |e| defaults_columns.include? e.name }

          expect(columns).to have_column("avatar_file_name").with_default("default")
          expect(columns).to have_column("avatar_content_type").with_default("1")
          expect(columns).to have_column("avatar_file_size").with_default(1)
        end
      end

      context "with multiple attachments" do
        before do
          ActiveRecord::Migration.add_attachment :dummies, :avatar, :photo
        end

        it "creates attachment columns" do
          columns = Dummy.columns.map { |column| [column.name, column.sql_type] }
          expect_attachment_columns(columns, "avatar")
          expect_attachment_columns(columns, "photo")
        end
      end

      context "with multiple attachments and options" do
        before do
          ActiveRecord::Migration.add_attachment :dummies, :avatar, :photo, default: "1", file_name: { default: "default" }
        end

        it "sets defaults on columns" do
          defaults_columns = ["avatar_file_name", "avatar_content_type", "avatar_file_size", "photo_file_name", "photo_content_type", "photo_file_size"]
          columns = Dummy.columns.select { |e| defaults_columns.include? e.name }

          expect(columns).to have_column("avatar_file_name").with_default("default")
          expect(columns).to have_column("avatar_content_type").with_default("1")
          expect(columns).to have_column("avatar_file_size").with_default(1)
          expect(columns).to have_column("photo_file_name").with_default("default")
          expect(columns).to have_column("photo_content_type").with_default("1")
          expect(columns).to have_column("photo_file_size").with_default(1)
        end
      end

      context "with no attachment" do
        it "raises an error" do
          assert_raises ArgumentError do
            ActiveRecord::Migration.add_attachment :dummies
          end
        end
      end
    end

    context "migrating down" do
      before do
        ActiveRecord::Migration.change_table :dummies do |t|
          t.column :avatar_file_name, :string
          t.column :avatar_content_type, :string
          t.column :avatar_file_size, :bigint
          t.column :avatar_updated_at, :datetime
        end
      end

      context "using #drop_attached_file" do
        it "removes the attachment columns" do
          Paperclip.deprecator.silence do
            ActiveRecord::Migration.drop_attached_file :dummies, :avatar
          end

          columns = Dummy.columns.map { |column| [column.name, column.sql_type] }
          expect_no_attachment_columns(columns)
        end

        it "displays a deprecation warning" do
          assert_paperclip_deprecated do
            ActiveRecord::Migration.drop_attached_file :dummies, :avatar
          end
        end
      end

      context "using #remove_attachment" do
        context "with single attachment" do
          before do
            ActiveRecord::Migration.remove_attachment :dummies, :avatar
          end

          it "removes the attachment columns" do
            columns = Dummy.columns.map { |column| [column.name, column.sql_type] }
            expect_no_attachment_columns(columns)
          end
        end

        context "with multiple attachments" do
          before do
            ActiveRecord::Migration.change_table :dummies do |t|
              t.column :photo_file_name, :string
              t.column :photo_content_type, :string
              t.column :photo_file_size, :bigint
              t.column :photo_updated_at, :datetime
            end

            ActiveRecord::Migration.remove_attachment :dummies, :avatar, :photo
          end

          it "removes the attachment columns" do
            columns = Dummy.columns.map { |column| [column.name, column.sql_type] }
            expect_no_attachment_columns(columns, "avatar")
            expect_no_attachment_columns(columns, "photo")
          end
        end

        context "with no attachment" do
          it "raises an error" do
            assert_raises ArgumentError do
              ActiveRecord::Migration.remove_attachment :dummies
            end
          end
        end
      end
    end
  end
end
