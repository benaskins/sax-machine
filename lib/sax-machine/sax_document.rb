require "nokogiri"

module SAXMachine
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  def parse(xml_text)
    sax_handler = SAXHandler.new(self)
    parser = Nokogiri::XML::SAX::Parser.new(sax_handler)
    parser.parse(xml_text)
    self
  end
  
  module ClassMethods

    def parse(xml_text)
      new.parse(xml_text)
    end
    
    def element(name, options = {})
      options[:as] ||= name
      sax_config.add_top_level_element(name, options)
      
      # we only want to insert the getter and setter if they haven't defined it from elsewhere.
      # this is how we allow custom parsing behavior. So you could define the setter
      # and have it parse the string into a date or whatever.
      attr_reader options[:as] unless instance_methods.include?(options[:as].to_s)
      attr_writer options[:as] unless instance_methods.include?("#{options[:as]}=")
    end
    
    def elements(name, options = {})
      options[:as] ||= name
      if options[:class]
        sax_config.add_collection_element(name, options)
      else
        class_eval <<-SRC
          def add_#{options[:as]}(value)
            #{options[:as]} << value
          end
        SRC
        sax_config.add_top_level_element(name, options.merge(:collection => true))
      end
      
      class_eval <<-SRC
        def #{options[:as]}
          @#{options[:as]} ||= []
        end
      SRC
      
      attr_writer options[:as]
    end
    
    def attributes(*attr_names)    
      attr_names.each do |attr_name|
        attr_reader attr_name unless instance_methods.include?(attr_name.to_s)
        attr_writer attr_name unless instance_methods.include?("#{attr_name}=")
      end
    end
    
    def sax_config
      @sax_config ||= SAXConfig.new
    end
  end
  
end