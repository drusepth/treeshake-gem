def self.called_main_scope_class_method
end

def self.uncalled_main_scope_class_method
end

def called_main_scope_method
  called_main_scope_method_from_another_method
end

def called_main_scope_method_from_another_method
end

def uncalled_main_scope_method
end

class TestClass
  def called_method
    called_method_from_another_method

    TreeshakeTestClass.called_class_method_from_another_instance_method
  end

  def called_method_from_another_method
  end

  def uncalled_method
  end

  def another_uncalled_method
  end

  def self.called_class_method
    self.called_class_method_from_another_class_method
  end

  def self.uncalled_class_method
  end

  def self.another_uncalled_class_method
  end

  def self.called_class_method_from_another_class_method
  end

  def self.called_class_method_from_another_instance_method
  end
end






class Treeshaker
  def self.list_of_all_methods
    [
      self.list_of_all_main_instance_methods,
      self.list_of_all_main_class_methods,
      self.list_of_all_class_methods
    ].flatten.uniq
  end

  private

  def self.list_of_all_class_methods
    classes = self.list_of_all_classes

    classes.flat_map do |class_name|
      class_object = Object.const_get(class_name)

      developer_defined_methods = class_object.methods.map do |method_name|
        method_reference = class_object.method(method_name)
        method_defined_by_developer?(method_reference) ? method_reference : nil
      end

      developer_defined_methods.compact!
    end
  end

  def self.list_of_all_main_instance_methods
    [] #TODO - no idea how to grab these references
  end

  def self.list_of_all_main_class_methods
    main_reference = TOPLEVEL_BINDING.eval('self')

    global_methods = main_reference.methods.map do |method_name|
      method_reference = main_reference.method(method_name)
      method_defined_by_developer?(method_reference) ? method_reference : nil
    end

    global_methods.compact!
  end

  private

  def self.list_of_all_classes
    global_classes = Object.constants.select do |constant|
      Object.const_get(constant).class == Class
    end

    global_classes
  end

  def self.method_defined_by_developer? method
    source_data = method.source_location

    # If a method doesn't source_location, we treat it as a language-defined method.
    return false if source_data.nil?

    # Also, if a method has a source_location file of <internal:prelude>, we do the same
    return false if source_data.any? && source_data[0] == '<internal:prelude>'

    # TODO: handle gem methods which have source_locations in the gem dir
    # TODO: methods defined with class_eval and define_method don't have source locations

    # If all of the above are false, we assume the method was defined by a developer
    true
  end
end

methods_in_source_code = Treeshaker.list_of_all_methods
m = methods_in_source_code

require 'pry'
binding.pry

# [1] pry(main)> methods_in_source_code
# => [
#  #<Method: main.called_main_scope_class_method>,
#  #<Method: main.uncalled_main_scope_class_method>,
#  #<Method: TestClass.called_class_method>,
#  #<Method: TestClass.uncalled_class_method>,
#  #<Method: TestClass.another_uncalled_class_method>,
#  #<Method: TestClass.called_class_method_from_another_class_method>,
#  #<Method: TestClass.called_class_method_from_another_instance_method>,
#  #<Method: Treeshaker.list_of_all_methods>,
#  #<Method: Treeshaker.list_of_all_class_methods>,
#  #<Method: Treeshaker.list_of_all_main_instance_methods>,
#  #<Method: Treeshaker.list_of_all_main_class_methods>,
#  #<Method: Treeshaker.list_of_all_classes>,
#  #<Method: Treeshaker.method_defined_by_developer?>
# ]
