module ShopifyGraphQLClient
  class QueryBuilder
    class Error < ShopifyGraphQLClient::Error; end

    attr_accessor :selections
    attr_accessor :receiver

    def initialize(&blk)
      self.selections = []
      self.receiver = blk.binding.receiver
      instance_eval(&blk)
    end

    def field(name, **args, &blk)
      sub_selections = QueryBuilder.new(&blk) if block_given?
      value = FieldSelectionValue.new(
        field_name: name,
        args: args,
        sub_selections: sub_selections,
      )
      selection = Selection.new(
        parent: self,
        index: selections.length,
        name: name,
        value: value,
      )
      selections.push(selection)
      selection
    end

    def include(fragment, **args, &blk)
      sub_selections = QueryBuilder.new(&blk) if block_given?

      if fragment.is_a? Symbol
        # call the method in the environment of the passed-in block
        fragment = receiver.send(fragment, **args)
      end

      inclusion = if fragment.is_a? Selection
        # `include product(id: id) do ... end`
        selection = fragment
        # doesn't work for array
        selection.value.sub_selections = sub_selections
        Inclusion.new(
          value: selection.value,
        )
      else
        # `include :fragment_name, arg1: "some value"`
        if sub_selections
          raise Error, "fragment composition not implemented yet"
        end
        FragmentInclusion.new(fragment: fragment)
      end

      selections.push(inclusion)
      nil
    end

    def object(&blk)
      raise Error, "`object` must be provided a block" unless block_given?

      sub_selections = QueryBuilder.new(&blk)

      ObjectSelectionValue.new(
        sub_selections: sub_selections,
      )
    end

    def method_missing(*args, **kwargs, &blk)
      field(*args, **kwargs, &blk)
    end

    # All methods above this point
    # Below are classes

    Selection = Struct.new(
      :parent, :index, :name, :value,
      keyword_init: true,
    ) do
      # `foo << bar(x: 1, y: 2)`
      # maps to
      # `foo: bar(x: 1, y: 2)`
      def <<(other)
        if other.is_a? Selection
          self.name = other.name
          self.value = other.value
        elsif other.is_a? ObjectSelectionValue
          self.value = other
        elsif other.is_a? Array
          self.value = ArraySelectionValue.new(array: other)
        else
          raise Error, "Invalid value passed to `<<`"
        end

        # remove all selections that were added when constructing other
        parent.selections.reject!.with_index{|_, i| i > index}

        # can't call any more methods
        nil
      end

      def with_value(value)
        self.value = DirectValue.new(value: value)

        # can't call any more methods
        nil
      end

      # `some_field.some_subfield`
      # intended usage: `foo << some_field.some_subfield`
      def method_missing(name, **args, &blk)
        # unset name, because you can't have a dot in the name
        self.name = nil

        sub_selections = QueryBuilder.new(&blk) if block_given?

        self.value = SubfieldSelectionValue.new(
          parent_value: self.value,
          field_name: name,
          args: args,
          sub_selections: sub_selections,
        )

        self
      end
    end

    FragmentInclusion = Struct.new(:fragment, keyword_init: true)
    Inclusion = Struct.new(:value, keyword_init: true)

    FieldSelectionValue = Struct.new(
      :field_name, :args, :sub_selections,
      keyword_init: true,
    )
    SubfieldSelectionValue = Struct.new(
      :parent_value, :field_name, :args, :sub_selections,
      keyword_init: true,
    )
    DirectValue = Struct.new(
      :value,
      keyword_init: true,
    )
    ObjectSelectionValue = Struct.new(:sub_selections, keyword_init: true)
    ArraySelectionValue = Struct.new(:array, keyword_init: true)
  end
end
