require 'singleton'

class CachingFormulaParser
  include Singleton

  attr_accessor :functions_used

  def self.parse(*args)
    instance.parse(*args)
  end

  def self.map(*args)
    instance.map(*args)
  end

  def initialize
    @number_cache = {}
    @string_cache = {}
    @percentage_cache = {}
    @error_cache = {}
    @operator_cache = {}
    @comparator_cache = {}
    @sheet_reference_cache = {}
    @functions_used = {}
  end

  def parse(text)
    ast = Formula.parse(text)
    if ast
      map(ast.to_ast[1])
    else
      nil
    end
  end

  # FIXME: THe function bit in here isn't DRY or consistent
  def map(ast)
    return ast unless ast.is_a?(Array)
    if ast[0] == :function
      ast[1] = ast[1].to_sym 
      @functions_used[ast[1]] = true
    end
    if respond_to?(ast[0])
      ast = send(ast[0], ast) 
    else
      ast.each.with_index do |a,i| 
        next unless a.is_a?(Array)
        
        if a[0] == :function
          a[1] = a[1].to_sym 
          @functions_used[a[1]] = true
        end

        ast[i] = map(a)
      end
    end
    ast
  end

  def external_reference(ast)
    raise ExcelToCodeException.new("Sorry, ExcelToCode cannot cope with external references (#{ast.inspect}. Please strip them from the workbook before attempting to compile it.")
  end

  def sheet_reference(ast)
    ast[1] = ast[1].to_sym
    ast[2] = map(ast[2])
    @sheet_reference_cache[ast] ||= ast
  end

  def cell(ast)
    ast[1] = ast[1].to_sym
    ast
  end

  def area(ast)
    ast[1] = ast[1].to_sym
    ast[2] = ast[2].to_sym
    ast
  end

  def number(ast)
    ast[1] = ast[1].to_f
    @number_cache[ast] ||= ast
  end

  def percentage(ast)
    ast[1] = ast[1].to_f
    @percentage_cache[ast] ||= ast
  end

  def string(ast)
    return @string_cache[ast] ||= ast
  end

  TRUE = [:boolean_true]
  FALSE = [:boolean_false]
  BLANK = [:blank]

  def boolean_true(ast)
    TRUE
  end

  def boolean_false(ast)
    FALSE
  end

  def error(ast)
    ast[1] = ast[1].to_sym
    @error_cache[ast] ||= ast
  end

  def blank(ast)
    BLANK
  end

  def operator(ast)
    ast[1] = ast[1].to_sym
    @operator_cache[ast] ||= ast
  end

  def comparator(ast)
    ast[1] = ast[1].to_sym
    @comparator_cache[ast] ||= ast
  end

end
