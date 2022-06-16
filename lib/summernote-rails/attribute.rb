module SummernoteRails
  module Rails
    module Attribute
      extend ActiveSupport::Concern

      class_methods do
        # https://github.com/rails/rails/blob/b961af3345fe2f9e492ba1e5424c2ceb75ac6ead/actiontext/lib/action_text/attribute.rb#L4
        # https://github.com/rails/rails/blob/b961af3345fe2f9e492ba1e5424c2ceb75ac6ead/actiontext/lib/action_text/content.rb#L121
        def has_summernote(name)
          serialize :"#{name}", ActionText::Content

          has_many_attached :"#{name}_summernote_embeds"
          before_save :"update_#{name}_summernote_embeds"#, :"clean_#{name}_summernote_code"

          # https://dalibornasevic.com/posts/16-ruby-class_eval-__file__-and-__line__-arguments
          class_eval <<-CODE, __FILE__, __LINE__ + 1
            def update_#{name}_summernote_embeds
              self.#{name}_summernote_embeds = #{name}.attachables.grep(ActiveStorage::Blob).uniq if #{name}.present?
            end

            def clean_#{name}_summernote_code
              return if self.#{name}.nil?
              self.#{name} = SummernoteCleaner.clean self.#{name}.to_html
            end
          CODE
        end
      end
    end
  end
end
