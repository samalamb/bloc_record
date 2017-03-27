require 'sqlite3'

module Selection
  def find(*ids)
    if ids.kind_of? String || id <= 0
      puts "Sorry please enter a number that is greater than 0."
    elsif ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
          WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end
  end

  def find_one(id=1)
    if id.is_a?(Integer)
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{id};
      SQL

      init_object_from_row(row)
    else
      puts "Sorry, please enter a number"
    end
  end

  def find_by(attribute, value)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  def find_each(options)
    if options.nil?
      items = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
      SQL
    elsif options.class.kind_of Hash
      items = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{options.size} OFFSET #{options.start};
      SQL
    else
      throw "Ya broke it."
    end

    items.each do |item|
      yield init_object_from_row(item)
    end
  end

  def find_in_batches(options)
    # find_in_batches(start: 200) find_in_batches(batch_size: 100)
    if !options.size.nil? && !options.start.nil?
      items = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{options.size} OFFSET #{options.start};
      SQL
    end

    if items.nil?
      throw "Sorry please pass in a Hash with size and start values."
    else
      yield rows_to_array(items)
    end
  end

  def self.method_missing(method_sym, *args)

    if method_sym.to_s =~ /find_by/
      if args.length > 1
        puts "please provide only one argument"
        method_missing(method_sym, *args)
      end

      attribute = nil
      value = nil
      attribute = method_sym.to_s[7...method.length].downcase
      attribute.slice!(0) if attribute[0] == "_"

      if self.attributes.include?(attribute)
        args.each do |arg|
          if arg.class == String
            value = arg
          else
            value = arg.to_s
          end
        end

        find_by(attribute, value)
      else
        super
      end
    elsif method_sym.to_s =~ /update/
      attribute = method_sym.to_s[6...method.length].downcase
      attribute.slice!(0) if attribute[0] == "_"

      if self.attributes.include?(attribute)
        args.each do |arg|
          if arg,class == String
            value = arg
          else
            value = arg.to_s
          end
        end

        self.update_attribute(attribute, value)
      else
        super
      end
    else
      super
    end
  end

  def take(num=1)
    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    orders = []

    if args.count < 1
      orders = args.first.to_s
    else
      args.each do |arg|
        case arg
        when String
          orders << ascend_descend(arg)
        when Hash
          orders << ascend_descend(arg.map { |key,value| "#{key} #{value}" }.join(''))
        when Symbol
          orders << ascend_descend(arg)
        end
      end
    end

    orders.join(',')

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{orders}
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        key = args.first.keys[0]
        value = args.first.values[0]
        rows = connection <<-SQL
          SELECT * FROM
          INNER JOIN #{key} ON #{key}.#{table}_id = #{table}.id
          INNER JOIN #{value} ON #{value}.#{key}_id = #{key}.id
        SQL
      end
    end

    rows_to_array(rows)
  end

  private
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end

  def ascend_descend(string)
    if string.include?(" asc") || string.include?(" ASC") || string.include?(" desc") || string.include?(" DESC")
      string
    else
      string << " ASC"
    end
  end
end
