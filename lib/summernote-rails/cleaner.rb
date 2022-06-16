require 'nokogiri'

class SummernoteCleaner
  BLOCK_TAGS = [
    'h1'.freeze,
    'h2'.freeze,
    'h3'.freeze,
    'h4'.freeze,
    'h5'.freeze,
    'h6'.freeze,
    'p'.freeze,
    'ul'.freeze,
    'ol'.freeze,
    'dl'.freeze
  ]

  DEFAULT_BLOCK = 'p'.freeze

  def self.clean(code)
    new(code).clean
  end

  def initialize(code)
    @code = code.gsub("<p>\n</p>", "")
                .gsub("<p></p>", "")
                .gsub("<p><br></p>", "")
    @max_loops = @code.length * 2
    @current_loop = 0
    @clean_code = ''
    @current_block_tag = nil
    @open_block_tag_found = nil
    @close_block_tag_found = nil
    @open_tags = {}
    @close_tags = {}
  end

  # def clean
  #   while @code.length > 0 && @max_loops > @current_loop do
  #     if starts_with_open_block_tag?
  #       log "starts_with_open_block_tag #{@open_block_tag_found}"
  #       unless @current_block_tag.nil?
  #         log "Opening a block in a block, we need to close the previous one"
  #         @clean_code.concat close(@current_block_tag)
  #       end
  #       log "Move the open block from code to clean code"
  #       transfer open_current.length
  #       @current_block_tag = @open_block_tag_found
  #       @open_block_tag_found = nil
  #     elsif starts_with_close_block_tag?
  #       log "starts_with_close_block_tag #{@close_block_tag_found}"
  #       if @close_block_tag_found == @current_block_tag
  #         log "Everything is logical, we close what was opened"
  #         transfer close_current.length
  #       elsif @current_block_tag == nil
  #         log "Nothing opened, just remove it"
  #         remove close(@close_block_tag_found).length
  #       else
  #         log "Mismatch, the closing tag is not what it should be. We need to remove it, and add the correct one instead"
  #         remove close(@close_block_tag_found).length
  #         @clean_code.concat close_current
  #       end
  #       @current_block_tag = nil
  #       @close_block_tag_found = nil
  #     else
  #       if in_block?
  #         transfer 1
  #       else
  #         log "not in a block, we open a p"
  #         @current_block_tag = DEFAULT_BLOCK
  #         @clean_code.concat open_current
  #       end
  #     end
  #     log @clean_code
  #     @current_loop += 1
  #   end
  #   if in_block?
  #     log "still in a block, we close with a #{@current_block_tag}"
  #     @clean_code.concat close_current
  #   end
  #   log @clean_code
  #   @clean_code
  # end

  def clean
    fragment = Nokogiri::HTML5::DocumentFragment.parse(@code)
    not_block_elements_collection = []
    not_block_elements = []
    fragment.children.each do |child|
      if child.class == Nokogiri::XML::Element && BLOCK_TAGS.include?(child.name)
        # Block
        if not_block_elements.length > 0
          not_block_elements_collection << not_block_elements
          not_block_elements = []
        end
      else
        # Not block (text or inline element)
        not_block_elements << child
      end
    end
    not_block_elements_collection << not_block_elements if not_block_elements.length > 0

    not_block_elements_collection.each do |nodes|
      first_node = nodes.first
      new_paragraph = first_node.add_previous_sibling Nokogiri::XML::Node.new('p', fragment.document)
      nodes.each do |node|
        node.parent = new_paragraph
      end
    end

    fragment.to_html
            .gsub("<p>\n</p>", "")
            .gsub("<p></p>", "")
            .gsub("<p><br></p>", "")
  end

  protected

  def transfer(length)
    add length
    remove length
  end

  # 0..0 means first character
  def add(length)
    # Concat is much lighter than +=
    # https://www.rubyguides.com/2019/07/ruby-string-concatenation/
    @clean_code.concat @code[0..length-1].freeze
  end

  # 1..-1 means everything but the first
  def remove(length)
    @code = @code[length..-1].freeze
  end

  def starts_with_open_block_tag?
    BLOCK_TAGS.each do |tag|
      if @code.start_with? open(tag)
        @open_block_tag_found = tag
        return true
      end
    end
    false
  end

  def starts_with_close_block_tag?
    BLOCK_TAGS.each do |tag|
      if @code.start_with? close(tag)
        @close_block_tag_found = tag
        return true
      end
    end
    return false
  end

  def in_block?
    !@current_block_tag.nil?
  end

  def open(tag)
    @open_tags[tag] ||= "<#{tag}>".freeze
  end

  def close(tag)
    @close_tags[tag] ||= "</#{tag}>".freeze
  end

  def open_current
    open @current_block_tag
  end

  def close_current
    close @current_block_tag
  end

  def log(string)
    # puts string
  end
end
