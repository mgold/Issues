class Sawyer::Resource
  def initialize(agent, data = {})
    @_agent  = agent
    data, links = agent.parse_links(data)
    @_rels = Relation.from_links(agent, links)
    @_fields = Set.new
    @attrs = {}
    data.each do |key, value|
      @_fields << key
      @attrs[key.to_sym] = process_value(value)
    end
    singleton_class.send(:attr_accessor, *data.keys)
  end

  def method_missing(method, *args)
    attr_name, suffix = method.to_s.scan(/([a-z0-9\_]+)(\?|\=)?$/i).first
    if suffix == ATTR_SETTER
      singleton_class.send(:attr_accessor, attr_name)
      @_fields << attr_name.to_sym
      send(method, args.first)
    elsif attr_name && @_fields.include?(attr_name.to_sym)
      value = @attrs[attr_name.to_sym]
      case suffix
      when nil
        singleton_class.send(:attr_accessor, attr_name)
        value
      when ATTR_PREDICATE then !!value
      end
    elsif suffix.nil? && SPECIAL_METHODS.include?(attr_name)
      instance_variable_get "@_#{attr_name}"
    elsif attr_name && !@_fields.include?(attr_name.to_sym)
      nil
    else
      super
    end
  end
end
